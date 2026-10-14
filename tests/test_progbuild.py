"""Program generation and comparison tests; no historical DOS tools are run."""
import struct
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import progbuild as pb
import mz


def candidate(lid, body, decls="", stubs="", episodes=pb.EPISODES, covers=()):
    recipe = {"function": lid, "unit": lid.split("_", 1)[0], "equal": list(episodes),
              "episodes": {ep: {"status": "EQUAL"} for ep in episodes}, "covers": list(covers)}
    return pb.Candidate(lid, recipe, "{@decls}\n" + decls + "\n{@stubs}\n" + stubs +
                        "\n{@body}\n" + body, "src/routines/" + lid + ".pas")


def fixture():
    atlas = {"units": ["p", "u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "crt", "u9", "dos", "sys"],
             "routines": {}}
    candidates = {}

    def add(c, entry):
        candidates[c.lid] = c
        atlas["routines"][c.lid] = {"unit": c.unit, "episodes": {
            ep: {"unit": c.unit, "start": entry, "entry": entry, "end": entry + 8}
            for ep in c.recipe["equal"]}}

    add(candidate("p_0100", "begin\n  u1_0001;\nend."), 0x100)
    for i in range(1, 10):
        add(candidate(f"u{i}_ff00", "begin\nend."), 0xFF00)
    add(candidate("p_0010", "procedure p_0010; begin p_0020; end;", stubs="procedure p_0020;"), 0x10)
    add(candidate("p_0020", "procedure p_0020; begin end;"), 0x20)
    add(candidate("u1_0001", "procedure u1_0001; begin u1_0020; end;", stubs="procedure u1_0020;"), 1)
    add(candidate("u1_0020", "procedure u1_0020; begin u1_0001; end;", stubs="procedure u1_0001;"), 0x20)
    add(candidate("u2_0001", "procedure u2_0001; begin d_0296[1] := 1; end;"), 1)
    add(candidate("u3_0020", "procedure u3_0020;\n  procedure u3_0010;\n  begin end;\nbegin u3_0010; end;",
                  covers=["u3_0010"]), 0x20)
    atlas["routines"]["u3_0010"] = {"unit": "u3", "episodes": {
        ep: {"unit": "u3", "start": 0x10, "entry": 0x10, "end": 0x20} for ep in pb.EPISODES}}
    add(candidate("p_sam2_0040", "procedure p_sam2_0040; begin end;", episodes=("sam2", "sam3")), 0x40)
    add(candidate("u3_0000", "procedure u3_0000; begin end;", episodes=("sam1",)), 0)
    canonical = """{@types}
type TCell = record A, B: Word; end;
{@globals}
const d_0000: array[0..3] of Byte = (1, 2, 3, 4);
var d_0294: array[0..1] of Byte;
    d_0296: array[1..8000] of Byte;
{@routines}
procedure p_0010;
procedure p_0020;
procedure u1_0001;
procedure u1_0020;
procedure u6_0010;
"""
    offsets = [0, 0x294, 0x296, 0x21D6, 0x21E0, 0x341E, 0x34B0, 0x70DA]
    data = {f"d_{n:04x}": {ep: f"{n:04X}" for ep in pb.EPISODES} for n in offsets}
    obj = {"unit": "u6", "function": "obj_u6", "equal": list(pb.EPISODES), "covers": ["u6_0010"]}
    atlas["routines"]["u6_0010"] = {"unit": "u6", "episodes": {
        ep: {"unit": "u6", "start": 0x10, "entry": 0x10, "end": 0x18} for ep in pb.EPISODES}}
    project = pb.Project(atlas, data, {}, {"objects": {"u6": {"sam1_start": "0010", "sam1_end": "0018"}}},
                         canonical, candidates, {"u6": (obj, "CODE segment byte public\npublic u6_0010\nCODE ends\nend")})
    anchors = {"game_const_end": 4, "game_var_start": 0x294, "crt_var_start": 0x70DA,
               "u9_var_start": 0x70EE, "u9_var_end": 0x7192, "ds_size": 0x73E0,
               "PREFIXSEG": 0x288, "CHECKBREAK": 0x70DA, "DOSERROR": None, "INPUT": 0x7192}
    far = {n: True for n in atlas["routines"]}
    far.update(p_0010=False, p_0020=False, u1_0020=False)
    sizes = {"D_0000": 4, "D_0294": 2, "D_0296": 8000}
    return project, anchors, far, sizes


class SourceGeneration(unittest.TestCase):
    def setUp(self):
        self.project, self.anchors, self.far, self.sizes = fixture()

    def generate(self, episode="sam1"):
        return pb.generate(self.project, episode, self.sizes, self.far, self.anchors)

    def test_complete_fixture_has_no_blockers(self):
        self.assertEqual(self.generate().problems, [])

    def test_real_program_uses_and_unit_dependencies(self):
        generated = self.generate()
        self.assertEqual(set(generated.sources), {"SAM.PAS", *(f"U{i}.PAS" for i in range(1, 10))})
        self.assertIn("uses Dos, U9, Crt, U8, U7, U6, U5, U4, U3, U2, U1;", generated.sources["SAM.PAS"])
        self.assertIn("{$M 16384,0,655360}", generated.sources["SAM.PAS"])
        self.assertIn("interface\nuses U8;", generated.sources["U1.PAS"])
        self.assertIn("uses Dos, U9, Crt, U7, U6, U5, U4, U3, U2;", generated.sources["U1.PAS"])
        self.assertNotIn("Crt", generated.sources["U9.PAS"])
        self.assertNotIn("U8", generated.sources["U9.PAS"])
        self.assertIn("TCell = record", generated.sources["U8.PAS"])

    def test_definition_order_forward_and_interface_visibility(self):
        text = self.generate().sources["U1.PAS"]
        interface, implementation = text.split("implementation", 1)
        self.assertIn("procedure u1_0001;", interface)
        self.assertNotIn("procedure u1_0020;", interface)
        self.assertIn("{$F-}\nprocedure u1_0020; forward;", implementation)
        self.assertLess(implementation.index("procedure u1_0001; begin"), implementation.index("procedure u1_0020; begin"))
        self.assertNotIn("u1_0001; forward", implementation)
        self.assertLess(text.index("procedure u1_0020; begin"), text.rindex("begin\nend."))
        self.assertIn("{$F-}\nprocedure p_0020; forward;", self.generate().sources["SAM.PAS"])

    def test_nested_routines_are_not_separate_definitions(self):
        text = self.generate().sources["U3.PAS"]
        self.assertEqual(text.count("procedure u3_0010;"), 1)
        self.assertIn("{$F+}\nprocedure u3_0020;\n  procedure u3_0010;", text)
        self.assertNotIn("u3_0010; forward", text)
        self.assertFalse(any(p["kind"] == "missing_routine" for p in self.generate().problems))

    def test_per_episode_routine_filter(self):
        one, two, three = (self.generate(ep) for ep in pb.EPISODES)
        self.assertNotIn("procedure p_sam2_0040;", one.sources["SAM.PAS"])
        self.assertIn("procedure p_sam2_0040;", two.sources["SAM.PAS"])
        self.assertIn("procedure p_sam2_0040;", three.sources["SAM.PAS"])
        self.assertIn("procedure u3_0000;", one.sources["U3.PAS"])
        self.assertNotIn("procedure u3_0000;", two.sources["U3.PAS"])

    def test_data_ownership_and_gaps_no_keep_calls(self):
        g = self.generate()
        self.assertEqual(g.globals["D_0000"]["unit"], "u5")
        self.assertEqual(g.globals["D_0294"]["unit"], "p")
        self.assertEqual(g.globals["D_0296"]["unit"], "u2")
        self.assertIn("reserved_21d6", g.sources["U4.PAS"])
        self.assertIn("reserved_70ee", g.sources["U9.PAS"])
        self.assertNotIn("d_0296:", g.sources["U8.PAS"])
        joined = "\n".join(g.sources.values())
        self.assertNotIn("if @", joined)
        self.assertNotIn("absolute", joined.lower())
        self.assertNotIn("SAMTYPES", joined)
        self.assertNotIn("GDATA", joined)

    def test_assembly_directive_and_external_declarations(self):
        text = self.generate().sources["U6.PAS"]
        self.assertIn("procedure u6_0010;", text.split("implementation")[0])
        self.assertIn("{$L U6.OBJ}", text)
        self.assertIn("procedure u6_0010; external;", text)
        self.assertNotIn("procedure u6_0010; begin", text)
        self.assertLess(text.index("{$L U6.OBJ}"), text.rindex("begin\nend."))

    def test_missing_routine_is_a_gap_never_an_empty_stub(self):
        del self.project.candidates["u1_0001"]
        generated = self.generate()
        self.assertIn("u1_0001", [p["message"] for p in generated.problems if p["kind"] == "missing_routine"])
        self.assertIn("GAP: missing accepted body u1_0001", generated.sources["U1.PAS"])
        self.assertNotIn("procedure u1_0001; begin", generated.sources["U1.PAS"])

    def test_undefined_object_header_not_invented(self):
        recipe, text = self.project.objects["u6"]
        self.project.objects["u6"] = (recipe, text.replace("public u6_0010", "public u6_0010,u6_0018"))
        g = self.generate()
        self.assertIn("u6_0018", [p["message"] for p in g.problems if p["kind"] == "missing_external_header"])
        self.assertNotIn("procedure u6_0018", g.sources["U6.PAS"])

    def test_missing_typed_constants_are_not_zero_filled(self):
        self.project.canonical = self.project.canonical.replace("const d_0000: array[0..3] of Byte = (1, 2, 3, 4);", "")
        g = self.generate()
        missing = [p for p in g.problems if p["kind"] == "missing_initializer"]
        self.assertEqual([(p["start"], p["end"]) for p in missing], [(0, 4)])
        self.assertIn("GAP: missing accepted typed constants DS:0000..0004", g.sources["U5.PAS"])
        self.assertNotIn("= (", g.sources["U5.PAS"])

    def test_conflicting_globals_and_overlaps_are_precise(self):
        c = self.project.candidates["u2_0001"]
        self.project.candidates[c.lid] = candidate(c.lid, c.sections["body"], "var d_0296: Word; d_0298: Word;")
        self.sizes["D_0298"] = 2
        g = self.generate()
        conflict = next(p for p in g.problems if p["kind"] == "global_conflict")
        self.assertEqual(conflict["message"], "d_0296")
        self.assertEqual({v["source"] for v in conflict["views"]}, {"canonical", "u2_0001"})
        overlap = next(p for p in g.problems if p["kind"] == "global_overlap")
        self.assertEqual(overlap["range"], [0x298, 0x29A])

    def test_local_type_names_are_scoped_and_literals_unchanged(self):
        for lid, bound in [("p_0010", 1), ("p_0020", 2)]:
            self.project.candidates[lid] = candidate(lid, f"procedure {lid}; var X: TLocal; begin end;",
                                                     f"type TLocal = array[0..{bound}] of Byte;")
        g = self.generate()
        self.assertIn("t_p_0010_tlocal = array[0..1] of Byte", g.sources["U8.PAS"])
        self.assertIn("t_p_0020_tlocal = array[0..2] of Byte", g.sources["U8.PAS"])
        self.assertIn("X: t_p_0010_tlocal", g.sources["SAM.PAS"])
        self.assertEqual(pb.rename("TLocal; 'TLocal'; { TLocal } (* TLocal *)", {"tlocal": "Other"}),
                         "Other; 'TLocal'; { TLocal } (* TLocal *)")

    def test_statement_line_locations_identify_original_body(self):
        g = self.generate()
        loc = g.routines["p_0100"]
        lines = g.sources["SAM.PAS"].splitlines()
        self.assertEqual(lines[loc["first_line"] - 1], "begin")
        self.assertEqual(lines[loc["last_line"] - 1], "end.")

    def test_source_generation_does_not_call_dos(self):
        with patch.object(pb.tpc, "compile_program", side_effect=AssertionError("DOS compile")), \
             patch.object(pb.asmproof, "assemble", side_effect=AssertionError("DOS assembly")):
            self.generate()

    def test_episode_specific_bindings_are_case_insensitive(self):
        self.project.data["d_sam2_02A4"] = {"sam1": None, "sam2": "02A4", "sam3": "02A4"}
        self.assertEqual(self.project.offset("D_SAM2_02A4", "sam3"), 0x2A4)
        self.assertIsNone(self.project.offset("D_SAM2_02A4", "sam1"))

    def test_pointer_alias_view_includes_pointee_dependencies(self):
        types = {"pitem": "PItem = ^TItem", "titem": "TItem = record X: Word; end",
                 "other": "Other = Byte"}
        self.assertEqual(set(pb.referenced_types("array[1..5] of PItem", types)), {"pitem", "titem"})


def executable(image, relocations=(), **fields):
    header = dict(zip(mz.FIELDS, [0x5A4D, 0, 0, len(relocations), 4, 0, 0xFFFF, 4, 0x4000, 0, 0, 0, 0x1C, 0]))
    header.update(fields)
    total = header["header_paras"] * 16 + len(image)
    header["last_page_bytes"], header["pages"] = total % 512, (total + 511) // 512
    out = bytearray(header["header_paras"] * 16)
    struct.pack_into("<14H", out, 0, *(header[n] for n in mz.FIELDS))
    for i, (seg, off) in enumerate(relocations):
        struct.pack_into("<HH", out, header["reloc_offset"] + i * 4, off, seg)
    return bytes(out) + image


class Comparisons(unittest.TestCase):
    def setUp(self):
        self.project, self.anchors, self.far, self.sizes = fixture()
        self.g = pb.generate(self.project, "sam1", self.sizes, self.far, self.anchors)
        self.project.atlas["units"] = ["p"]
        self.census = {"segments": [{"start": 0, "para": 0, "size": 16}], "ds_para": 1}
        self.original = bytes(range(32))
        self.map = """ Start  Stop   Length Name Class
 00000H 0000FH 00010H SAM CODE
 00010H 0001FH 00010H DATA DATA
 00020H 0401FH 04000H STACK STACK
 Publics by Value
 0000:0000 P_0010
 0001:0000 D_0000
 Program entry point at 0000:0000
"""

    def compare(self, image, relocs=()):
        original = executable(self.original, ((0, 2),))
        candidate_exe = executable(image, relocs)
        return pb.compare_image(self.project, self.g, self.census, self.original, ((0, 2),),
                                mz.parse(original).header, candidate_exe, self.map, self.anchors)

    def test_equal_segment_and_relocation_set(self):
        r = self.compare(self.original, ((0, 2),))
        self.assertTrue(r["image_equal"])
        self.assertEqual([s["status"] for s in r["segments"]], ["EQUAL", "EQUAL"])
        self.assertTrue(r["relocations"]["equal"])

    def test_raw_difference_names_routine_or_global(self):
        image = bytearray(self.original)
        image[3] ^= 1
        image[17] ^= 1
        r = self.compare(bytes(image))
        self.assertEqual([s["first_difference"] for s in r["segments"]], [3, 1])
        self.assertEqual(r["segments"][1]["original_owner"], "d_0000")
        self.assertEqual(r["segments"][0]["candidate_owner"], "P_0010")
        self.assertEqual(r["relocations"]["only_original"], [2])

    def test_duplicate_relocation_cannot_pass(self):
        self.assertFalse(self.compare(self.original, ((0, 2), (0, 2)))["relocations"]["equal"])

    def test_length_difference_at_boundary(self):
        self.assertEqual(pb.first_difference(b"abc", b"abcd"), 3)
        self.assertEqual(pb.first_difference(b"abc", b"ab"), 2)
        self.assertIsNone(pb.first_difference(b"abc", b"abc"))

    def test_gaps_preserve_storage_boundaries(self):
        self.assertEqual(pb.gaps([(3, 6), (5, 8), (10, 12)], 0, 15), [(0, 3), (8, 10), (12, 15)])

    def test_isolation_restores_shared_wrapper_paths(self):
        old = pb.tpc.CACHE, pb.tpc.SCRATCH, pb.tpc.INFLIGHT
        with pb.isolated_tools(pb.OUT / "test-isolation"):
            self.assertEqual(pb.tpc.CACHE, pb.OUT / "test-isolation" / "cc-cache")
        self.assertEqual((pb.tpc.CACHE, pb.tpc.SCRATCH, pb.tpc.INFLIGHT), old)


class BuildArrangements(unittest.TestCase):
    def test_separate_processes_use_only_freshly_compiled_tpus(self):
        sources = {"SAM.PAS": "program SAM; begin end.",
                   **{f"U{i}.PAS": f"unit U{i}; interface implementation end." for i in range(1, 10)}}
        binaries, calls = {"P.OBJ": b"unaltered object"}, []

        def compile(sources_in, main, options, *, binaries, fresh):
            self.assertEqual(sources_in, sources)
            self.assertEqual(options, ["/GD"])
            self.assertTrue(fresh)
            self.assertEqual(binaries["P.OBJ"], b"unaltered object")
            calls.append((main, dict(binaries)))
            outputs = {main[:-4] + ".TPU": main.encode()} if main != "SAM.PAS" else {"SAM.EXE": b"result"}
            return SimpleNamespace(ok=True, outputs=outputs)

        with patch.object(pb.tpc, "compile_program", side_effect=compile):
            final, units = pb.compile_sources(sources, binaries, ["/GD"], unit_processes=True)
        self.assertEqual([n for n, _ in calls], [*(f"U{i}.PAS" for i in range(9, 0, -1)), "SAM.PAS"])
        self.assertEqual(set(units), {f"u{i}" for i in range(1, 10)})
        self.assertEqual(final.outputs, {"SAM.EXE": b"result"})
        self.assertEqual(binaries, {"P.OBJ": b"unaltered object"})
        for index, (_, staged) in enumerate(calls):
            self.assertEqual({n for n in staged if n.endswith(".TPU")},
                             {f"U{i}.TPU" for i in range(9, 9-index, -1)})

    def test_failed_unit_never_reaches_program_link(self):
        failure = SimpleNamespace(ok=False, outputs={})
        with patch.object(pb.tpc, "compile_program", return_value=failure) as compiler:
            final, units = pb.compile_sources({"SAM.PAS": "program SAM; begin end."}, {}, [],
                                               unit_processes=True)
        self.assertIs(final, failure)
        self.assertEqual(units, {"u9": failure})
        self.assertEqual(compiler.call_count, 1)
        self.assertEqual(compiler.call_args.args[1], "U9.PAS")

    def test_default_arrangement_preserves_single_make_invocation(self):
        receipt = SimpleNamespace(ok=True, outputs={"SAM.EXE": b"result"})
        with patch.object(pb.tpc, "compile_program", return_value=receipt) as compiler:
            final, units = pb.compile_sources({"SAM.PAS": "source"}, {"P.OBJ": b"object"}, ["/GD"])
        self.assertIs(final, receipt)
        self.assertEqual(units, {})
        compiler.assert_called_once_with({"SAM.PAS": "source"}, "SAM.PAS", ["/GD"],
                                         binaries={"P.OBJ": b"object"}, fresh=False)


if __name__ == "__main__":
    unittest.main()
