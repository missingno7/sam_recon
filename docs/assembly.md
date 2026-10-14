# Assembly objects and libraries

> Research report written during the matching phase. Scripts, probes and worker paths it cites
> (`build/workers/...`, `probes/`, `tools/` that no longer exist) are preserved in the git tag
> `matching-archive`; identifiers are the coordinate names of that phase (see docs/names.json for
> the mapping to the names used in game/).

Date: 2026-10-14. Scope: unpacked SAM1/2/3 oracle images; historical TASM, MASM, and Turbo Pascal binaries; Duke 1's reconstructed toolbox and original DN1 oracle. All offsets below are hexadecimal, relative to the **SAM1 load image segment**. Routine ends are exclusive. Names are behavioral guesses, not recovered source identifiers.

**Verdict:** the executable mixes TP-compiled Pascal, linked assembly libraries, and Borland runtime. ProGraphx is demonstrably version 2.0, with a Pascal initializer followed by a large assembly OBJ contribution in the same unit segment. The machine code supports the MASM-compatible assembler family, including TASM's default mode; **the tested bytes do not distinguish TASM 1.0/1.01/2.0/2.01 from MASM 4.0/5.0/5.1**. It would be unjustified to pin TASM 1.0 from the forward-jump NOP alone.

## Segment classification

| SAM1 segment : length | Classification | Concrete evidence |
|---|---|---|
| `0000:5200` | **Mixed: Pascal main + inline fragments + linked assembly tail** | Nine `55 89 E5` TP frames, System string/file/heap calls and compiler interrupt frames. Main compiled code ends at `514A`; OBJ scratch bytes occupy `514A–5151`; CMOS/clock/PIT assembly occupies `5151–5200`. CLI at `0BF5` and STI at `0E26` are numeric-INLINE-style fragments inside the Pascal timer ISR `0BE5–0E33`. |
| `0520:8730` | **Pascal compiled** | Seventeen `55 89 E5` frames, `89 EC 5D CA nn nn` cleanup, repeated BP locals, pointer/array calculations and System calls. Empty unit init at `8724`; final compiler return at `872A`, then zero alignment. No separate ASM tail found. |
| `0D93:A660` | **Pascal compiled** | Nine TP frames, stack locals, far-pointer calculations, signed loop/branch expansion and System helpers. Init `A658`; no ASM tail. |
| `17F9:DEC0` | **Pascal compiled** | Fifty-three TP frames, large automatic records/string temporaries, System helpers, Pascal call/argument patterns. Hardware access such as `IN AL,60h` is consistent with TP's built-in `Port[]`, rather than sufficient evidence of assembly. Init `DEAF`; no ASM tail. |
| `25E5:05D0` | **Mixed: Pascal text unit + linked assembly** | Nine TP frames through init `048C–04A3`; assembly `04A3–05C7` uses `8B EC`/`8B E5`, string instructions, BIOS adapter detection and synchronized text-VRAM writes. DS state `21D6–21DF`. |
| `2642:22C0` | **Mixed: Pascal init + Genus PCX assembly library** | Init `0000–000F` is TP. Code `000F–22B8` has twenty `55 8B EC` frames, explicit loading/preservation of DS/ES/SI/DI, RLE image decoding, device dispatch and printer paths. **DS:0000 contains `PCX Programmer's Toolkit 3.56`; DS:0020 contains the Genus 1988–89 copyright; DS:006A names Christopher A. Howard.** This is neither Borland Graph nor ProGraphx. |
| `286E:0100` | **Mixed: Pascal joystick wrappers + linked assembly** | TP frames at `0000`, `0038`, `0058`, empty init `0078`. Assembly `007F–00FB` times game port `201h`, with CLI/STI and LOOPNE. |
| `287E:0120` | **Pascal compiled** | Two TP frames, System-independent compiled comparisons and array/pointer calculations; no `8B EC` ASM frame or ASM tail. Init `0116`. |
| `2890:0D00` | **Mixed: Pascal game-data unit + linked asset decoder** | Four TP frames and Pascal high-score strings/state initialization through init `0C0D–0C14`. ASM `0C14–0CFC` reverses bits and XORs a cyclic key, with an `8B EC` frame and hand-built stack key. |
| `2960:0620` | **Borland Crt runtime** | Pascal init `0000–0030`; BIOS/text/speaker/keyboard runtime assembly thereafter. Eleven exact 32-byte-or-longer runs totaling 722 non-overlapping sampled bytes match TP5 `TURBO.TPL`; APIs include TextMode `016D`, ClrScr `01C2`, Delay `029E`, Sound `02C6`, NoSound `02F3`, KeyPressed `02FA`, ReadKey `030C`. |
| `29C2:3040` | **Mixed: Pascal init + ProGraphx 2.0 linked assembly** | Four ordinary Pascal string constants at `0000–0070`; TP init `0070–00E6`; ASM OBJ data/code `00E6–303A`. Sixty-one `55 8B EC` frames plus frame-free helpers. Banner at `0137`, version at `0153`, Jungck copyright at `0171`. No TP/System calls occur in the toolbox assembly body. |
| `2CC6:00A0` | **Borland Dos runtime** | `MsDos` `0000`, `Intr` `000B`, GetIntVec `006C`, SetIntVec `0084`; BIOS/DOS register marshaling. Two sampled exact runs cover 150 of the 151 meaningful bytes in TP5's shipped runtime. |
| `2CD0:11A0` | **Borland System runtime** | Startup, heap/error handling, string/set/file/text operations. Twenty-nine sampled exact runs total 3003 bytes, longest 864, in TP5 `TURBO.TPL`. Register conventions and handwritten assembly are runtime implementation, not user Pascal codegen. |

