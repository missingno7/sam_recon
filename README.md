# sam_recon

Historical reconstruction of Apogee's **Secret Agent** (1992), episodes 1-3 (`SAM1.EXE`,
`SAM2.EXE`, `SAM3.EXE`): readable Turbo Pascal 5.0 and TASM source in [game/](game/) that the
original toolchain compiles back into the original programs.

Original game files and anything derived from them (unpacked images, builds) are never committed;
supply them in `assets/` (or `$SAM_ASSET_DIR`).

## Result

`game/` is built with the pinned Turbo Pascal 5.0 (TPC, TURBO.TPL), Turbo Assembler 1.0 and compared
with the originals (`python tools/verify.py`):

| Episode | Load image | Equal bytes | Residue bytes |
|---|---:|---:|---:|
| SAM1 | 188,736 | 188,644 | 92 |
| SAM2 | 189,744 | 189,664 | 80 |
| SAM3 | 189,792 | 189,761 | 31 |

Every byte of code (the game, the Genus PCX Toolkit 3.56 and ProGraphx 2.0 libraries, and Borland's
System/Crt/Dos runtime), every initialised data byte, the relocation set and the header fields of the
load image are identical. The only differences are inside the 102 bytes per episode of undefined
(`DB ?`) storage in two linked assembly objects, which the original build filled with leftover
compiler memory (fragments of the original source text and symbol tables in SAM1/SAM2; traced in
[docs/object-holes.md](docs/object-holes.md)). They are documented residue (`config/residue.json`),
compared and reported, never filled or patched; consequently the LZEXE-packed files are not equal.

## Layout

| Path | Contents |
|---|---|
| [game/](game/) | the source: SAM.PAS (program), SAMPLAY, SAMLEVEL, SAMUI, SAMSOUND, SAMDATA, TEXT80, GAMEJOY, PCXGENUS, PROGRPHX units, six .ASM objects, BUILD.BAT; episode differences as `{$IFDEF SAMn}` |
| tools/ | `oracle.py` (lock, decode, cross-check), `lz91.py`, `lz91_emulate.py`, `repack.py`, `verify.py` (build + compare), `validate.py`, `assets.py` (asset decoder) |
| config/ | oracle lock, pinned toolchain hashes, compiler profile, residue ranges |
| docs/ | [oracle](docs/oracle.md), [compiler](docs/compiler.md), [assembly libraries](docs/assembly.md), [object holes](docs/object-holes.md), [file formats](docs/formats.md), [actors](docs/actors.md), [runtime model](docs/runtime.md), [roadmap](docs/roadmap.md), [names and evidence](docs/names.json) |

## Requirements

* Python 3.11 with `capstone` 5.0.9 and `unicorn` 2.1.4 (`python tools/setup_env.py` vendors them
  into `build/python`).
* Pinned tools outside the repository (hashes in `config/toolchain.json`): Turbo Pascal 5.0,
  TASM 1.0, MS-DOS Player (`C:\tools\nmlgcdos`), DOSBox-X and LZEXE 0.91 for packing.

```bash
python tools/setup_env.py
python tools/validate.py            # oracle, build of game/ for all three episodes, tests
python tools/validate.py --crosscheck --pack
```

## History

The reconstruction followed the method of the sibling project duke1_recon: locked oracle -> census
and cross-episode atlas -> every routine proven byte-identical in a harness that reproduced the
original data segment (GPT-6 Luna / GPT-6.1 Sol workers, supervised) -> declaration consolidation ->
whole-program link -> standalone tree -> readability passes. The per-routine sources, recipes and the
matching tools are preserved in the git tag `matching-archive`. Next phase: an SDL3/Android port
generated from `game/` ([docs/roadmap.md](docs/roadmap.md)).
