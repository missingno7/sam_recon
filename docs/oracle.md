# Oracles

Fixture: the supplied Duke Nukem ("Duke Nukum") v2.0 archive in `assets/`
(never committed). All files are hashed in `layout/oracle.lock.json`
(`fixture_files`). `DNHINT.EXE` is a separate LZ91-packed hint program and is
not a reconstruction target.

| Episode | Packed SHA-256 | Size | Unpacked image | Relocs | Entry |
|---|---|---:|---:|---:|---|
| DN1 | `7e31ad9f…87cc5f` | 54,688 | 118,010 | 1,581 | CS:IP 0000:0000, SS:SP 255E:00E6 |
| DN2 | `b155c58e…15910a` | 54,595 | 118,290 | 1,584 | 0000:0000, 2570:00E6 |
| DN3 | `7966ca89…81b802` | 54,439 | 117,830 | 1,586 | 0000:0000, 2553:00E6 |

## Unpacking and cross-check

* `tools/lz91.py` decodes LZEXE 0.91 (bit stream, back-references, the
  0x158-offset relocation table) as a pure function of the file.
* `tools/lz91_emulate.py` loads each packed file as DOS would into a unicorn
  emulator and runs **the file's own decompressor stub** until it jumps to the
  original entry, at two different load segments. Bytes that differ by the
  load-segment delta give the relocation set independently. Image, relocation
  set and SS:SP/CS:IP must equal `tools/lz91.py`'s result.
* UNLZEXE 0.5 (pinned in `layout/toolchain.json`) was tried as the second
  implementation, but it hangs under both MS-DOS Player and DOSBox-X, even when
  only printing its usage, so it is not used.

`python tools/oracle.py` re-derives everything and refuses any difference from
the lock; `--write-lock` refuses to overwrite an existing lock.

## Structure (all episodes)

| Region | DN1 linear | Size | Notes |
|---|---|---:|---|
| C0_TEXT | 0x00000 | 457 | Turbo C 2.0 C0L startup (incl. `DGROUP@`) |
| ASM_TEXT | 0x001C9 | 1,082 | hand-written assembly appended to C0's `_TEXT`; byte-identical in all episodes |
| CL.LIB `_TEXT` modules | 0x00603 | 885 | SETARGV … SCOPY (incl. the 4-byte REALCVT at 0x805, placed positionally) |
| G1_TEXT | 0x00978 | 65,393 | first-party C unit 1, frame 0097; `main` at 0097:FF16 |
| G2_TEXT | 0x108E9 | 18,053 / 18,116 / 18,146 | first-party C unit 2, frame 108E |
| CL.LIB far modules | 0x14F6E (DN1) | 11,964 | IOERROR … UNGETC, plus 2/3/5 bytes of TLINK fill before the paragraph-aligned DELAY_TEXT |
| DGROUP | 0x17E30 / 0x17E70 / 0x17E90 | | initialised data 20,170 / 20,386 / 19,894 B; BSS 35,042 B in all |

Episode data differs mostly by file-name extensions (`.DN1`/`.DN2`/`.DN3`) and
text; code differences are concentrated in G2 (12 parameterized, 2
episode-specific, 2 unresolved functions; see `evidence/atlas.json`).
