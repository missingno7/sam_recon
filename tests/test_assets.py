"""Synthetic, DOS-free format tests. No original assets are required."""
import contextlib
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

from tools import assets


def encode_fixture(clear):
    # Inverse operation used only to construct synthetic encrypted records.
    def reverse(n):
        value = 0
        for _ in range(8):
            value, n = (value << 1) | (n & 1), n >> 1
        return value
    return bytes(reverse(c ^ b"Copyright 1991 Peder Jungck\0"[i % 28])
                 for i, c in enumerate(clear))


def levels_fixture():
    records = []
    for level in range(17):
        rows = [b"501" + b" " * 37, b"B" * 40, b"Y" + b" " * 39,
                b"*" + b"Z" * 39]
        rows.extend(bytes((65 + i,)) * 40 for i in range(1, 24))
        rows.extend(b"\0" * 40 for _ in range(48 - len(rows)))
        records.extend(encode_fixture(row) + b"\xa5\x5a" for row in rows)
    return b"".join(records)


def pcx_fixture(rle=b"\x80\x00\x00\x80", width=8):
    header = bytearray(128)
    header[:4] = b"\x0a\x05\x01\x01"
    struct.pack_into("<4H", header, 4, 0, 0, width - 1, 0)
    header[65] = 4
    struct.pack_into("<H", header, 66, 1)
    for i in range(16):
        header[16 + 3 * i:19 + 3 * i] = bytes((i, i * 2, i * 3))
    return bytes(header) + rle


