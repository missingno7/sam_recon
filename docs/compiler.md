# Compiler identification: Turbo Pascal 5.0

> Research report written during the matching phase. The probes, tools and evidence it cites
> (`probes/`, `tools/`, `evidence/` that no longer exist) are preserved in the git tag
> `matching-archive`; `build/workers/...` paths were uncommitted worker scratch (they hold bytes
> derived from the originals) and are reproduced by rerunning those probes. Identifiers are the
> coordinate names of that phase (see docs/names.json for the mapping to the names used in game/).

Research completed 2026-10-14. All probe sources, compiler scratch copies, EXEs, maps, disassemblies, and results are in this worker directory. The oracle and repository tools are read as inputs.

## Verdict and strongest evidence

Use **Turbo Pascal 5.0**, specifically the locally supplied 5.00 toolchain. This conclusion no longer rests on chunk counts: a Pascal probe reproduces **the entire Dos, Crt, and System code segments, including paragraph padding and relocation locations, in all three episodes**. That is 6,240 compared bytes per episode. Its SS, SP, minalloc, and maxalloc also equal the oracle values.

The probe implements ordinary Pascal runtime idioms, reserves initialized/BSS space, and uses NOP-filled game-unit stand-ins to obtain the original segment coordinates. It does not copy oracle runtime bytes into the probe. Original coordinates are measured, then stock TPC/TURBO.TPL generate the matching bytes. Game stand-ins and their init bodies are not intended to match game code. MZ header size, relocation count for the whole game, entry IP, and game-segment contents are therefore intentionally different.

| Episode | Unit | Original segment | Actual code bytes (hex) | Padded bytes (hex) | Raw equality | Relocation equality |
|---|---|---|---|---|---|---|
| sam1 | DOS | `2cc6:0000` | `0097` | `00a0` | True | True |
| sam1 | CRT | `2960:0000` | `0613` | `0620` | True | True |
| sam1 | SYSTEM | `2cd0:0000` | `1191` | `11a0` | True | True |
| sam2 | DOS | `2d04:0000` | `0097` | `00a0` | True | True |
| sam2 | CRT | `299e:0000` | `0613` | `0620` | True | True |
| sam2 | SYSTEM | `2d0e:0000` | `1191` | `11a0` | True | True |
| sam3 | DOS | `2d07:0000` | `0097` | `00a0` | True | True |
| sam3 | CRT | `29a1:0000` | `0613` | `0620` | True | True |
| sam3 | SYSTEM | `2d11:0000` | `1191` | `11a0` | True | True |

Evidence: `full_runtime_results.json`, `full_runtime_results_sam2.json`, `full_runtime_results_sam3.json`. Re-run `python build/workers/sol-compiler/full_runtime_probe.py`; it asserts all nine matches and memory-header matches.

Tested toolchain fingerprints:

- TPC.EXE SHA-256: `095e26ddb83386eb8d90509faf1e9a3d63a2f81fffb43fb2ff7968b228936c34`.
- TURBO.TPL SHA-256: `b3b699c6736c00b4075f8fc39871a9eab5a8b933b1696dff3e1572cf7ca3b5ae`.
- TPC identifies itself as Version 5.0, copyright 1983,88.

**5.5 discrimination:** complete MemAvail (68 bytes), MaxAvail (77), Insert (84), and Delete (86) match 5.0 and fail 5.5. `discriminant.py` compensates 5.5's extra two initialized data bytes; Mark and Release then match, but those four discriminants still fail. Stock 5.5 also rejects the 5.0 TPL with Error 72, unit file format error (`extra_results.json`). TP4/6/7 are available for comparison, but their shared routines are weaker evidence than the complete 5.0 segment reproduction.

**Patch level:** no patch to this stock 5.00 runtime is needed. Exact original TPC patch level cannot be established from runtime equality if a compiler patch retained the same library and generated these same idioms. This report does not invent a 5.0 patch identifier. A deliberately converted/custom later compiler library is outside what stock-toolchain comparisons can logically exclude.

## Standard units and runtime inventory

SAM1's standard segments are System `2cd0`, Crt `2960`, and Dos `2cc6`. Their unpadded lengths are `1191`, `0613`, and `0097`. Crt init is `0000`; Dos has no init entry. `29c2` is not Borland Graph: its leading strings identify Peder Jungck, copyright 1991. Initialized DS starts with Genus Microprogramming PCX Programmer's Toolkit 3.56 identification; the `2642` unit is consistent with that third-party toolkit. These identifications from strings are weaker than the standard-unit byte proofs.

