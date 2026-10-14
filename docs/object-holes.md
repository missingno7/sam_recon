# Object holes: residual compiler-buffer bytes

> Research report written during the matching phase. The probes, tools and evidence it cites
> (`probes/`, `tools/`, `evidence/` that no longer exist) are preserved in the git tag
> `matching-archive`; `build/workers/...` paths were uncommitted worker scratch (they hold bytes
> derived from the originals) and are reproduced by rerunning those probes. Identifiers are the
> coordinate names of that phase (see docs/names.json for the mapping to the names used in game/).

SAM3 remains **DIFF**. No qualifying zero-producing arrangement was found.
The default build and the implemented `--unit-processes` arrangement produce
the **same complete SAM.EXE**, not merely the same holes. There are 31 differing
load-image bytes, all in the leading undefined storage of P and U9. All defined
code, DATA, relocation sites, routine entries and the initialization/link layout
still match. LZEXE comparison is **SKIPPED**, because progbuild correctly requires
an equal load image before packing. No packed equality claim is made.

## Exact final results

Commands:

```
python tools/progbuild.py --episodes sam3 --unit-processes --keep
python tools/progbuild.py --episodes sam1,sam2 --unit-processes --keep
python tools/progbuild.py --episodes sam3
python -B -m unittest discover -s tests -v
```

The build commands exit 1 (DIFF, zero input/compilation blockers). All **60 tests**
pass, including three new build-arrangement tests. `--unit-processes` invokes
fresh pinned TPC processes for U9, U8, ... U1, then SAM. Each subsequent process
receives only the unchanged assembled objects and TPUs produced by preceding
invocations from the generated accepted sources. TPU bytes are never edited.
Every unit receipt is recorded in `report.json`; `--keep` retains their TPUs and
individual compiler logs. The default single `/M` build is unchanged.

| Episode | Different image bytes | First P difference | First U9 difference | Relocations | Packed |
|---|---:|---:|---:|---|---|
| SAM1 | 89 | 514A | 00E6 | EQUAL | SKIPPED |
| SAM2 | 80 | 51CC | 00E6 | EQUAL | SKIPPED |
| SAM3 | 31 | 51CC | 00E6 | EQUAL | SKIPPED |

SAM3 load-image SHA-256:
`73fdf98add33c9a014c4a25fe1f1d3f52f9f69453af9e9def407109651f331d8`.

| SAM3 undefined range | Original | Produced |
|---|---|---|
| P:51CC..51D3 | `00000000000000` | `10000200bc1104` |
| U9:00E6..0100 | `0000000000000000000000000000000000000000000000000000` | `50000450049a100230300000000212460000dd000204bf0e0050` |
| U9:0110..011C | `000000000000000000000000` | `00061e570200fb0000080104` |

All nine later U9 hole ranges are already zero in these SAM3 builds. Separately
saved reports/products are under `arrangements/unit-processes/<episode>/` and
`arrangements/make/sam3/`. `measurements.json` records hashes and byte counts.

## Controlled arrangements tested

`probe.py` stages unchanged accepted source snapshots and objects through the
existing pinned tpc wrapper, with caches/scratch confined to this worker. These
are investigations, not alternative accepted source recipes.

| Change | Result |
|---|---|
| U9 alone in a fresh process, then SAM reusing its TPU | Same 31 bytes |
| SAM in a fresh process with all game TPUs already built | Same 31 bytes |
| Every game unit in its own fresh process | Same complete EXE |
| Move `$L` before uses/interface, or immediately after module header | Same complete image |
| TPC `/L` (disk link buffer), `/Q`, `/B`, `/V`, omit `/GD` | Same complete load image |
| Reverse external implementation declarations | Same complete image |
| Make existing U9 variables private | Same complete image |
| Put interface or external declarations in an include | Only line-record residue changes; no zero result |
| Name the four existing copyright/address literals as ordinary constants | Only line-record residue changes |
| Disable `$L` local symbols | Same complete image |
| Disable `$D` debug information | Different residue; still nonzero |
| Compact source to conventional 110-column lines, or split semicolons | Different line/code records; still nonzero |
| Load existing U8/U3/U1 TPUs before rebuilding U9 | Same complete image |

