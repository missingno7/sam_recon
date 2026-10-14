# Oracles

Fixture: the supplied Secret Agent (Apogee, 1992) episode files in `assets/` (never committed).
All files are hashed in `config/oracle.lock.json` (`fixture_files`); the lock is immutable.

| Episode | Packed SHA-256 | Size | Unpacked image | Relocs | Entry CS:IP | SS:SP | Extra paragraphs (min / max) |
|---|---|---:|---:|---:|---|---|---|
| SAM1 | `742f6c83…c63aa9` | 63,569 | 188,736 | 2,556 | 0000:1148 | 3528:4000 | 2836 / 0xAB14 |
| SAM2 | `8bf20a9f…abdb73` | 63,950 | 189,744 | 2,571 | 0000:11C3 | 3568:4000 | 2837 / 0xAB15 |
| SAM3 | `ce98f1a9…336922` | 63,888 | 189,792 | 2,573 | 0000:11C3 | 356B:4000 | 2837 / 0xAB15 |

## Unpacking and cross-check

* `tools/lz91.py` decodes LZEXE 0.91 (bit stream, back-references, the relocation table at loader
  offset 0x158) as a pure function of the file.
* LZEXE 0.91 adds the same growth to `e_maxalloc` as to `e_minalloc` unless `e_maxalloc` is 0xFFFF
  (duke1 never hit this case); the decoder undoes it, and `max = min + 0xA000` paragraphs is exactly
  Turbo Pascal's default `$M` heap maximum of 655,360 bytes.
* `tools/lz91_emulate.py` loads each packed file as DOS would into a unicorn emulator and runs **the
  file's own decompressor stub** at two load segments; image, relocation set and entry registers
  must agree with the decoder (`python tools/oracle.py --crosscheck`).
* `tools/repack.py` packs the canonical unpacked images with the pinned LZEXE 0.91 (DOSBox-X): all
  three reproduce the original files byte for byte.
* LZ91 stores relocations as ascending deltas, so the original relocation-table order and the
  original unpacked header are not observable; comparisons use the relocation *set* and the header
  fields that exist in a load image (CS:IP, SS:SP, min/max allocation).

## Image structure

Turbo Pascal 5.0 links code segments in reverse `uses`/initialisation order: the program, units
u1..u8, Crt, u9 (ProGraphx), Dos, System, then DATA (initialised typed constants of every module in
link order, then all variables in the same order) and a 16 KB stack. Only the program and u3 differ in
size between episodes. See [compiler.md](compiler.md) and [assembly.md](assembly.md).