The cited “607 relocations” for `29C2` means **607 relocation words target that segment**. Only **four MZ relocation sites are located inside it**, all in the Pascal initializer's far System calls. Its CS offsets are link-time offset fixups, not MZ segment relocation words. `census.json`, `calls.json`, `codegen_census.json` and `runtime_matches.json` retain the underlying measurements. Sampled runtime matching is identity evidence, not a complete reconstruction of every runtime routine.

The Genus attribution is independently consistent with its contemporary product announcement, which describes assembly routines and directly linked Turbo Pascal interfaces. [Genus announcement, Dr. Dobb's July 1988](https://jacobfilipp.com/DrDobbs/articles/DDJ/1988/8807/8807l/8807l.htm).

## Calling conventions and data

Normal TP far entries have return IP/CS at `[BP+2]`/`[BP+4]`, the **last Pascal argument at `[BP+6]`**, preceding arguments at increasing offsets, and `RETF n` callee cleanup. A far pointer occupies two words. Pascal pushes arguments left to right, so for the fixed sprite routines the bitmap far pointer is `[BP+0A]`, x is `[BP+8]`, y is `[BP+6]`; `RETF 8` consumes all four words. Local calls to far routines often use TP's `PUSH CS; CALL near` optimization. Genuine near helpers use `RET` and registers or the caller's BP frame.

Important exceptions:

- **`29C2:26E9` is the real string-renderer entry**, one byte before its apparent BP prologue at `26EA`. It pushes DS before BP, so the stack arguments start at **BP+8**, with y at +8, x at +A, string pointer at +C/+E. Its `E8 0000; POP AX` calculates its own address; `26F5` is not another function.
- PCX decode handlers `0F9B`, `10D7`, `12B6`, `137A`, `14A7`, `15D1`, `16F5` are **far-jump continuations** of `0D2D`; they inherit its BP/local/register frame. They are not ordinary independent Pascal procedure entries.
- The clock/PIT routines in main use **far register conventions**, without BP frames or stack arguments; CMOS input is AL and the decoded value is returned in AL.
- `286E:00A9` is called with near `E8`, yet ends `CB` (RETF). The four-axis entry `007F` is unreferenced in the observed game; the inconsistency is retained and not silently “fixed.”
- `29C2:2F7B` and `2FD7` actively return with **plain CB**, followed by unreachable `CA 08 00` / `CA 0C 00`. They therefore behave as caller-cleanup entries, despite appended Pascal cleanup instructions. Neither has an observed game call. This looks like an incomplete adaptation of unused C-style routines, but that explanation is an inference.
- PCX entry `2642:1915` begins with **INT3**; its BP prologue is at `1916`. Existing callers target `1915`, so the leading byte must be preserved.
- Unused entry `29C2:2BB2` branches backward into earlier masked/clipped code at `1F7F` and `1FF9`; its `external_code_ranges` field preserves those blocks outside the entry span.

ProGraphx keeps mutable library state in **CS**, allowing DS to address bitmap memory or video memory:

| CS offsets | Use |
|---|---|
| `00E6–0100` | Text-renderer coordinates, font row/source pointers, counters, masks; largely uninitialized OBJ storage. |
| `0100–0108`, `0108–0110` | Left-edge masks `FF 7F 3F 1F 0F 07 03 01` and pixel masks `80 40 20 10 08 04 02 01`. |
| `0110–011C` | Width/height/transfer state used by bitmap capture/restore. |
| `011C–011E` | Screen stride in bytes, initially 40 (`28h`), updated at `01D3`; many address calculations use `MUL word ptr CS:[011C]`. |
| `0192`, `0194`, `0196` | Draw-page index, color/plane mask, EGA drawing operation state. |
| `0197–01A3` | Clipping rectangle bounds. |
| `059F`, `07EC` | Rectangle height/count scratch words. |
| `09C6–09CE` | Line-drawing increments/error/major-axis state. |
| `12F2–12FC`, `1586–1590` | Circle/curve work variables. |
| `18C2–18CA`, `1B22–1B27`, `1E7F–1E87` | Shifted/variable/clipped sprite work state. |
| `26CF–26E9` | Selected/ROM font pointers, glyph heights and text direction. |

Genus uses DS instead: video state begins at `21E0`, work-buffer fields near `2A8A`, per-display records at `2EA2` with stride `38h`, printer state near `338A`, initialized printer command strings near `3396`, and a decimal divisor table at `33F3`. Text ASM uses DS `21D6` (video segment), `21D8` (adapter synchronization flag), `21DE/21DF` (mode/adapter detection). The asset decoder uses a caller-provided far buffer and length, plus stack locals; its cyclic key is the 27-character copyright text followed by NUL. Decoding is **bit reversal followed by XOR**, not an assertion that the same transform is its own inverse.

## Assembler and TP probes

`probe.py` assembled the same ordinary 8086 source under all seven requested tools through `C:/tools/nmlgcdos/msdos.exe`, with each tool's output, OBJ and listing retained in `probes/<tool>/`. All seven succeeded and emitted **identical LEDATA bytes**. In particular the complete 34-byte SetMode routine matches SAM `29C2:01A3–01C5`:

```text
55 8b ec 8b 46 06 3c 00 75 05 b0 0d eb 0e 90
3c 01 74 07 32 e4 b0 12 eb 03 90 b0 10 cd 10 5d ca 02 00
```

| Source operation | All tested TASM/MASM defaults | TP5 compiled / TP6 built-in ASM |
|---|---|---|
| `mov bp,sp` | `8B EC` | `89 E5` |
| `mov sp,bp` | `8B E5` | `89 EC` |
| `mov ax,bx` | `8B C3` | `89 D8` in TP6 ASM |
| `xor ax,ax` | `33 C0` | `31 C0` |
| `xor ah,ah` | `32 E4` | `30 E4` |
| Unqualified short-range forward `jmp` | Short JMP plus a retained one-byte NOP slot | TP6 ASM selects short size directly |

SAM's `29C2:0401` = image `2A021` is **`EB 03 90`**, and many other toolbox/text/joystick forward jumps have the same reserved-slot pattern. Both MASM and default TASM reproduce this. A separate **TASM 2.0 `/m2`** probe removes the extra slots and emits a 32-byte SetMode body; the default 34-byte body is therefore incompatible with *that source under that optimizing mode*. Explicit SHORT/NOP source could preserve the old bytes even under a newer assembler. No version-exclusive encoding was found, and no original OBJ producer comment survives in the linked EXE.

The TP6 built-in ASM probe emits the compiler's direction-bit choices above; TP5 rejects `assembler;` with Error 36. TP5 numeric `Inline(...)` accepts arbitrary bytes and cannot be categorically excluded from machine code alone. **OBJ linkage is the strong structural explanation**, not a mathematical proof against a programmer manually entering every byte.

`tp_exact_layout.py` makes the placement concrete with TP 5.0:

1. Four ordinary Pascal constants, each a 27-character string, occupy code offsets `0000`, `001C`, `0038`, `0054`.
2. A far-mode Pascal initializer begins at **`0070`**. Its calls and four `string[80]` assignments produce the same **118-byte initializer shape ending at `00E6`**, including `BF string_offset; PUSH CS; PUSH DI` and the System bounded-string-assignment call.
3. An ASM OBJ with `BDh` reserved bytes is appended at **`00E6`**. Its SetMode entry is therefore **`01A3`**, precisely the SAM offset. The directive's textual location in the Pascal implementation does not interleave OBJ code with Pascal routines.
4. `CODE SEGMENT BYTE PUBLIC` without a class succeeded. Adding a `'CODE'` class caused Error 51 in the tested TP5 OBJ layout; the successful TP source/object recipe and failed variants are retained.
5. Reserved `DB ?` bytes in the probe were **not zero-filled**: 92 of the 189 bytes in the linked reserved area were nonzero. Thus SAM1/2's Pascal-looking text and old bytes inside toolbox scratch storage, versus SAM3 zeros, are consistent with uninitialized OBJ holes populated from the linker's buffer. They are not evidence of extra instructions.

The interrupt probe confirms TP5 itself supplies the register-save/restore and IRET frame, but not the CLI/STI pair in the main timer ISR. The `Port[201h]` probe confirms that direct IN instructions can be ordinary Pascal codegen. Receipts and actual binaries are retained under `probes/tp_codegen/`, `probes/tp_layout2/`, and `probes/tp_exact_layout/`.

## Relationship to Duke 1

Comparison used both `D:/Prog/duke1_recon/src/TOOLBOX.ASM` and the DN1 oracle. The reconstructed source was assembled separately inside this worker directory to recover its offsets; `duke_publics.json` and `duke_toolbox_disasm.txt` record the correspondence. The historical `reconstruction-complete:src/asm/toolbox.asm` was read with a per-command git safe-directory override; no git configuration was changed.

| DN1 image routine | SAM1 routine | Relationship / changes |
|---|---|---|
| `0258` SetMode | `29C2:01A3` | Same 0/1/other mapping to BIOS modes 0Dh/10h/12h, same forward-jump padding. DN ends CB; SAM ends CA 02 00. |
| `0278` BIOS mode | `01C5` | Same BIOS AH=0 wrapper; Pascal cleanup added. |
| `0285` border color | `0337` | Same INT 10h AX=1001h logic and BH=BL. |
| `0294` reset mode | `0349` | Same get-current-mode then reset-current-mode sequence. |
| `029D` palette register | `0352` | Same AX=1000h API. DN reads BL/BH from BP+6/+8; SAM reverses these offsets for Pascal argument order and returns with cleanup 4. |
| `0424` masked 16×16 tile | `0475` | Same mask-plus-four-color-plane packets, mask register 8 at 3CEh and plane selects 1/2/4/8 at 3C5h, `LODSB`/VRAM `XCHG`. SAM uses a CS stride multiplication instead of DN's hard-coded ×40 shifts and consumes pointer/x/y in Pascal order. SAM `0372` expands this family to 32×16. |
| `04C5` masked 8×8 glyph | `051F` | Same eight-row single-packet version and graphics-register reset sequence; stride and calling-convention changes as above. |
| `053C` opaque 8×8 path | `2B38` | Both skip the mask byte and write the four planes. SAM also provides opaque 16×16 (`2A9F`), 32×16 (`29C3`) and shifted/clipped variants. |
| `05B0` split/retrace helper | `029F` | Same BDA video-port lookup and retrace polling, CRTC register 18h/07h line-compare update. SAM preserves fewer registers and uses AH=11h where DN uses 1Fh. |
| `05EB` draw-page selector | `0633` | Same shared CS draw-page variable, with moved offset and Pascal cleanup. |
| `05F7` show page | `07C6` | Same BIOS AH=5 wrapper; Pascal cleanup added. |
| `02AD`, `0315` latch/video-region copies | `2E6D`, `2ECF`, `2F32`, `2F7B`, `2FD7` | Related video-to-video/latch-copy algorithm family, not byte-identical implementations: DN uses fixed 40-byte rows and A400h source storage/unrolling; SAM uses stride-based addresses, A000:FA00 cache addressing and write-mode-1 copies. |

**CS-resident data is shared lineage, not a SAM-only change.** DN already keeps the draw-page word at image `0247` and the same mask tables at `01E3`/`01EB`. SAM expands that state substantially with stride, clipping, text, curve and sprite scratch tables. The packet algorithms and banners are much stronger lineage evidence than the small amount of long literal byte sharing. SAM adds substantial graphics/text functionality absent from Duke's small linked subset; there is no basis to treat the entire 12 KB toolbox as Duke-specific code.

## SAM2 / SAM3 identity

| SAM1 segment | SAM2 | SAM3 | Result |
|---|---|---|---|
| Main ASM entries `5151…` | entries `51D3…` | entries `51D3…` | Same code after **+82h** OBJ placement shift and CS/call-offset fixups; CMOS and PIT routines are otherwise raw-identical. Segment-paragraph alignment changes by 90h, so using that as the OBJ offset shift would be wrong. |
| `25E5` | `2623` | `2626` | Six ASM routines match after DS variable offset fixups of +26h. |
| `2642` | `2680` | `2683` | Thirty ASM routines/continuations match after segment relocations, DS variable offsets +26h, and initialized-constant address offsets +0Eh. |
| `286E` | `28AC` | `28AF` | Entire 100h-byte segment is raw byte-identical. |
| `2890` | `28CE` | `28D1` | Decoder `0C14–0CFC` is raw byte-identical; Pascal portion has linked DS offsets. |
| `29C2` | `2A00` | `2A03` | **All 11,848 code bytes** in `01A3–303A`, excluding nine documented embedded data ranges, are raw byte-identical, including NOP padding and unreachable RETF n. Entire segments are **not** identical after merely masking MZ relocations. |
| `2CC6` | `2D04` | `2D07` | Entire A0h-byte Dos segment is raw byte-identical. |

Toolbox code SHA-256, concatenating the documented code ranges: `a8fd40159dc1d87fc539fa1bf12d7f381ee1e89aade2a8217ba012eb59be8787` in all three episodes. `toolbox_code_identity.json` defines the exact scope. `asm_episode_compare.json` checks every cataloged custom routine; all **123** assembly routine entries/continuations pass after only the specified link-address normalization.

The full toolbox differences are four DS destination offsets in its Pascal initializer (`7140` → `7166`), four far System-call segment relocation words, and scratch storage. Examples: SAM1 `1586–1590` contains `   restore`, SAM2 contains other old bytes, SAM3 zeros; `18C2–18CA` and `1B22–1B27` behave similarly. Masking only MZ relocation words is consequently insufficient. Do not hard-code SAM1's scratch bytes as required assembly initialization values.

## Routine catalog and confidence

`asm_routines.json` includes **123 custom assembly routines/continuations plus two Pascal INLINE fragments**, with segment/start/end, calling convention, instruction ranges, argument widths/offsets, CS/DS data references and evidence. The bounding end can span an embedded helper, so `code_ranges` identifies the actual reachable instruction ranges. Dead forward-jump padding and unreachable trailing returns are separately checked by the whole-toolbox comparison. Borland runtime API identities are classified above; this catalog focuses on custom/third-party assembly rather than renaming the entire standard runtime.

Boundaries and byte identities are high confidence. Most behavioral names are medium confidence; the circle/ellipse, shifted-image variants and some unused printer APIs remain guesses. `{$L}` provenance is strongly supported by the placement experiment and instruction styles, but an EXE alone cannot prove the original source directive or assembler version. A matching reconstruction can use TASM 1.0 defaults, provided the TP OBJ segment declaration, Pascal argument order and cleanup, CS fixups, reserved data holes and inactive anomalous returns are preserved.

The full custom routine table follows.

| Segment | Start–end (exclusive) | Name guess | Convention | CS / DS data |
|---|---|---|---|---|
| 0000 | 0bf5–0bf6 | timer_interrupt_inline_cli | embedded in Pascal interrupt procedure 0BE5..0E33; no separate call boundary | CS —; DS — |
| 0000 | 0e26–0e27 | timer_interrupt_inline_sti | embedded in Pascal interrupt procedure 0BE5..0E33; no separate call boundary | CS —; DS — |
| 0000 | 5151–516d | read_cmos_bcd | far register convention, no stack arguments; RETF; AL = CMOS index, AX = decoded byte | CS —; DS — |
| 0000 | 516d–51df | synchronize_dos_clock_from_cmos | far register convention, no stack arguments; RETF | CS 514a,514b,514c,514d,514e,514f; DS — |
| 0000 | 51df–51f3 | set_pit_timer_140hz | far register convention, no stack arguments; RETF | CS —; DS — |
| 0000 | 51f3–5200 | restore_pit_timer_default | far register convention, no stack arguments; RETF | CS —; DS — |
| 25e5 | 04a3–04bf | text_cell_address_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS 21d6 |
| 25e5 | 04bf–0508 | write_colored_pascal_string | far / pop 10 / BP+6 | CS —; DS 21d8 |
| 25e5 | 0508–054f | write_pascal_string_characters_only | far / pop 8 / BP+6 | CS —; DS 21d8 |
| 25e5 | 054f–0557 | query_bios_video_mode_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS 21de |
| 25e5 | 0557–05c3 | detect_video_adapter | far / no args | CS —; DS 21de,21df |
| 25e5 | 05c3–05c7 | get_video_mode | far / no args | CS —; DS — |
| 2642 | 000f–0047 | pcx_set_display_type | far / pop 2 / BP+6 | CS —; DS 21e0 |
| 2642 | 0047–00eb | pcx_set_graphics_or_text_mode | far / pop 2 / BP+6 | CS —; DS 21e0,21e2,21e4 |
| 2642 | 00eb–011a | pcx_get_display_type | far / no args | CS —; DS 21e0 |
| 2642 | 011a–0155 | pcx_get_version_string | far / pop 4 / BP+6 | CS —; DS — |
| 2642 | 0155–01ac | pcx_set_work_buffer | far / pop 6 / BP+6 | CS —; DS 2a8a,2a8c,2a8e |
| 2642 | 01ac–0204 | pcx_get_display_descriptor | far / pop 2 / BP+6 | CS —; DS — |
| 2642 | 0204–026b | pcx_get_display_information | far / pop 6 / BP+6 | CS —; DS — |
| 2642 | 026b–0c70 | pcx_initialize_video_descriptors | far / no args | CS —; DS 21e0,21e2,21e4,21e6,2a8a,2a8c,2a8e,2a90,2a96,2a97,2a98,2a99,2a9a |
| 2642 | 0c70–0cc4 | pcx_hercules_mode_helper | far / no args | CS —; DS — |
| 2642 | 0cc4–0cf9 | pcx_set_cga_palette | far / pop 2 / BP+6 | CS —; DS — |
| 2642 | 0cf9–0d2d | pcx_set_mode_change_policy | far / pop 2 / BP+6 | CS —; DS 21e6 |
| 2642 | 0d2d–0dc7 | pcx_display_buffer | far / pop 12 / BP+6 | CS —; DS 21e6,2a96 |
| 2642 | 0dc7–0f9b | pcx_initialize_display_dispatch | far / no args | CS —; DS 2a96 |
| 2642 | 0f9b–10d7 | pcx_cga_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 10d7–12b6 | pcx_ega_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 12b6–137a | pcx_vga_256_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 137a–14a7 | pcx_hercules_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 14a7–15d1 | pcx_paradise_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 15d1–16f5 | pcx_tseng_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 16f5–1915 | pcx_video7_decode_continuation | far-jump continuation of pcx_display_buffer; inherits BP frame; Pascal far callee cleanup 12 bytes | CS —; DS — |
| 2642 | 1915–19e3 | pcx_decode_or_print_buffer | far / pop 10 / BP+6 | CS —; DS 2a8a,2a8c,2a8e,2a90,2a92,2a94 |
| 2642 | 19e3–1a5f | pcx_flush_print_buffer | far / pop 2 / BP+6 | CS —; DS 2a8a,2a8c,2a8e,2a90,2a92,2a94 |
| 2642 | 1a5f–1ac6 | pcx_configure_printer | far / pop 12 / BP+6 | CS —; DS 2e9e,2ea0,338a,338c,338e,3390 |
| 2642 | 1ac6–1bf7 | pcx_begin_printer_image | far / pop 6 / BP+6 | CS —; DS 2ea0,338a,338c,3390,3392,3394 |
| 2642 | 1bf7–1c28 | pcx_end_printer_image | far / no args | CS —; DS 338e |
| 2642 | 1c28–1d60 | pcx_print_buffer | far / pop 10 / BP+6 | CS —; DS — |
| 2642 | 1d60–1d71 | pcx_send_printer_string | far / no args | CS —; DS 338a |
| 2642 | 1d71–201f | pcx_print_scanline | far / no args | CS —; DS 2e9c,2ea0,338a,338c,3392,3394 |
| 2642 | 2020–20a2 | pcx_format_unsigned_decimal | far / pop 8 / BP+6 | CS —; DS — |
| 2642 | 20a2–22b8 | pcx_initialize_printer_state | far / no args | CS —; DS 2e9e,2ea0,338a,338c,338e,3390 |
| 286e | 007f–00cc | read_four_joystick_axes_unused | far / pop 16 / BP+6 | CS —; DS — |
| 286e | 00a9–00c5 | measure_joystick_axis_helper | internal near call E8; register arguments DX/AH/ES:DI; anomalous RETF | CS —; DS — |
| 286e | 00cc–00fb | read_joystick_axis | far / pop 2 / BP+6 | CS —; DS — |
| 2890 | 0c14–0cfc | decrypt_asset_buffer | far / pop 6 / BP+6 | CS —; DS — |
| 29c2 | 01a3–01c5 | set_toolbox_video_mode | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 01c5–01d3 | set_bios_video_mode | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 01d3–01f9 | set_screen_stride | far / pop 2 / BP+6 | CS 011c; DS — |
| 29c2 | 01f9–024c | pan_display_retrace_variant_a | far / pop 4 / BP+6 | CS 011c; DS — |
| 29c2 | 024c–029f | pan_display_retrace_variant_b | far / pop 4 / BP+6 | CS 011c; DS — |
| 29c2 | 029f–02db | set_split_scanline | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 02db–02fa | wait_vertical_retrace | far / no args | CS —; DS — |
| 29c2 | 02fa–0337 | set_split_scanline_registers | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 0337–0349 | set_border_color | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 0349–0352 | reset_current_video_mode | far / no args | CS —; DS — |
| 29c2 | 0352–0364 | set_palette_register | far / pop 4 / BP+6 | CS —; DS — |
| 29c2 | 0364–0372 | set_text_direction | far / pop 2 / BP+6 | CS 26e7; DS — |
| 29c2 | 0372–0475 | blit_masked_32x16 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 0475–051f | blit_masked_16x16 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 051f–059f | blit_masked_8x8 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 05a1–0625 | blit_single_plane_rectangle | far / pop 12 / BP+6 | CS 011c,0192,0194,059f; DS — |
| 29c2 | 0625–0633 | set_color_or_plane_mask | far / pop 2 / BP+6 | CS 0194; DS — |
| 29c2 | 0633–0641 | select_draw_page | far / pop 2 / BP+6 | CS 0192; DS — |
| 29c2 | 0641–06c1 | put_pixel | far / pop 4 / BP+6 | CS 011c,0192,0194; DS — |
| 29c2 | 06c1–075d | put_pixel_clipped | far / pop 4 / BP+6 | CS 011c,0192,0194,019b,019d,019f,01a1; DS — |
| 29c2 | 075d–07c6 | get_pixel | far / pop 4 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 07c6–07d4 | show_video_page_bios | far / pop 2 / BP+6 | CS —; DS — |
| 29c2 | 07d4–07ec | set_mouse_cursor_shape | far / pop 8 / BP+6 | CS —; DS — |
| 29c2 | 07ee–087e | fill_rectangle_byte_aligned | far / pop 8 / BP+6 | CS 011c,0192,0194,07ec; DS — |
| 29c2 | 087e–098a | fill_rectangle_clipped | far / pop 8 / BP+6 | CS 011c,0192,0194,0197,0199,019b,019d,07ec; DS — |
| 29c2 | 098a–09c6 | pixel_address_and_bit_helper | far register helper, AX=y and BX=x; returns ES:BX/CL/AH; RETF | CS 011c,0192; DS — |
| 29c2 | 09ce–0b6a | draw_line_bresenham | far / pop 8 / BP+6 | CS 011c,0194,09c6,09c8,09ca,09cc; DS — |
| 29c2 | 0b6a–0d0a | draw_line_bresenham_variant | far / pop 8 / BP+6 | CS 011c,0194,09c6,09c8,09ca,09cc; DS — |
| 29c2 | 0d0a–0e48 | draw_rectangle_outline | far / pop 8 / BP+6 | CS 011c,0194,0196; DS — |
| 29c2 | 0e48–106f | draw_rectangle_outline_clipped | far / pop 8 / BP+6 | CS 011c,0194,019b,019d,019f,01a1; DS — |
| 29c2 | 106f–1105 | fill_rectangle | far / pop 8 / BP+6 | CS 011c,0194; DS — |
| 29c2 | 1105–1204 | fill_rectangle_clipped_pixels | far / pop 8 / BP+6 | CS 011c,0194,019b,019d,019f,01a1; DS — |
| 29c2 | 1204–129c | draw_horizontal_span | far / pop 6 / BP+6 | CS 011c,0194; DS — |
| 29c2 | 129c–12f2 | draw_vertical_span | far / pop 6 / BP+6 | CS 011c,0194; DS — |
| 29c2 | 12fc–1586 | draw_circle_variant_a | far / pop 6 / BP+6 | CS 011c,0194,12f2,12f4,12f6,12f8,12fa; DS — |
| 29c2 | 1590–1731 | draw_circle_symmetric | far / pop 6 / BP+6 | CS 011c,0194,1586,1588,158a; DS — |
| 29c2 | 1731–1754 | set_clip_rectangle | far / pop 8 / BP+6 | CS 0197,0199,019b,019d; DS — |
| 29c2 | 1754–1759 | get_clip_left | far / no args | CS 0197; DS — |
| 29c2 | 1759–175e | get_clip_right | far / no args | CS 0199; DS — |
| 29c2 | 175e–1781 | set_clip_rectangle_variant | far / pop 8 / BP+6 | CS 019b,019d,019f,01a1; DS — |
| 29c2 | 1781–1786 | get_clip_left_variant | far / no args | CS 019f; DS — |
| 29c2 | 1786–178b | get_clip_right_variant | far / no args | CS 01a1; DS — |
| 29c2 | 178b–1790 | get_clip_top | far / no args | CS 019b; DS — |
| 29c2 | 1790–1795 | get_clip_bottom | far / no args | CS 019d; DS — |
| 29c2 | 1795–1831 | capture_planar_rectangle | far / pop 12 / BP+6 | CS 0110,0112,011c,0192; DS — |
| 29c2 | 1831–18c2 | restore_planar_rectangle | far / pop 8 / BP+6 | CS 0110,0112,011c,0192; DS — |
| 29c2 | 18ca–19f9 | blit_masked_shifted_sprite_variant_a | far / pop 8 / BP+6 | CS 011c,0192,18c2,18c3,18c4,18c5,18c6,18c7,18c8,18c9; DS — |
| 29c2 | 19f9–1b22 | blit_masked_shifted_16x16 | far / pop 8 / BP+6 | CS 011c,18c2,18c3,18c4,18c6,18c7,18c8,18c9; DS — |
| 29c2 | 1b27–1c58 | blit_masked_variable_sprite | far / pop 8 / BP+6 | CS 011c,0192,1b22,1b23,1b26; DS — |
| 29c2 | 1c58–1e02 | draw_ellipse_or_curve | far / pop 8 / BP+6 | CS 011c,0194; DS — |
| 29c2 | 1e02–1e73 | curve_symmetric_pixel_helper | near register/helper convention; RET; may inherit caller BP frame | CS 011c; DS — |
| 29c2 | 1e73–1e7f | multiply_partial_products_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS — |
| 29c2 | 1e87–2053 | blit_masked_32x16_clipped | far / pop 8 / BP+6 | CS 011c,0192,1e7f,1e81,1e83,1e85; DS — |
| 29c2 | 2053–2173 | blit_masked_16x16_clipped | far / pop 8 / BP+6 | CS 011c,0192,1e7f,1e81,1e83,1e85; DS — |
| 29c2 | 2173–2208 | capture_planar_rectangle_variant | far / pop 12 / BP+6 | CS 0110,0112,011c; DS — |
| 29c2 | 2208–233a | restore_planar_rectangle_variant | far / pop 8 / BP+6 | CS 0110,0112,0114,0116,0118,011a,011c; DS — |
| 29c2 | 233a–2463 | blit_opaque_shifted_sprite_variant_a | far / pop 8 / BP+6 | CS 011c,0192,18c2,18c3,18c4,18c5,18c6,18c7,18c8,18c9; DS — |
| 29c2 | 2463–259a | blit_opaque_shifted_16x16 | far / pop 8 / BP+6 | CS 011c,18c2,18c3,18c4,18c5,18c6,18c7,18c8,18c9; DS — |
| 29c2 | 259a–26cf | blit_opaque_variable_sprite | far / pop 8 / BP+6 | CS 011c,0192,1b22,1b23,1b26; DS — |
| 29c2 | 26e9–27e2 | draw_pascal_string | far / pop 8 bytes; PUSH DS before BP shifts arguments to BP+8 | CS 00e6,00e8,00ee,00f0,00f2,00f4,00f6,00fc,00fe,26cf,26d1,26d3,26e7; DS — |
| 29c2 | 27e2–2829 | initialize_rom_fonts | far / no args | CS 26d9,26db,26dd,26df,26e1,26e3; DS — |
| 29c2 | 2829–28a7 | draw_font_row_horizontal_helper | near register/helper convention; RET; may inherit caller BP frame | CS 00e6,00e8,00ea,00ec,00ee,00f8,00fa,0100,0194,0196; DS — |
| 29c2 | 28a7–28e8 | draw_font_row_vertical_helper | near register/helper convention; RET; may inherit caller BP frame | CS 00e6,00e8,00ea,00ec,26e7; DS — |
| 29c2 | 28e8–28f1 | set_ega_bit_mask_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS — |
| 29c2 | 28f1–28ff | set_ega_set_reset_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS — |
| 29c2 | 28ff–2908 | set_ega_data_rotate_helper | near register/helper convention; RET; may inherit caller BP frame | CS —; DS — |
| 29c2 | 2908–2936 | font_pixel_address_helper | near register/helper convention; RET; may inherit caller BP frame | CS 00ea,00ec,011c,0192; DS — |
| 29c2 | 2936–2981 | draw_font_pixel_helper | near register/helper convention; RET; may inherit caller BP frame | CS 00ea,00ee,0108,0194,0196; DS — |
| 29c2 | 2981–29c3 | select_rom_font | far / pop 2 / BP+6 | CS 26cf,26d1,26d3,26d9,26db,26dd,26df,26e1,26e3; DS — |
| 29c2 | 29c3–2a9f | blit_opaque_32x16 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 2a9f–2b38 | blit_opaque_16x16 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 2b38–2bb2 | blit_opaque_8x8 | far / pop 8 / BP+6 | CS 011c,0192; DS — |
| 29c2 | 2bb2–2d5d | blit_opaque_32x16_clipped | far / pop 8 / BP+6 | CS 011c,0192,1e7f,1e81,1e83,1e85; DS — |
| 29c2 | 2d5d–2e6d | blit_opaque_16x16_clipped | far / pop 8 / BP+6 | CS 011c,0192,1e7f,1e81,1e83,1e85; DS — |
| 29c2 | 2e6d–2ecf | copy_cached_video_tile_16x16 | far / pop 6 / BP+6 | CS 011c; DS — |
| 29c2 | 2ecf–2f32 | copy_video_screen_region_320x200 | far / pop 8 / BP+6 | CS 011c; DS — |
| 29c2 | 2f32–2f7b | copy_video_band_320x8 | far / no args | CS —; DS — |
| 29c2 | 2f7b–2fd7 | copy_video_tile_16x16_unused_cdecl | far caller cleanup (active RETF); stack words at BP+6 onward; unreachable Pascal RETF n follows | CS 011c; DS — |
| 29c2 | 2fd7–303a | copy_video_rectangle_unused_cdecl | far caller cleanup (active RETF); stack words at BP+6 onward; unreachable Pascal RETF n follows | CS 011c; DS — |