class AssetsTests(unittest.TestCase):
    def test_key_includes_nul_and_restarts_per_call(self):
        self.assertEqual(assets.decrypt(bytes(29)), assets.KEY + b"C")
        self.assertEqual(assets.decrypt(b"\x80\x01\xff"), b"B\xef\x8f")
        self.assertEqual(assets.decrypt(bytes(28))[27], 0)

    def test_sprite_header_is_once_per_bank_and_mask_is_write_enable(self):
        clear = bytearray(8064)
        clear[:3] = bytes((50, 2, 16))
        # First pixel is opaque palette 5; second has color 1 but is transparent.
        clear[3:8] = bytes((0x80, 0xc0, 0, 0x80, 0))
        # Final three pixels' source bytes overlap the *next Pascal record*.
        clear[3 + 157:3 + 160] = b"\x12\x34\x56"
        second = bytearray(clear)
        second[3] = 0x7f
        data = encode_fixture(clear) + encode_fixture(second) + encode_fixture(clear) * 14
        banks = assets.decode_banks(data)
        self.assertEqual(banks[0]["images"][0][-3:], b"\x12\x34\x56")
        self.assertEqual(banks[1]["images"][0][0], 0x7f)
        rgba = assets.decode_planar(banks[0]["images"][0], 16, 16)
        self.assertEqual(rgba[:4], bytes((*assets.DOS_PALETTE[5], 255)))
        self.assertEqual(rgba[7], 0)
        self.assertEqual(assets.decode_planar(banks[0]["images"][0], 16, 16,
                                             masked=False)[7], 255)

    def test_glyph_stride_and_padding(self):
        clear = bytearray(2048)
        clear[:3] = bytes((50, 1, 8))
        clear[3 + 49 * 40:3 + 50 * 40] = b"\xff" * 40
        banks = assets.decode_banks(encode_fixture(clear) * 3, glyphs=True)
        self.assertEqual(len(banks[2]["images"][49]), 40)
        self.assertEqual(len(bytes.fromhex(banks[0]["padding_hex"])), 45)
        self.assertEqual(assets.decode_planar(banks[0]["images"][49], 8, 8)[:4],
                         b"\xff" * 4)

    def test_level_bottom_first_overlay_does_not_consume_a_row(self):
        levels = assets.decode_levels(levels_fixture())
        self.assertEqual(len(levels), 17)
        level = levels[16]
        self.assertEqual(level["slot_offset"], 16 * 2016)
        self.assertEqual(bytes.fromhex(level["rows_hex"][24]), b"B" * 40)
        self.assertEqual(bytes.fromhex(level["rows_hex"][0]), b"Y" + b" " * 39)
        self.assertEqual(bytes.fromhex(level["rows_hex"][1]), b"B" * 40)
        self.assertEqual(level["foreground"][0]["row"], 0)
        self.assertEqual(level["records_consumed"], 27)
        self.assertEqual(level["ignored_trailer_hex"][0], "a55a")

    def test_pcx_planes_palette_bit_order_and_padding_crop(self):
        image = assets.decode_pcx(pcx_fixture(width=7))
        self.assertEqual(image["rgba"][:4], bytes((9, 18, 27, 255)))
        self.assertEqual(image["rgba"][4:8], bytes((0, 0, 0, 255)))
        self.assertEqual(len(image["rgba"]), 7 * 4)
        self.assertEqual(image["trailing_bytes"], 0)

    def test_pcx_rle_and_bad_input(self):
        image = assets.decode_pcx(pcx_fixture(b"\xc4\x80"))
        self.assertEqual(image["rgba"][:4], bytes((15, 30, 45, 255)))
        for stream in (b"", b"\xc4", b"\xc0\x00", b"\xc5\x80"):
            with self.subTest(stream=stream), self.assertRaises(ValueError):
                assets.decode_pcx(pcx_fixture(stream))

    def test_sound_signed_terminator_and_metadata_columns(self):
        words = [440, 0, -1] + [0] * 297 + [7, 5000, 2, -12, 0]
        effects = assets.decode_sounds(encode_fixture(struct.pack("<305h", *words) * 12))
        self.assertEqual(effects[11]["samples_hz"], (440, 0))
        self.assertEqual(effects[0]["terminator_column"], 3)
        self.assertEqual(effects[0]["priority"], 7)
        self.assertEqual(effects[0]["gate_modulus"], 2)
        self.assertEqual(effects[0]["unused_columns_304_305"], (-12, 0))

    def test_config_unaligned_words_and_pascal_string_length(self):
        data = bytearray(467)
        data[:6] = b"\x03ABCxx"
        struct.pack_into("<10iB8H", data, 410, *range(10), 1,
                         0x48, 0x50, 0x4b, 0x4d, 0x1d, 0x38, 1, 0)
        config = assets.decode_config(data)
        self.assertEqual(config["score_lines"][0], "ABC")
        self.assertEqual(config["bindings"]["fire"], 0x38)
        self.assertEqual(config["alternate_video"], 1)
        data[0] = 41
        with self.assertRaises(ValueError):
            assets.decode_config(data)

    def test_save_packed_unaligned_fields(self):
        data = bytearray(72)
        struct.pack_into("<hhi3h", data, 0, 320, -16, 123456, 7, 99, 2)
        data[38] = 1
        struct.pack_into("<h", data, 39, 321)
        struct.pack_into("<4h", data, 43, 100, -2, 51, 17)
        data[70:72] = b"\x01\x01"
        save = assets.decode_save(data)
        self.assertEqual(save["player_y"], -16)
        self.assertEqual(save["score"], 123456)
        self.assertEqual(save["confusion_time_left"], 321)
        self.assertEqual(save["auxiliary_value"], -2)
        self.assertEqual(save["completed_level_flags"][-1], 1)
        self.assertEqual(save["extra_ammo_cheat_used"], 1)

    def test_png_chunk_crc_and_inflated_rows(self):
        rgba = bytes(range(8))
        encoded = assets.png_bytes(2, 1, rgba)
        self.assertEqual(encoded[:8], b"\x89PNG\r\n\x1a\n")
        offset = 8
        while offset < len(encoded):
            length = struct.unpack_from(">I", encoded, offset)[0]
            kind = encoded[offset + 4:offset + 8]
            payload = encoded[offset + 8:offset + 8 + length]
            crc = struct.unpack_from(">I", encoded, offset + 8 + length)[0]
            self.assertEqual(zlib.crc32(kind + payload) & 0xffffffff, crc)
            if kind == b"IDAT":
                self.assertEqual(zlib.decompress(payload), b"\0" + rgba)
            offset += length + 12

    def test_cli_export_is_read_only_and_rejects_input_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "originals"
            source.mkdir()
            path = source / "SAM1.TTL"
            before = pcx_fixture()
            path.write_bytes(before)
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(assets.main([str(source), "--out", str(root / "out")]), 0)
            self.assertEqual(path.read_bytes(), before)
            result = json.loads((root / "out/SAM1.TTL.json").read_text())
            self.assertEqual(result["pcx"]["width"], 8)
            with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                assets.main([str(source), "--out", str(source / "oops")])

    def test_rejects_truncated_fixed_formats(self):
        for decoder in (assets.decode_levels, assets.decode_sounds, assets.decode_config,
                        assets.decode_save, assets.decode_banks):
            with self.subTest(decoder=decoder.__name__), self.assertRaises(ValueError):
                decoder(b"\0" * 10)


if __name__ == "__main__":
    unittest.main()