Dos links MsDos `0000`, Intr `000b` (including its interrupt-return callback), GetIntVec `006c`, and SetIntVec `0084`. It does not contain the broad date/time, file-search, Exec, environment, or disk-space functions linked by the rich probe.

Crt links its complete standard implementation: init and private screen/console handlers, TextMode `016d`, Window `0182`, ClrScr `01c2`, ClrEol `01dc`, InsLine `01f0`, DelLine `01f5`, GotoXY `0215`, WhereX `0241`, WhereY `024d`, TextColor `0259`, TextBackground `0273`, LowVideo `028b`, HighVideo `0291`, NormVideo `0297`, Delay `029e`, Sound `02c6`, NoSound `02f3`, KeyPressed `02fa`, ReadKey `030c`, AssignCrt `032e`. These are linked entrypoints; not all are called directly by game code.

System contains the core startup/exit/error handlers; IOResult/check/range/stack-check block; generic aggregate copy `025d`; long arithmetic; heap manager; strings; sets; random; integer conversion; text control and character backend; text string I/O; typed/untyped file control and block I/O; Move and FillChar. A runtime group retains multiple entries together. Therefore the presence of the range/stack/I/O check routines does **not** establish enabled checks in game code.

The table maps compiler builtin idioms to SAM1 System offsets. Names such as strcopy describe compiler helpers, not original public symbol spellings. Direct-call counts are relocation-backed game/library far calls; zero means linked but no such direct call. Near internal calls are not counted. `runtime_catalogue.json` records each probing call and its CFG information; `oracle_runtime_calls.json` records caller addresses.

| System offset | Probe idiom(s) | Direct far calls |
|---|---|---|
| `00d1` | runerror | 0 |
| `00d8` | halt | 2 |
| `0207` | ioresult | 7 |
| `0279` | longmul | 4 |
| `0294` | longdiv, longmod | 0 |
| `0329` | getmem | 25 |
| `0364` | freemem | 3 |
| `0384` | mark | 0 |
| `039a` | release | 0 |
| `03b5` | memavail | 1 |
| `03f9` | maxavail | 0 |
| `0634` | concat | 11 |
| `064e` | strcopy, concat, copy, stringchar | 695 |
| `0680` | copy | 5 |
| `06c1` | concat | 17 |
| `06ed` | pos | 4 |
| `0724` | stringcmp | 330 |
| `074f` | stringchar | 17 |
| `077c` | insert | 0 |
| `07d0` | delete | 2 |
| `0826` | setunion, setinter, setdiff | 0 |
| `08b4` | setunion, setinter, setdiff | 0 |
| `08d4` | setin | 6 |
| `08f5` | setunion | 0 |
| `0911` | setdiff | 0 |
| `092f` | setinter | 0 |
| `094b` | seteq | 0 |
| `0980` | random | 47 |
| `0a07` | randomize | 0 |
| `0b26` | strlong, strint | 4 |
| `0b71` | vallong, valint | 3 |
| `0ba2` | assigntext | 0 |
| `0c12` | resettext | 1 |
| `0c17` | rewritetext | 1 |
| `0c1c` | appendtext | 0 |
| `0c67` | flush | 0 |
| `0c6b` | closetext | 0 |
| `0ec5` | readln | 0 |
| `0eee` | writeln | 3 |
| `0f0d` | writestr, readstr | 0 |
| `0f33` | readstr | 0 |
| `0f6b` | writestr | 3 |
| `0fa9` | assignfile | 11 |
| `0fd7` | resetfile | 11 |
| `0fe0` | rewritefile | 2 |
| `103c` | truncate | 0 |
| `1058` | closefile | 11 |
| `108c` | readtyped | 31 |
| `1093` | writetyped | 2 |
| `10c2` | blockread, blockread3 | 0 |
| `10c9` | blockwrite, blockwrite3 | 0 |
| `112a` | seek | 0 |
| `115a` | move | 0 |
| `117d` | fillchar | 1 |

The catalogue tests show **absent** groups: Eof/Eoln/SeekEof/SeekEoln add `0046` bytes; FilePos/FileSize add `008c`; text integer writing adds `00a1`; Erase/Rename add `0066`; ParamStr/ParamCount add `0088`; GetDir adds `00e6`; real arithmetic adds `0314`. No such extra groups are needed for SAM. Typed-file Read/Write are `108c`/`1093`; BlockRead/BlockWrite are `10c2`/`10c9`. Do not confuse those two pairs.