An `$O+` probe changed defined linked code/layout and was rejected as a candidate.
TP5 also rejects includes inside a statement block (Error 118); putting the final
module `end.` inside an include produced Error 10. Failed probes are retained.
Repeated unchanged families were stopped. No marker comments, marker literals,
dummy globals, dummy Pascal routines, seeded TPUs, hole initializers or object
patches were used.

## Buffer mechanism: directly established for the current build

`compiler_inspect.py` disassembles the unchanged pinned TPC.EXE. `trace_tpc.py`
executes that binary in a diagnostic Unicorn DOS shim and snapshots buffers; it
is **not** the acceptance compiler. The diagnostic SAM.EXE **load image exactly
equals** the pinned MS-DOS Player result above. U9 TPU differs only in three
source-file date/time metadata bytes at file offsets 06EF..06F2, supplied by the
diagnostic DOS shim. Its linked code and holes agree.

TPC code offsets and compiler DS fields:

* `098E` (program) and `0A04` (unit) call `80B7`, the deferred object importer,
  after Pascal declaration/body processing and `0CF8`'s final source check.
  `$L` records the object request; its textual position does not import it early.
* OMF dispatch is at `8143..8190`. SEGDEF handling at `8238..8244` extends the
  **code buffer** descriptor at DS:1990 (used size), 1992 (segment), 1994
  (capacity), through allocator `141F`. It does not initialize reserved bytes.
* Allocator `1433..14A9` grows earlier buffers and moves later buffers with
  `90BD`. It copies their **used bytes**, leaving stale data in other portions
  of the newly occupied memory. Growth is normally 512, 1024, 2048, ... bytes,
  then 8192-byte increments. This is the concrete overlap/reuse mechanism.
* LEDATA handling `8388..83B7` copies only supplied data into the code buffer at
  the current contribution start (DS:194E) plus the record offset. It does not
  touch holes. LIDATA handling likewise only emits defined data.
* The temporary instruction stream is DS:19A8/19AA; final machine code is
  assembled from it by `7528..765A`. The stream includes byte/word instructions,
  symbolic fixups and `$D+` line records, rather than just raw x86 code.

The three current differing ranges have **exact provenance**:

| Output range | Earlier temporary instruction stream |
|---|---|
| U9:00E6..0100 | `trace-u9/tokens-before-17.bin`, offset 00E6 |
| U9:0110..011C | the same file, offset 0110 |
| P:51CC..51D3 | `trace-sam/tokens-before-80.bin`, offset 11CC |

The U9 stream is the current U9 initializer; the P stream is the current SAM
main statement body. Neither differing range is residue from a preceding game
unit in the default or separate-process build. The exact bytes exist in the
code-buffer tail **before** the importer reads its OBJ. Relinking an existing
U9 TPU preserves its filler, confirming the earlier asmproof result.

This is stronger than merely observing repeatable EXEs: source placement and
fresh processes do not change this current-module allocation sequence in the
tested arrangements.

## What compilation history can change

Three additional diagnostics compile **real accepted** U8, U3 or U1 code before
a separately named `PGX` graphics wrapper, then use the freshly produced PGX
TPU in an otherwise equivalent game link. A minimal build driver selects the
units; it contains no data or marker routines. The differently named graphics
wrapper makes this predecessor compilation possible without the predecessor
depending on the unit being rebuilt. These are history diagnostics, not a
claimed historical unit name or a proposed accepted arrangement.

Each experiment introduces different stale machine code into the **later**
graphics holes, while both leading graphics holes and the program hole remain
the same. The linked images differ in 58, 71 and 80 bytes respectively, all in
undefined object storage. Example U9:1586..1590 becomes:

