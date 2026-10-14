"""Read Secret Agent assets without DOS or third-party packages.

See docs/formats.md for the source evidence. Inputs are never changed. PNGs,
text maps, byte-exact row hex and sound/config JSON go to --out (build/assets
by default). This is a format inspector, not a level renderer or game emulator.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zlib

KEY = b"Copyright 1991 Peder Jungck\0"
REVERSE = bytes(int(f"{n:08b}"[::-1], 2) for n in range(256))
SPRITE_BANK_ORDER = (851, 1, 101, 401, 451, 601, 651, 701,
                     751, 301, 151, 201, 801, "player", 351, 251)
DOS_PALETTE = tuple(tuple(bytes.fromhex(c)) for c in (
    "000000", "0000aa", "00aa00", "00aaaa", "aa0000", "aa00aa",
    "aa5500", "aaaaaa", "555555", "5555ff", "55ff55", "55ffff",
    "ff5555", "ff55ff", "ffff55", "ffffff"))
CONTROL_GLYPHS = "·☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼"


def decrypt(data: bytes) -> bytes:
    """One DECODE.ASM call: reverse bits, XOR the 28-byte key from index 0."""
    return bytes(REVERSE[value] ^ KEY[i % len(KEY)]
                 for i, value in enumerate(data))


def _size(data: bytes, expected: int, kind: str) -> None:
    if len(data) != expected:
        raise ValueError(f"{kind}: expected {expected} bytes, got {len(data)}")


def decode_planar(data: bytes, width: int, height: int,
                  palette=DOS_PALETTE, masked: bool = True) -> bytes:
    """ProGraphx groups: write mask, plane 0, 1, 2, 3; MSB is leftmost.

    A mask bit of ONE writes the pixel. Zero preserves the destination. The
    opaque blitters skip the mask byte but still consume it from the source.
    """
    if width <= 0 or width % 8 or height <= 0:
        raise ValueError("planar dimensions must be positive; width divisible by 8")
    _size(data, width // 8 * height * 5, "planar image")
    pixels = bytearray()
    for y in range(height):
        for group in range(width // 8):
            offset = (y * (width // 8) + group) * 5
            mask, *planes = data[offset:offset + 5]
            for bit in range(7, -1, -1):
                index = sum(((plane >> bit) & 1) << p
                            for p, plane in enumerate(planes))
                pixels.extend((*palette[index],
                               255 if not masked or mask & (1 << bit) else 0))
    return bytes(pixels)


def decode_banks(data: bytes, glyphs: bool = False) -> list[dict]:
    bank_bytes, width, height, stride, count = (
        (2048, 8, 8, 40, 3) if glyphs else (8064, 16, 16, 160, 16))
    _size(data, bank_bytes * count, "glyph file" if glyphs else "sprite file")
    banks = []
    for number in range(count):
        bank = decrypt(data[number * bank_bytes:(number + 1) * bank_bytes])
        if bank[:3] != bytes((50, width // 8, height)):
            raise ValueError(f"bank {number}: unexpected header {bank[:3].hex()}")
        images = [bank[3 + i * stride:3 + (i + 1) * stride] for i in range(50)]
        banks.append({"bank": number, "logical_base": (
            ("popup", "extended", "status")[number] if glyphs
            else SPRITE_BANK_ORDER[number]),
            "width": width, "height": height, "images": images,
            "padding_hex": bank[3 + 50 * stride:].hex()})
    return banks


def decode_levels(data: bytes) -> list[dict]:
    """Decode 17 fixed slots; preserve overlays separately and keep ignored bytes."""
    _size(data, 17 * 48 * 42, "level file")
    levels = []
    for level in range(17):
        start = level * 48 * 42
        records = [data[start + i * 42:start + (i + 1) * 42] for i in range(48)]
        rows = [decrypt(row[:40]) for row in records]
        try:
            backdrop = int(rows[0][:3].decode("ascii"))
        except (ValueError, UnicodeError) as exc:
            raise ValueError(f"level {level + 1}: invalid backdrop") from exc
        base_rows = [None] * 25
        base_rows[24] = rows[1]
        foreground = []
        row_number, record_number = 0, 2
        while row_number < 24:
            if record_number >= 48:
                raise ValueError(f"level {level + 1}: incomplete map")
            row = rows[record_number]
            if row.startswith(b"*"):
                if row_number == 0:
                    raise ValueError(f"level {level + 1}: overlay before row zero")
                foreground.append({"row": row_number - 1, "record": record_number,
                                   "bytes_hex": row.hex()})
            else:
                base_rows[row_number] = row
                row_number += 1
            record_number += 1
        levels.append({"level": level + 1, "slot_offset": start,
                       "backdrop": backdrop, "header_hex": rows[0].hex(),
                       "rows_hex": [row.hex() for row in base_rows],
                       "foreground": foreground,
                       "records_consumed": record_number,
                       "ignored_record_hex": [r.hex() for r in records[record_number:]],
                       "ignored_trailer_hex": [r[40:].hex() for r in records]})
    return levels


def decode_pcx(data: bytes) -> dict:
    """The shipped screens: PCX v5, RLE, 1 bit/plane, four planes."""
    if len(data) < 128 or data[:4] != b"\x0a\x05\x01\x01":
        raise ValueError("expected a v5 RLE 1-bit PCX header")
    xmin, ymin, xmax, ymax = struct.unpack_from("<4H", data, 4)
    width, height = xmax - xmin + 1, ymax - ymin + 1
    planes = data[65]
    row_bytes = struct.unpack_from("<H", data, 66)[0]
    if not (0 < width <= 4096 and 0 < height <= 4096 and planes == 4
            and (width + 7) // 8 <= row_bytes <= 4096):
        raise ValueError("unsupported PCX dimensions/planes/stride")
    expected = row_bytes * planes * height
    decoded = bytearray()
    offset = 128
    while len(decoded) < expected:
        if offset >= len(data):
            raise ValueError("truncated PCX RLE")
        value = data[offset]
        offset += 1
        count = 1
        if value & 0xc0 == 0xc0:
            count = value & 0x3f
            if not count or offset >= len(data):
                raise ValueError("invalid/truncated PCX run")
            value = data[offset]
            offset += 1
        if len(decoded) + count > expected:
            raise ValueError("PCX RLE exceeds raster size")
        decoded.extend(bytes((value,)) * count)
    palette = [tuple(data[16 + p * 3:19 + p * 3]) for p in range(16)]
    rgba = bytearray()
    for y in range(height):
        for x in range(width):
            index = sum(((decoded[(y * 4 + p) * row_bytes + x // 8]
                          >> (7 - x % 8)) & 1) << p for p in range(4))
            rgba.extend((*palette[index], 255))
    return {"width": width, "height": height, "bytes_per_plane_row": row_bytes,
            "palette": palette, "rgba": bytes(rgba),
            "compressed_bytes_consumed": offset - 128,
            "trailing_bytes": len(data) - offset}


def decode_sounds(data: bytes) -> list[dict]:
    _size(data, 7320, "sound bank")
    data = decrypt(data)
    sounds = []
    for i in range(12):
        words = struct.unpack_from("<305h", data, i * 610)
        try:
            end = words[:300].index(-1)
        except ValueError as exc:
            raise ValueError(f"effect {i + 1}: no terminator in sample area") from exc
        sounds.append({"bank_effect": i + 1, "samples_hz": words[:end],
                       "terminator_column": end + 1, "priority": words[300],
                       "unused_column_302": words[301], "gate_modulus": words[302],
                       "unused_columns_304_305": words[303:], "words": words})
    return sounds


def decode_config(data: bytes) -> dict:
    _size(data, 467, "configuration")
    lines = []
    for i in range(10):
        record = data[i * 41:(i + 1) * 41]
        if record[0] > 40:
            raise ValueError("configuration shortstring length exceeds 40")
        lines.append(record[1:1 + record[0]].decode("cp437"))
    return {"score_lines": lines, "scores": struct.unpack_from("<10i", data, 410),
            "sound_enabled": data[450],
            "bindings": dict(zip(("up", "down", "left", "right", "jump", "fire"),
                                 struct.unpack_from("<6H", data, 451))),
            "alternate_video": struct.unpack_from("<H", data, 463)[0],
            "joystick_enabled": struct.unpack_from("<H", data, 465)[0]}


def decode_save(data: bytes) -> dict:
    _size(data, 72, "saved game")
    result = dict(zip(("player_x", "player_y", "score", "progress_count", "ammo",
                       "projectile_limit"), struct.unpack_from("<hhi3h", data)))
    result["blueprint_flags"] = list(data[14:34])
    result.update(zip(("speed_boost", "speed_time_left"),
                      struct.unpack_from("<2h", data, 34)))
    result["controls_reversed"] = data[38]
    result["confusion_time_left"] = struct.unpack_from("<h", data, 39)[0]
    result["confusion_ended_pending"] = data[41]
    result["slow_movement"] = data[42]
    result.update(zip(("slow_time_left", "auxiliary_value", "entrance_animation_tick",
                       "entered_level_number"), struct.unpack_from("<4h", data, 43)))
    result["completed_level_flags"] = list(data[51:71])
    result["extra_ammo_cheat_used"] = data[71]
    return result


def png_bytes(width: int, height: int, rgba: bytes) -> bytes:
    if width <= 0 or height <= 0:
        raise ValueError("PNG dimensions must be positive")
    _size(rgba, width * height * 4, "RGBA pixels")
    def chunk(kind, payload):
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff))
    raster = b"".join(b"\0" + rgba[y * width * 4:(y + 1) * width * 4]
                      for y in range(height))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raster)) + chunk(b"IEND", b""))


def _atlas(bank: dict, opaque: bool = False, masks: bool = False) -> tuple:
    w, h = bank["width"], bank["height"]
    width, height = (w + 2) * 10, (h + 2) * 5
    raster = bytearray(width * height * 4)
    for i, image in enumerate(bank["images"]):
        pixels = decode_planar(image, w, h, masked=not opaque)
        if masks:
            pixels = b"".join(bytes((pixels[j + 3],) * 3 + (255,))
                              for j in range(0, len(pixels), 4))
        x, y = (i % 10) * (w + 2), (i // 10) * (h + 2)
        for row in range(h):
            target = ((y + row) * width + x) * 4
            raster[target:target + w * 4] = pixels[row * w * 4:(row + 1) * w * 4]
    return width, height, bytes(raster)


def _map_text(row: bytes) -> str:
    return "".join(CONTROL_GLYPHS[b] if b < 32 else
                   "⌂" if b == 127 else bytes((b,)).decode("cp437") for b in row)


def export_file(path: Path, out: Path) -> dict:
    data = path.read_bytes()
    name = path.name.upper()
    result = {"file": path.name, "size": len(data),
              "sha256": hashlib.sha256(data).hexdigest()}
    out.mkdir(parents=True, exist_ok=True)
    if re.fullmatch(r"SAM[123]0[12]\.GFX", name):
        banks = decode_banks(data, glyphs=name.endswith("02.GFX"))
        result["banks"] = []
        for bank in banks:
            stem = f"{path.stem}-bank{bank['bank']:02d}-{bank['logical_base']}"
            for suffix, opaque, masks in (("masked", False, False),
                                           ("opaque", True, False), ("mask", False, True)):
                w, h, rgba = _atlas(bank, opaque, masks)
                (out / f"{stem}-{suffix}.png").write_bytes(png_bytes(w, h, rgba))
            result["banks"].append({k: v for k, v in bank.items() if k != "images"})
    elif re.fullmatch(r"SAM[123]03\.GFX", name):
        result["levels"] = decode_levels(data)
        for level in result["levels"]:
            text = [f"Level {level['level']} backdrop {level['backdrop']} (40 x 25)",
                    *(_map_text(bytes.fromhex(r)) for r in level["rows_hex"])]
            for layer in level["foreground"]:
                text.extend((f"Foreground row {layer['row']} record {layer['record']}",
                             _map_text(bytes.fromhex(layer["bytes_hex"]))))
            (out / f"{path.stem}-level{level['level']:02d}.txt").write_text(
                "\n".join(text) + "\n", encoding="utf-8")
    elif path.suffix.upper() in (".APO", ".TTL", ".CRD", ".END"):
        image = decode_pcx(data)
        (out / f"{path.name}.png").write_bytes(png_bytes(
            image["width"], image["height"], image.pop("rgba")))
        result["pcx"] = image
    elif re.fullmatch(r"SAM[123]0[123]E\.SND", name):
        result["effects"] = decode_sounds(data)
        bias = (int(name[5]) - 1) * 12
        for effect in result["effects"]:
            effect["game_effect"] = bias + effect["bank_effect"]
    elif path.suffix.upper() == ".CFG":
        result["config"] = decode_config(data)
    elif path.suffix.upper() == ".SAV":
        result["save"] = decode_save(data)
    else:
        raise ValueError(f"unsupported asset: {path.name}")
    (out / f"{path.name}.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    return result


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="*", type=Path, help="asset files or directories")
    parser.add_argument("--out", type=Path, default=Path("build/assets"))
    args = parser.parse_args(argv)
    inputs = args.inputs or [Path("assets")]
    files = []
    for item in inputs:
        if item.is_dir():
            files.extend(p for p in sorted(item.iterdir()) if p.suffix.upper() in
                         (".GFX", ".SND", ".APO", ".TTL", ".CRD", ".END", ".CFG", ".SAV"))
        else:
            files.append(item)
    if not files:
        parser.error("no assets found")
    out = args.out.resolve()
    # Refuse even an accidental export into an input's asset directory.
    if any(out == p.parent.resolve() or p.parent.resolve() in out.parents for p in files):
        parser.error("output must be outside the input asset directories")
    manifest = []
    for path in files:
        try:
            result = export_file(path, out)
        except (ValueError, OSError) as exc:
            parser.exit(1, f"{path}: {exc}\n")
        manifest.append({k: result[k] for k in ("file", "size", "sha256")})
        print(f"{path.name}: {len(path.read_bytes())} bytes decoded")
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