Re-run `python build/workers/sol-compiler/catalogue_probe.py` after `system_recipe.py`. Individual `tp50/catalogue_*/CAT.PAS`, `.MAP`, and `.EXE` are retained. The catalogue permits only the known address-fixup differences while checking an unchanged library selection; the independent full-layout probe supplies the raw-byte proof.

## Compiler directives: proven settings versus unconstrained flags

Flags can vary by unit, procedure, or source region. A single global directive vector is not fully recoverable from an EXE, and ordinary valid code does not expose some flags.

| Flag | Finding and falsification probe |
|---|---|
| A | Unproven for game code. A+ global `pad:byte; x,y:integer` gives X=`0140`, Y=`0142`; A- gives `013f`, `0141`. Matched Pack/BitBtn bytes permit both. Use A+ as a tested default, not a recovered fact. |
| B | B- proven for joystick Pascal code. The first `007f` bytes of original `286e` match: Exists, both buttons, and empty init. B+ increases Exists 56 to 76 bytes and breaks equality. |
| D | Unconstrained. D- and D+ give identical EXE bytes without `/V`; D changes line/debug information used by maps/TPUs. |
| E | Unconstrained where no floating arithmetic is generated. E- leaves the integer probe unchanged. |
| F | Mixed near/far behavior. Main `0e67` and `0ec2` return near; `0e33` and `0ef2` return far. Unit interfaces are far even under F-. F+ changes a private helper call from CALL to PUSH CS/CALL and RET to RETF. Source may use scoped directives or explicit declarations. |
| I | I- fits observed game I/O. No relocation-backed far call to System `020e` occurs. Probe Io is 27 bytes under I-, 37 under I+, with two added check calls. Original config-file and startup output sequences lack them. |
| L | Unconstrained. L- and L+ give identical EXE bytes without `/V`; it controls debug symbols rather than these instruction bytes. |
| N | Unconstrained for observed integer code. N+ leaves that probe unchanged; no real arithmetic group occurs in SAM. Absence of floating operations does not prove N-. |
| O | No overlay manager/link behavior is needed. O+ alone leaves this ordinary probe identical, so permission to overlay cannot be inferred. |
| R | R- proven for matched routines: Pack is exactly 37 bytes, BitBtn 32. R+ produces 46 and 42 bytes and fails both matches. |
| S | S- proven for ordinary matched routines. S+ makes Pack 45 bytes, BitBtn 40, adding stack-check calls. Interrupt prologues suppress that check and cannot alone decide S. |
| V | Unconstrained for valid same-capacity calls. V+ rejects `string[20]` passed to `var string`; V- accepts it. Valid-call EXEs are identical. |
| M | Canonical effective settings: `{$M 16384,0,655360}`. SP=`4000`; required allocation ends exactly at SS:SP, so effective heap minimum is zero; maxalloc-minalloc=`a000` paragraphs gives 655360 maximum heap bytes. Paragraph rounding means exact original source literals need not be unique. |

The complete 37-byte `Pack(lo,hi:byte):byte` routine matches original `25e5:0000`; source is in `tp50/dir_base/UPROBE.PAS`. The 32-byte Boolean port expression matches `286e:0038`. The full-layout probe's interrupt procedure reproduces original bytes `0000:0000..0012` (19 bytes), including save order, BP frame, four local bytes, and DS load. `full_runtime_results.json` records the exact prefix.

Compiler frames use `55 89 e5`, and zero assignments often use `31 c0`; System's hand-written assembly frequently uses `8b ec` and `33 c0`. A `cmp ax,0` in the toolkit's assembly-looking `2642:000f` code is not enough to deduce a compiler flag. These encodings are instruction-selection/context or assembler differences, not independent directive switches. The frame probe shows `cmp word ptr [bp-2],0` for a local integer comparison.

Memory counterfactuals: stack 8192 changes SP and minalloc; heap minimum 4096 adds 256 paragraphs; maximum 327680 halves the maxalloc-minalloc delta. A maximum literal 655359 still rounds to the same effective maximum. Evidence: `extra_results.json`. Re-run `directive_probe.py` and `extra_probes.py`.

## Layout rules for reconstruction

