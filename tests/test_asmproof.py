"""OMF coverage and strict assembly binding tests; no DOS tools or oracles."""
import struct
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from omf import MatchError, OmfReader
import asmproof


def record(kind, body=b""):
    raw = bytes([kind]) + struct.pack("<H", len(body) + 1) + body
    return raw + bytes([-sum(raw) & 255])


def name(s):
    b = s.encode("ascii")
    return bytes([len(b)]) + b


def module(size, records=(), externals=(), publics=()):
    # LNAMES: null, CODE; SEGDEF: byte/public/use16, class null, no overlay.
    out = record(0x80, name("TEST")) + record(0x96, b"\x00" + name("CODE"))
    out += record(0x98, b"\x28" + struct.pack("<H", size) + b"\x02\x01\x01")
    if externals:
        out += record(0x8c, b"".join(name(n) + b"\x00" for n in externals))
    if publics:
        out += record(0x90, b"\x00\x01" + b"".join(
            name(n) + struct.pack("<H", off) + b"\x00" for n, off in publics))
    return out + b"".join(records) + record(0x8a, b"\x00")


def ledata(off, payload):
    return record(0xa0, b"\x01" + struct.pack("<H", off) + payload)


def fixup(at=0, loc=1, target=1, method=0, disp=None, relative=False,
          frame_method=5, frame_index=0):
    locat = 0x8000 | (0 if relative else 0x4000) | (loc << 10) | at
    fixdat = (frame_method << 4) | (4 if disp is None else 0) | method
    body = struct.pack(">H", locat) + bytes([fixdat])
    if frame_method in (0, 1, 2):
        body += bytes([frame_index])
    body += bytes([target])
    if disp is not None:
        body += struct.pack("<H", disp)
    return record(0x9c, body)


def context(original, start=0x100, relocs=(), globals_=None, routines=None, extra=None):
    return asmproof.Context("sam2", "u6", start, original,
        {"u6": 0x286e, "u3": 0x1800, "DATA": 0x3000},
        routines or {}, globals_ or {}, set(relocs), extra)


class OMFParsing(unittest.TestCase):
    def test_coverage_preserves_leading_middle_and_trailing_holes(self):
        obj = OmfReader().read(module(10, [ledata(2, b"\x00\x00"), ledata(7, b"X")]))
        self.assertEqual(obj.segment_bytes("CODE"), b"\x00" * 7 + b"X\x00\x00")
        self.assertEqual(obj.segment_defined["CODE"], b"\x00\x00\x01\x01\x00\x00\x00\x01\x00\x00")
        self.assertEqual(asmproof.ranges(obj.segment_defined["CODE"]), [(0, 2), (4, 7), (8, 10)])

    def test_wholly_undefined_segment_has_no_initialized_bytes(self):
        obj = OmfReader().read(module(8))
        self.assertEqual(obj.segment_length("CODE"), 8)
        self.assertEqual(obj.segment_defined["CODE"], bytes(8))
        self.assertNotIn("CODE", obj.segments)

    def test_lidata_nested_repetition_and_coverage(self):
        leaf = struct.pack("<HH", 3, 0) + b"\x02AB"
        nested = struct.pack("<HH", 2, 1) + leaf
        obj = OmfReader().read(module(16, [record(0xa2, b"\x01\x02\x00" + nested)]))
        self.assertEqual(obj.segment_bytes("CODE")[2:14], b"AB" * 6)
        self.assertEqual(obj.segment_defined["CODE"], bytes(2) + b"\x01" * 12 + bytes(2))

    def test_lidata_fixup_is_expanded_at_each_repetition(self):
        # FIXUPP offset 5 points to the literal bytes after repeat/block/length.
        leaf = struct.pack("<HH", 3, 0) + b"\x02\x00\x00"
        obj = OmfReader().read(module(6, [record(0xa2, b"\x01\x00\x00" + leaf), fixup(5)]))
        self.assertEqual([f["offset"] for f in obj.linker_fixups], [0, 2, 4])
        self.assertTrue(all(f["iterated"] for f in obj.linker_fixups))

    def test_external_public_and_displacement(self):
        obj = OmfReader().read(module(2, [ledata(0, b"\x04\x00"),
            fixup(method=2, disp=3)], ["d_1234"], [("u6_0100", 0)]))
        self.assertEqual(obj.externals, ["d_1234"])
        self.assertEqual(obj.publics, [{"name": "u6_0100", "segment": "CODE", "offset": 0}])
        f = obj.linker_fixups[0]
        self.assertEqual((f["target_kind"], f["target"], f["displacement"], f["encoded_addend"]),
                         ("external", "d_1234", 3, "0400"))

    def test_threads_carry_frame_and_target(self):
        # Frame thread 0 = target; target thread 0 = segment index 1.
        threads = b"\x54\x00\x01"
        threaded = b"\xc4\x00\x8c"
        obj = OmfReader().read(module(2, [ledata(0, bytes(2)), record(0x9c, threads + threaded)]))
        f = obj.linker_fixups[0]
        self.assertEqual((f["target"], f["frame_kind"]), ("CODE", "target"))

    def test_refuse_data_beyond_declared_length_and_overlap(self):
        for records in ([ledata(1, bytes(2))], [ledata(0, bytes(2)), ledata(1, b"X")]):
            with self.assertRaises(MatchError):
                OmfReader().read(module(2, records))

    def test_refuse_fixup_into_hole(self):
        with self.assertRaises(MatchError):
            OmfReader().read(module(4, [ledata(2, bytes(2)), fixup(2)]))

    def test_refuse_32bit_unknown_truncated_and_missing_modend(self):
        inputs = [module(2, [record(0xa1)]), module(2, [record(0xa4)]),
                  module(2)[:-1], module(2)[:-5], module(2) + b"\x00"]
        for blob in inputs:
            with self.subTest(blob=blob.hex()), self.assertRaises(MatchError):
                OmfReader().read(blob)

    def test_nonzero_bad_checksum_is_refused(self):
        blob = bytearray(module(2))
        blob[5] ^= 1
        with self.assertRaises(MatchError):
            OmfReader().read(bytes(blob))

    def test_zero_checksum_is_accepted(self):
        blob = bytearray(module(2))
        blob[3 + int.from_bytes(blob[1:3], "little") - 1] = 0
        self.assertEqual(OmfReader().read(bytes(blob)).segment_length("CODE"), 2)