* after U8: `03c606000000c6060000`
* after U3: `03f881c7dbff06578b46`
* after U1: `007403e9de008b7e0ab1`

Thus preceding reconstructed game compilation can naturally populate distant
holes, but these tested orders do not explain the original SAM1/SAM2 residue or
make SAM3 zero. Adding an otherwise unnecessary Pascal body to preallocate
buffers would be steering; no such body was added.

## SAM1 and SAM2: attribution and limits

**SAM1** has mixed binary records and case-preserving, punctuated, indented
source-like fragments (`bg(objs[z].s`, `R3^.Imag`, `   restore`, `].y+1`,
`dy+16)`). The first three full fragments occur only once in the original load
image, at these holes. They strongly suggest retained game source/editor text.
They are not evidence of literal initialization in the OBJ. As established by
the prior asmproof literal probe, discarded source-looking string literals can
also leave this sort of text; these scattered bytes cannot exclude that cause.

There is an additional important limit on **TPC-specific** attribution: the
traced TPC reads Pascal text in 1024-byte chunks at its static compiler
DS:42D8 buffer. Its generated code buffer is in a distinct heap allocation.
The trace contains no direct reuse of that static source-read buffer as game
code. Consequently a claim that these SAM1 bytes came directly from TPC's file
read buffer is unsupported. Reuse of a Turbo IDE editor heap, or discarded
compiled literal storage, is plausible, but neither is proved here. The text
suggests object drawing/background restoration logic; it does **not** uniquely
identify which unit, source file, or preceding compilation generated it.

**SAM2** is much more characteristic of symbol storage: length-prefixed,
uppercase identifier fragments, including an 0B-length `TELEPORTCN...` record
(consistent with `TELEPORTCNT`), `DRAFTQ`, `IBDIR`, and partial PCX/SFL names,
surrounded by small pointer/index/flag fields. The traced current symbol buffer
DS:1958/195A contains the same structural idiom: link words, length-prefixed
uppercase source identifiers, symbol-kind bytes and type/reference records.
This gives strong evidence for reused symbol-table/interface records, not a
machine-code or raw case-preserving source-text buffer. It does not establish
whether those records came from U9's original declarations, imported units,
earlier source compilation, or IDE compilation state. The observed names are
game/graphics related, but exact ownership and declaration order are unknown.

None of `TELEPORT`, `TELEPORTCNT`, `DRAFTQ`, `IBDIR`, or the three SAM1 source
fragments occur in the accepted Pascal source snapshot. Reordering its units
therefore cannot faithfully recreate those historical identifier/text records.
Independent recovery of original aliases, declarations/types, complete unused
library/game source, and the compiler environment/history would be needed.
Merely adding these names or text to plant them in buffers would be a seed,
not a natural reconstruction, and was not attempted.

All three original program-object holes are zero; the separate-process build
does **not** explain those zeros either. The original U9 filler differs among
episodes, so it cannot have come from one identical cached U9 TPU reused for
all three builds. It requires separately built TPUs or otherwise differing
historical object/compiler inputs. SAM3's zeros alone cannot distinguish
cleared/unoccupied compiler storage from an original OBJ that actually defined
zeros; this investigation does not resolve that original-object ambiguity.

## Concrete remaining blocker and next discriminating work

The current compiler creates these leading residues from the **same module's**
temporary instruction stream. No tested arrangement removes them without
changing defined output or introducing artificial allocator steering. The next
useful input is a genuine complete historical ProGraphx Pascal interface and
game source/build record, including omitted unlinked routines, or a controlled
TP5 IDE compilation history. Such inputs can test allocation sequences that
the accepted linked-code-only source does not represent. A claim that an
arbitrary new wrapper/dummy routine solves the historical build is not justified.

Only `tools/progbuild.py`, `tests/test_progbuild.py`, this worker directory and
`build/progbuild/` were written. Canonical sources, recipes, layouts, evidence,
oracles, tool pins and commits were not changed. `measurements.json`, the
per-run receipts/logs, and buffer snapshots preserve the investigation.