1. **Code order:** `uses Ua,Ub` emits Program, Ub, Ua, System; swapped uses swaps their segments. With both importing Uc, code is Program, Ub, Ua, Uc, System, while init calls System, Uc, Ua, Ub. Shared dependencies initialize once. The general tested rule is reverse initialization/dependency order, with program first.
2. **Body order and smart linking:** bodies follow definitions, not interface declaration order. Ua declares AFirst before ALast but defines ALast first; ALast precedes AFirst in output. Unused program/private/interface routines disappear. Forward declarations reserve no code position.
3. **Init placement:** Pascal init follows retained Pascal bodies. External objects follow it. Joystick probe has Exists=`0000`, Btn1=`0038`, Btn2=`0058`, init=`0078`, external Help=`007f`, external Axis=`00cc`. The external bytes are simple synthetic NOP/RET stubs, not copied original assembly.
4. **String literals:** routine-owned Pascal short strings occur in CS immediately before their routine body. Ub has `04 beta` at `0000`, BFirst at `0005`; Ua's `alpha` is between preceding body and AFirst. Unused routine literals disappear. Thus a target first in its unit can still have a nonzero public start.
5. **Typed constants:** retained ordinary and local typed constants are initialized DS objects. Live probe starts `bbbb dddd 7700 9999 1111`: program PC/TC, Ub BC/LC, Ua AC, then System initialized globals. A+ inserted alignment after the byte. Unused PC/AC/BC disappear in the other probe, making System base `0004`, versus `000a` when live.
6. **DS ordering:** initialized objects are collected first across linked units; uninitialized variable blocks follow in the same program/unit order. System's initialized globals therefore follow other units' constants even though System initializes first. SAM1 has 600 preceding initialized bytes (`0258`), then the 60-byte System initialized block, then BSS from `0294`. SAM2/3 have 614 preceding bytes (`0266`). System Input/Output/save vectors are much later in BSS. The oracle's `02a0` materialized DS bytes are rounded initialized data, not the full DATA segment.
7. **BSS linking:** merely declaring a unit variable does not retain a wholly unused BSS block. The full probe must reference G9.Extra to retain its 164-byte block. When a block is linked, other unused variables in it remain (AB with AW, BB with BW). Preserve unit/data-group boundaries, not just a flattened used-variable list.
8. **Calls:** interface procedures are far independent of F. Cross-unit calls use `9a`; intra-unit far calls use `0e e8` (PUSH CS/CALL near). Private helpers under F- use ordinary E8/RET. External object authors can emit a genuine far call even within the same segment; original RTC assembly does so.
9. **Paragraphs:** unit code, DATA, and STACK starts are paragraph-aligned. System's `1191` bytes occupy `11a0`; Crt `0613` occupies `0620`; Dos `0097` occupies `00a0`. Runtime padding bytes match as well as routines.

Evidence/re-run: `layout_probe.py` (ab, ba, live, dep), `extra_probes.py` (external and forward), and `full_runtime_probe.py` (all episode layouts). Maps and readable disassemblies are next to each EXE.

## Routine extent harness

`TPC PROBE.PAS /B /GD` works on 5.0. `/GD` provides public starts and line addresses, not a universal routine-end table. Unit implementation-private routines may have line addresses without publics; System intrinsic helpers lack useful code publics. D+ is useful for line entries. L+/D+ are harness choices, not recovered game flags. `/V` is unnecessary and changes EXE/debug output.

For an isolated target, export Target and an empty Sentinel. Define Target first, Sentinel immediately next, then bodies of any forward-declared private helpers. Call both from the driver so the linker retains them. The forward probe gives Target=`0000`, Sentinel=`000a`, helper=`0011`, init=`0019`; Target's exact instruction interval is `[0000,000a)`. Helpers remain later, outside that interval. Include target-owned string literals before its public entry separately.

Do not blindly use next public as the end in an arbitrary unit: a private helper or the next routine's preceding literal can intervene. Do not scan to the first RET: early returns and shared tails exist. `runtime_probe.extent` walks direct CFG branches and records min/end; negative ownership cases (GetMem error tail into `00d1`, for example) are explicitly rejected for raw single-interval comparisons. A production harness should use the sentinel convention for probes and explicit CFG/data ownership for arbitrary binaries. The preexisting atlas is not used as a byte-exact extent oracle: several atlas ranges combine neighboring runtime entries.

## Re-run everything

From `D:\Prog\sam_recon`:

```text
python build/workers/sol-compiler/run_all.py
python build/workers/sol-compiler/write_report.py
```

`run_all.log` records the completed suite. Compilers execute through `C:/tools/nmlgcdos/msdos.exe` via Python subprocess in owned scratch directories; no shell slash conversion is involved. Only TPC/TURBO.TPL (and BINOBJ for the external probe) are copied from installed toolchains. Python bytecode writing is disabled before importing repository/vendored helpers. The oracle images must already exist; this suite does not run oracle materialization outside the worker directory.

Remaining uncertainty is limited to source directives with no distinguishing emitted behavior and the original compiler patch identifier. The matching standard runtime, effective memory layout, concrete game idioms, call rules, and harness convention are established by the retained probes.