class Binding(unittest.TestCase):
    def proof(self, obj, ctx):
        return asmproof.prove(OmfReader().read(obj), ctx)

    def test_raw_data_diff_and_holes_do_not_count_as_defined_equality(self):
        obj = module(4, [ledata(1, b"A")])
        good = self.proof(obj, context(b"xAyz"))
        self.assertEqual((good.status, good.defined, good.holes), ("EQUAL", 1, [(0, 1), (2, 4)]))
        bad = self.proof(obj, context(b"xByz"))
        self.assertEqual((bad.status, bad.first_diff), ("DIFF", 1))
        self.assertIn("original", bad.disassembly)
        self.assertIn("candidate", bad.disassembly)

    def test_ds_global_episode_offset_plus_both_addends(self):
        obj = module(2, [ledata(0, b"\x04\x00"), fixup(method=2, disp=3)], ["d_1234"])
        self.assertEqual(self.proof(obj, context(b"\x47\x12", globals_={"D_1234": 0x1240})).status, "EQUAL")
        self.assertEqual(self.proof(obj, context(b"\x3b\x12", globals_={"D_1234": 0x1240})).status, "DIFF")

    def test_extra_offset_fallback(self):
        calls = []
        def extra(n, ep):
            calls.append((n, ep))
            return 0x6789
        obj = module(2, [ledata(0, bytes(2)), fixup(method=2)], ["d_6677"])
        self.assertEqual(self.proof(obj, context(b"\x89\x67", extra=extra)).status, "EQUAL")
        self.assertEqual(calls, [("D_6677", "sam2")])

    def test_unknown_external_fails_even_if_raw_word_happens_to_equal(self):
        obj = module(2, [ledata(0, bytes(2)), fixup(method=2)], ["unknown"])
        result = self.proof(obj, context(bytes(2)))
        self.assertEqual(result.status, "DIFF")
        self.assertIn("Unbound EXTDEF", result.reason)

    def test_cs_reference_adds_contribution_start(self):
        obj = module(2, [ledata(0, b"\x1c\x00"), fixup()])
        self.assertEqual(self.proof(obj, context(b"\x9b\x00", start=0x7f)).status, "EQUAL")
        self.assertEqual(self.proof(obj, context(b"\x1c\x00", start=0x7f)).status, "DIFF")

    def test_self_relative_fixup_accounts_for_location_and_field_width(self):
        obj = module(6, [ledata(0, bytes(6)), fixup(at=2, disp=0, relative=True)])
        self.assertEqual(self.proof(obj, context(b"\x00\x00\xfc\xff\x00\x00")).status, "EQUAL")

    def test_segment_fixup_needs_relocation_and_correct_unit(self):
        obj = module(2, [ledata(0, bytes(2)), fixup(loc=2)])
        self.assertEqual(self.proof(obj, context(b"\x6e\x28", relocs=[0])).status, "EQUAL")
        self.assertEqual(self.proof(obj, context(b"\x6e\x28")).status, "DIFF")
        self.assertEqual(self.proof(obj, context(b"\x00\x18", relocs=[0])).status, "DIFF")

    def test_far_call_external_binds_offset_segment_and_relocation(self):
        obj = module(5, [ledata(0, b"\x9a\x00\x00\x00\x00"),
                         fixup(at=1, loc=3, method=2)], ["u3_6ea9"])
        ctx = context(b"\x9a\xaa\x70\x00\x18", relocs=[3], routines={"u3_6ea9": ("u3", 0x70aa)})
        self.assertEqual(self.proof(obj, ctx).status, "EQUAL")
        ctx.routines["u3_6ea9"] = ("u3", 0x6ea9)
        self.assertEqual(self.proof(obj, ctx).status, "DIFF")

    def test_tp_cross_unit_external_uses_symbol_owner_with_conventional_code_frame(self):
        obj = module(5, [ledata(0, b"\x9a\x00\x00\x00\x00"),
            fixup(at=1, loc=3, method=2, frame_method=0, frame_index=1)], ["u3_6ea9"])
        ctx = context(b"\x9a\xa9\x6e\x00\x18", relocs=[3],
                      routines={"u3_6ea9": ("u3", 0x6ea9)})
        self.assertEqual(self.proof(obj, ctx).status, "EQUAL")

    def test_segment_addend_cannot_impersonate_another_unit(self):
        obj = module(2, [ledata(0, b"\x01\x00"), fixup(loc=2)])
        result = self.proof(obj, context(b"\x6f\x28", relocs=[0]))
        self.assertEqual(result.status, "DIFF")
        self.assertIn("segment addend", result.reason)

    def test_frame_target_unit_mismatch_refused(self):
        obj = module(2, [ledata(0, bytes(2)),
            fixup(method=2, frame_method=0, frame_index=1)], ["d_1234"])
        self.assertEqual(self.proof(obj, context(b"\x34\x12", globals_={"D_1234": 0x1234})).status, "DIFF")

    def test_original_relocation_without_candidate_fixup_fails(self):
        self.assertEqual(self.proof(module(2, [ledata(0, bytes(2))]),
            context(bytes(2), relocs=[0])).status, "DIFF")

    def test_publics_bind_by_identity_and_offset(self):
        obj = module(2, [ledata(0, bytes(2))], publics=[("u6_0100", 0)])
        ctx = context(bytes(2), routines={"u6_0100": ("u6", 0x100)})
        self.assertEqual(self.proof(obj, ctx).status, "EQUAL")
        ctx.routines["u6_0100"] = ("u6", 0x101)
        self.assertEqual(self.proof(obj, ctx).status, "DIFF")
        ctx.routines.clear()
        self.assertEqual(self.proof(obj, ctx).status, "DIFF")

    def test_extent_cannot_be_shortened_or_zero_filled_to_manufacture_equality(self):
        self.assertEqual(self.proof(module(1, [ledata(0, b"A")]), context(b"AB")).status, "DIFF")
        result = self.proof(module(2), context(b"AB"))
        self.assertEqual((result.status, result.defined, result.holes), ("EQUAL", 0, [(0, 2)]))
        self.assertIn("HOLES 2", result.short())

    def test_overlapping_fixups_refused(self):
        obj = module(2, [ledata(0, bytes(2)), fixup(), fixup()])
        self.assertEqual(self.proof(obj, context(b"\x00\x01")).status, "DIFF")

    def test_atlas_translation_checks_all_anchors(self):
        objects = {"p": {"sam1_start": "514a", "sam1_end": "5200"}}
        def row(a, b):
            return {"episodes": {"sam1": {"unit": "p", "entry": a},
                                 "sam2": {"unit": "p", "entry": b}}}
        atlas = {"routines": {"p_5151": row(0x5151, 0x51d3), "p_51f3": row(0x51f3, 0x5275)}}
        self.assertEqual(asmproof.translated_extent("p", "sam2", objects, atlas), (0x51cc, 0x5282))
        atlas["routines"]["p_51f3"]["episodes"]["sam2"]["entry"] += 1
        with self.assertRaises(MatchError):
            asmproof.translated_extent("p", "sam2", objects, atlas)


if __name__ == "__main__":
    unittest.main()
