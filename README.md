# sam_recon

Historical matching reconstruction of Apogee's **Secret Agent** (1992), episodes 1-3
(`SAM1.EXE`, `SAM2.EXE`, `SAM3.EXE`), treated as three historical builds of one logical
program. Same method as `duke1_recon`:

> original binary -> independent evidence -> historically compiled candidate -> exact proof -> canonical source

Original game files and anything derived from them are ignored by git and never redistributed.

## Status

* **Oracles locked:** all three LZEXE 0.91 executables are hashed, unpacked by `tools/lz91.py`,
  cross-checked by executing each file's own LZEXE stub in unicorn at two load segments
  (`tools/oracle.py --crosscheck`), and **repacked byte-identically** by the pinned LZEXE 0.91
  (`tools/repack.py --oracle`).
* **Language:** Turbo Pascal (not C): unit-initialisation far-call chain at the entry point,
  length-prefixed string literals in code segments, separate 16 KB stack segment,
  `maxalloc = minalloc + 0xA000` (TP default `$M` heap maximum 655360). The System unit
  matches Turbo Pascal 5.0 best (provisional; see `evidence/`).

## Requirements

* Python 3.11 with `capstone` 5.0.9 and `unicorn` 2.1.4; `python tools/setup_env.py` vendors them
  into `build/python`.
* Pinned tools outside the repo (hashes in `layout/toolchain.json`).
* The original files in `assets/` (or `$SAM_ASSET_DIR`).

```bash
python tools/setup_env.py
python tools/oracle.py --crosscheck
python tools/repack.py --oracle
```
