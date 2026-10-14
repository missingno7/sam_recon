from research import *
def read(name):return json.loads((ROOT/name).read_text())
def rule(rid,statement,evidence,probe,status='proven'):
    return {'id':rid,'statement':statement,'evidence':evidence,'probe_path':'build/workers/sol-compiler/'+probe,'status':status}
def run():
    full=[read('full_runtime_results'+('' if ep=='sam1' else '_'+ep)+'.json') for ep in ('sam1','sam2','sam3')]
    catalogue=read('runtime_catalogue.json')
    oracle=(REPO/'build/oracle/sam1/image.bin').read_bytes()
    reloc=read('../../oracle/sam1/relocs.json') if False else json.loads((REPO/'build/oracle/sam1/relocs.json').read_text())['relocs']
    counts={}
    for seg,off in reloc:
        a=seg*16+off
        if a>=3 and oracle[a-3]==0x9a:
            cs=struct.unpack_from('<H',oracle,a)[0]; ip=struct.unpack_from('<H',oracle,a-2)[0]
            if cs in (0x2cd0,0x2960,0x2cc6):
                key='%04x:%04x'%(cs,ip);counts.setdefault(key,[]).append(a-3)
    (ROOT/'oracle_runtime_calls.json').write_text(json.dumps(counts,indent=2))
    rows=[]
    for ep in full:
        for u in ep['runtime']:
            rows.append('| %s | %s | `%04x:0000` | `%04x` | `%04x` | %s | %s |'%(
                ep['episode'],u['unit'],u['oracle_segment'],u['raw_length'],u['padded_length'],u['byte_equal'],u['relocations_equal']))
    inventory=[]
    for x in catalogue['system']:
        key='2cd0:%04x'%x['offset']
        inventory.append('| `%04x` | %s | %d |'%(x['offset'],', '.join(x['features']),len(counts.get(key,[]))))
    rules=[
      rule('compiler.tp50','Use the tested TP 5.0 TPC/TURBO.TPL pair; all three standard-unit segments and their relocation locations match all three episodes exactly.',['full_runtime_results.json','full_runtime_results_sam2.json','full_runtime_results_sam3.json'],'full_runtime_probe.py'),
      rule('compiler.patch','The original TPC patch level is not uniquely identifiable; the tested stock 5.00 library needs no runtime patch.',['Full runtime equality','TPC and TPL SHA-256 in REPORT.md'],'full_runtime_probe.py','limited'),
      rule('compiler.tp55_rejected','Stock TP 5.5 is falsified by whole MemAvail, MaxAvail, Insert and Delete comparisons, including a test compensating its extra two initialized data bytes.',['fair55_results.json','extra_results.json: stock TP55 rejects TP50 TPL with error 72'],'discriminant.py'),
      rule('units.standard','SAM1 System=2cd0, Crt=2960, Dos=2cc6. Their entire padded code segments equal stock TP5.0 output.',['full_runtime_results.json'],'full_runtime_probe.py'),
      rule('units.other','29c2 carries Peder Jungck copyright text and is not Graph; 2642 uses the Genus PCX toolkit identified by initialized DS text. These are third-party units.',['SAM1 image at 29c2:0000 and DS:0000','No Graph unit needed for byte-exact standard runtime'],'full_runtime_probe.py','identified_from_strings'),
      rule('directive.A','A is unconstrained by the reproduced game routines; A+ aligns global words, A- does not.',['directive_results.json: X=0140 vs 013f; Pack and BitBtn match with both'],'directive_probe.py','unknown_game_setting'),
      rule('directive.B','B- is required for the reproduced joystick Pascal code; B+ changes Exists from 56 to 76 bytes.',['extra_results.json: 127 Pascal bytes match only short variant'],'extra_probes.py'),
      rule('directive.D','D cannot be recovered from this EXE: D+ and D- produce identical EXE bytes without /V, while map debug detail changes.',['directive_results.json'],'directive_probe.py','unknown_game_setting'),
      rule('directive.E','E is unconstrained for the observed integer game code; E- leaves this probe EXE unchanged.',['directive_results.json'],'directive_probe.py','unknown_game_setting'),
      rule('directive.F','The game uses both near and far main-program routines. Unit interface routines are far regardless of F; private routines follow F.',['SAM1 e67/ec2 RET vs e33/ef2 RETF','directive_results.json: Frame changes 30 to 31 bytes under F+'],'directive_probe.py','mixed_or_explicit_declarations'),
      rule('directive.I','I- fits observed game I/O: no game far call to System:020e, and enabling I adds a check after each I/O operation.',['oracle_runtime_calls.json','directive_results.json: Io 27 vs 37 bytes'],'directive_probe.py'),
      rule('directive.L','L cannot be recovered from this EXE: L+ and L- produce identical EXE bytes without /V.',['directive_results.json'],'directive_probe.py','unknown_game_setting'),
      rule('directive.N','N is unconstrained where no floating operation is linked; N+ leaves the integer probe identical. SAM links no real-arithmetic runtime group.',['directive_results.json','runtime_catalogue.json: realadd enlarges System'],'directive_probe.py','unknown_game_setting'),
      rule('directive.O','No overlay machinery is needed to reproduce SAM; O+ alone does not change an ordinary EXE, so the permission flag is not recoverable.',['directive_results.json','full_runtime_results.json'],'directive_probe.py','unknown_game_setting'),
      rule('directive.R','R- is required by the complete Pack and BitBtn matches; R+ adds checks and changes their lengths.',['directive_results.json: Pack 37 vs 46; BitBtn 32 vs 42'],'directive_probe.py'),
      rule('directive.S','S- is required by ordinary matched game routines; S+ adds stack-check calls. An interrupt prologue alone does not establish S.',['directive_results.json: Pack 37 vs 45; BitBtn 32 vs 40','full_runtime_results.json: interrupt prefix 19 bytes'],'directive_probe.py'),
      rule('directive.V','V is not identifiable for valid same-capacity calls. V+ rejects string[20] passed to var string; V- accepts it.',['extra_results.json: compatibility','directive_results.json: valid calls identical'],'extra_probes.py','unknown_game_setting'),
      rule('directive.M','Canonical effective memory settings are M 16384,0,655360; allocation is rounded to paragraphs, so the exact source literal for heapmax is not unique.',['extra_results.json: memory','All episode SS/SP/minalloc/maxalloc match'],'extra_probes.py'),
      rule('layout.unit_order','EXE code order is program then reverse unit initialization order; initialization follows dependency-first uses traversal, with shared dependencies initialized once.',['layout_ab/ba/dep facts and MAP files'],'layout_probe.py'),
      rule('layout.body_order','Retained Pascal routine bodies follow definition order, not interface declaration order; forwards permit moving helper bodies after a target.',['extra_results.json: forward','layout_ab/UA.asm'],'extra_probes.py'),
      rule('layout.smartlink','Unused Pascal routines and their literals/typed constants are dropped. Linked runtime groups can retain unused entrypoints together.',['layout_ab vs live facts','runtime_catalogue.json: extra functions fit unchanged System'],'layout_probe.py'),
      rule('layout.init','Pascal unit init follows retained Pascal bodies, but linked external object code can follow init.',['extra_results.json: init=0078, Help=007f, Axis=00cc'],'extra_probes.py'),
      rule('layout.literal','A routine string literal is emitted in CS immediately before its body; literal bytes may make the first public offset nonzero.',['layout_ab/UB.asm: beta at 0000, BFirst at 0005'],'layout_probe.py'),
      rule('layout.typed_constant','Retained typed constants, including routine-local typed constants, occupy initialized DS, not CS. Unused typed constants can disappear.',['layout_live data starts bbbb dddd 7700 9999 1111','layout_ab System base=4 vs live=10'],'layout_probe.py'),
      rule('layout.DS','Initialized DS blocks precede uninitialized DS blocks. Both follow program then linked unit order; System initialized globals are last in the initialized area, not first in DS.',['full_runtime_results.json: initialized base 0258; BSS starts0294','layout_live facts'],'full_runtime_probe.py'),
      rule('layout.DS_episode','System initialized global base is 0258 in SAM1 and 0266 in SAM2/3; reserve 600 vs 614 preceding initialized bytes.',['full_runtime_results*.json'],'full_runtime_probe.py'),
      rule('layout.BSS_group','A unit BSS block is omitted if nothing references it; referencing one variable retains other variables in that block.',['G9 Extra must be referenced for the 164-byte block','layout_ab unused AB/BB remain with used AW/BW'],'full_runtime_probe.py'),
      rule('calls.interface_far','Interface routines return RETF and cross-unit calls use 9A; same-unit calls to far routines use PUSH CS; CALL near.',['layout_ab/UA.asm: AFirst to ALast','extra_results.json: Exists to Axis'],'layout_probe.py'),
      rule('calls.private_near','Private routines default to near under F-; F+ changes their return and adds PUSH CS at same-unit calls.',['directive_results.json','tp50/dir_base and dir_f_plus UPROBE.asm'],'directive_probe.py'),
      rule('harness.map','TPC /GD provides public starts and source line addresses, but no general exact routine-end table; private routines may only have line entries.',['tp50/layout_ab/LAYOUT.MAP','tp50/forward/FWDTEST.MAP'],'layout_probe.py'),
      rule('harness.sentinel','For an exact target interval, define target first, immediately follow its body with a used empty public Sentinel, and put forward helper bodies later. Account separately for target literals before its public entry.',['extra_results.json: Target0000 Sentinel000a helper0011 init0019'],'extra_probes.py'),
      rule('harness.cfg','Do not use next RET or next public as a universal extent rule: early returns, shared tails, private helpers, and literals can cross those boundaries. Use a sentinel construction or validated CFG plus literal/table ownership.',['runtime_matches.json: error tails have min offset before root','layout_ab/UA.asm'],'runtime_probe.py'),
    ]
    (ROOT/'rules.json').write_text(json.dumps(rules,indent=2))
    report='''# sol-compiler report

Research completed 2026-10-14. All probe sources, compiler scratch copies, EXEs, maps, disassemblies, and results are in this worker directory. The oracle and repository tools are read as inputs.

## Verdict and strongest evidence

Use **Turbo Pascal 5.0**, specifically the locally supplied 5.00 toolchain. This conclusion no longer rests on chunk counts: a Pascal probe reproduces **the entire Dos, Crt, and System code segments, including paragraph padding and relocation locations, in all three episodes**. That is 6,240 compared bytes per episode. Its SS, SP, minalloc, and maxalloc also equal the oracle values.

The probe implements ordinary Pascal runtime idioms, reserves initialized/BSS space, and uses NOP-filled game-unit stand-ins to obtain the original segment coordinates. It does not copy oracle runtime bytes into the probe. Original coordinates are measured, then stock TPC/TURBO.TPL generate the matching bytes. Game stand-ins and their init bodies are not intended to match game code. MZ header size, relocation count for the whole game, entry IP, and game-segment contents are therefore intentionally different.

| Episode | Unit | Original segment | Actual code bytes (hex) | Padded bytes (hex) | Raw equality | Relocation equality |
|---|---|---|---|---|---|---|
'''+ '\n'.join(rows)+'''

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
'''+ '\n'.join(inventory)+'''

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

From `D:\\Prog\\sam_recon`:

```text
python build/workers/sol-compiler/run_all.py
python build/workers/sol-compiler/write_report.py
```

`run_all.log` records the completed suite. Compilers execute through `C:/tools/nmlgcdos/msdos.exe` via Python subprocess in owned scratch directories; no shell slash conversion is involved. Only TPC/TURBO.TPL (and BINOBJ for the external probe) are copied from installed toolchains. Python bytecode writing is disabled before importing repository/vendored helpers. The oracle images must already exist; this suite does not run oracle materialization outside the worker directory.

Remaining uncertainty is limited to source directives with no distinguishing emitted behavior and the original compiler patch identifier. The matching standard runtime, effective memory layout, concrete game idioms, call rules, and harness convention are established by the retained probes.
'''
    (ROOT/'REPORT.md').write_text(report)
    assert len(rules)==len({x['id']for x in rules})
    assert '2cd0:020e' not in counts
    print('Wrote REPORT.md and',len(rules),'machine-readable rules.')
if __name__=='__main__':run()
