# Secret Agent data formats

This is a porting specification derived from the readable source in `game/`
and checked against every supplied data file in `assets/` for all three episodes.
Routine names are the citations: source line numbers are deliberately avoided
because the readability pass is still moving them. All offsets below are zero
based; Pascal array indices in source are usually one based. All multibyte
file fields are little endian. TP `Integer` is signed 16 bit, `Word` unsigned
16 bit, `LongInt` signed 32 bit, `Byte`/`Char` one byte. A Pascal `String[N]`
occupies N+1 bytes: length byte, that many characters, then unused storage.
Never interpret its unused tail as text.

## Inventory and readers

`n` is the episode, 1, 2 or 3. Extensions are historical names, not type tags.

| Filename | Bytes per file | Actual format | Reader |
|---|---:|---|---|
| `SAMn01.GFX` | 129024 | 16 encrypted banks of 50 masked 16×16 images | `SAMUI.LoadGameSpriteBanks` |
| `SAMn02.GFX` | 6144 | 3 encrypted banks of 50 masked 8×8 glyphs | `SAMUI.LoadGameSpriteBanks` |
| `SAMn03.GFX` | 34272 | 17 fixed level slots, encrypted row payloads | `SAMLEVEL.LoadLevelMap`, `DecodeLevelRow` |
| `SAMn01E.SND`, `02E.SND`, `03E.SND` | 7320 each | 12 × 305 signed words, encrypted | program startup in `SAM.PAS`; `SAMSOUND.StartSoundEffect`, `SAM.TimerInterrupt` consume it |
| `SAMn.CFG` | 467 | one packed configuration/high-score record | `SAM.LoadGameConfig`, `SaveGameConfig` |
| `SAMn-0.SAV` … `SAMn-9.SAV` | 72 (source layout) | one packed snapshot record | `SAMUI.WriteSavedGame`, `ReadSavedGame` |
| `SAMn.APO` | 16304 | 320×200 four-plane PCX | `SAMUI.ShowApogeeSplash` |
| `SAMn.CRD` | 17420 | 320×200 four-plane PCX | `SAMUI.ShowTitleAndCredits` |
| `SAM1.TTL`, `SAM2.TTL`, `SAM3.TTL` | 22885 / 22450 / 22211 | 320×200 four-plane PCX | `SAMUI.ShowTitleAndCredits` |
| `SAM1.END`, `SAM2.END` | 11091 / 20869 | 320×200 four-plane PCX | `SAMUI.ShowEpisodeEnding` |
| `SAM3A.END`, `SAM3B.END` | 28902 / 21658 | two successive 320×200 PCX screens | `SAMUI.ShowEpisodeEnding` |
| `SAM1.EXE`, `SAM2.EXE`, `SAM3.EXE` | 63569 / 63950 / 63888 | LZEXE-packed DOS MZ program | DOS loader, not an asset reader |

Source: [SAMDATA.PAS](../game/SAMDATA.PAS) record declarations,
[SAM.PAS](../game/SAM.PAS), [SAMUI.PAS](../game/SAMUI.PAS),
[SAMLEVEL.PAS](../game/SAMLEVEL.PAS). No supplied `.SAV` exists: its layout
is source-derived and tested with synthetic records, not claimed as an
observation from a shipped save.

## Asset obfuscation

`SAMDATA.DecryptGameAssetBuffer`, implemented by
[`DECODE.ASM`](../game/DECODE.ASM), performs, for each byte i of **one call**:

```text
clear[i] = reverse_8_bits(encoded[i]) XOR key[i mod 28]
key = ASCII("Copyright 1991 Peder Jungck") + 00
encoded[i] = reverse_8_bits(clear[i] XOR key[i mod 28])
```

The terminating zero is the 28th key byte. Reverse and XOR do not commute.
The key restarts at zero for every 8064-byte sprite bank, 2048-byte glyph bank,
7320-byte sound bank, and 40-byte level-row payload. Decrypting a whole GFX
file in one pass is wrong. There is no compression in these three formats;
the startup text “Decompressing Graphics Files” describes this decoding.
PCX files, configs and saves are **not** passed to this decoder.

## Images and glyphs

`LoadGameSpriteBanks` opens an untyped file with record size `$1F80` (8064)
or `$0800` (2048), then reads it through a `file of TSpriteFileBlock` /
`file of TGlyphFileBlock` variant view. It uses typed `Read`, not `BlockRead`.
The bank contents after decoding are:

| Offset | 16×16 bank | 8×8 bank |
|---:|---|---|
| 0 | image count = 50 | glyph count = 50 |
| 1 | width in byte groups = 2 | width in byte groups = 1 |
| 2 | height = 16 | height = 8 |
| 3 | 50 × 160-byte images | 50 × 40-byte images |
| 8003 / 2003 | 61 bytes ignored padding | 45 bytes ignored padding |

The three header bytes occur **once per bank**. The source declaration slices
storage into artificial 160-byte records with `SpriteLeadingBytes[3]` and
`SpriteDataBytes[157]` (glyphs: 3+37). A call using entry i's `DataBytes[1]`
actually reads 160/40 bytes from `3 + (i-1)*stride`, including the first three
bytes of the next declared record. Do not strip three bytes from every image
or truncate an image to 157/37 bytes. This is checked against all 57 banks.

For each image, scan rows top to bottom and 8-pixel groups left to right.
Each group is five bytes: **write mask, plane 0, plane 1, plane 2, plane 3**.
Bit 7 is the left pixel. Pixel index is `p0 + 2*p1 + 4*p2 + 8*p3`.
A mask bit **1 writes**, a mask bit 0 retains the destination. An opaque
draw ignores the mask but still advances over it. These are EGA bit masks,
not the inverted AND masks used in some other DOS sprite formats.
`PgBlitMasked16x16`, `PgBlitMasked8x8`, `PgBlitOpaque16x16`,
`PgBlitOpaque8x8` in [PROGRAPX.ASM](../game/PROGRAPX.ASM) establish this
ordering; the shifted variants split a byte group between destination bytes
to support arbitrary pixel X. No per-image palette, dimensions, compression,
hotspot, bounding box, actor identity or animation rate is stored.

Disk bank order (bank index zero based, image indices 1..50):

| Bank | Source pointer / usual logical image IDs |
|---:|---|
| 0 | `SpriteBank851`, 851..900 |
| 1 | `SpriteBank001`, 1..50; island tile IDs 501..550 alias these images |
| 2 | `SpriteBank101`, 101..150 |
| 3 | `SpriteBank401`, 401..450 |
| 4 | `SpriteBank451`, 451..500 |
| 5 | `SpriteBank601`, 601..650 |
| 6 | `SpriteBank651`, 651..700 |
| 7 | `SpriteBank701`, 701..750 |
| 8 | `SpriteBank751`, 751..800 |
| 9 | `SpriteBank301`, 301..350 |
| 10 | `SpriteBank151`, 151..200 |
| 11 | `SpriteBank201`, 201..250 |
| 12 | `SpriteBank801`, 801..850 |
| 13 | `PlayerSpriteBank`, separate player pose namespace |
| 14 | `SpriteBank351`, 351..400 |
| 15 | `SpriteBank251`, 251..300 |

The glyph-bank order is `PopupFrameAndGlyphBank`, `PopupExtendedGlyphBank`,
`StatusGlyphBank`. `SAMUI.DrawGameText` implements its character-to-bank
dispatch; ASCII code is not a universal glyph-array index. Composite enemies
and UI frames are made of several images; their composition lives in code.
`SAMLEVEL.RedrawLevelCell`, `DrawLevelCellResolved`, `DrawCellForeground`
also contain special frame/buffer-dependent images (179, 499, 535, 603, 613,
624); see [runtime.md](runtime.md) before replacing the drawing model.

## Level slots in `SAMn03.GFX`

`LoadLevelMap` uses 42-byte records through `TEncodedLevelFile`, an untyped
file opened with record size 42. It discards `(level-1)*48` records to select
the level; there is no directory or pointer table. Slot size is 2016 bytes;
17 slots account for every byte of the 34272-byte file. Only the first 40
bytes of each read record are decoded; bytes 40..41 are ignored. They are
**not raw CRLF separators** in the supplied files (observed pairs are `2c50`
and `9c00`). Do not split this binary file using line endings.

1. Slot record 0: first three decoded bytes are an ASCII decimal backdrop
   tile ID (`Val`); the other 37 bytes are ignored by the loader. They are
   not a level name. The last byte sometimes looks like a marker/number but
   is not consulted by `LoadLevelMap`.
2. Record 1: map row **24**, the bottom boundary; decoded before the rest.
3. Remaining consumed records: map rows 0..23. A row whose first byte is `*`
   applies to the preceding map row; it does not advance the logical row.
   Keep all 40 columns: the marker itself is also processed as a symbol in
   column 0. A space in such an overlay leaves the previous cell unchanged.
4. Loading stops after the normal row 23, without consuming the rest of the
   48-record slot. The unused records are padding, not extra levels. Supplied
   levels use 26..41 records, including 0..15 foreground records per slot.

The world is 40×25 cells, 16×16 pixels each, or 640×400 pixels. Source
`LevelCells[1..40,1..25]` is column-major Pascal storage; file rows are
left-to-right. Each expanded `TLevelCell` is 8 bytes: base tile u16, middle
tile u16, foreground/object code u16, solid byte, one-way-support byte.
This is an **in-memory result**, not an eight-byte record in the asset file.
The object code doubles as image ID and gameplay trigger. `$FFFF` is tested
as signed -1 for invisible platforms. The symbol dictionary is in
[actors.md](actors.md), including multi-cell expansions and island meanings.
Bytes are raw codes, not Unicode or a natural-language text encoding.

`SetAndDrawLevelCell` normally writes all five fields. In foreground-only
mode it writes **only the object code**; solidity/support and lower layers
survive, even if the ordinary symbol would set them. It updates both video
buffers. `DecodeLevelRow` clears cells only for normal rows; unrecognized
bytes (including NUL) leave the cleared cells alone. `Y` places player slot
1 at `(column*16,row*16)` and centers/clamps the camera; restoring an island
snapshot can override its position. Mission actors occupy slots 2..25 in
file traversal order; the loader has no overflow check.

Backdrop codes 2, 5, 6, 7 represent backdrop +0,+1,+2,+3 respectively; code
8 resolves to tile 667. `DrawLevelCellResolved` temporarily substitutes the
real images then restores the generic codes. The bottom row supplies cached
background tiles used by `PgCopyCachedVideoTile16x16`. Preserve this indirect
meaning; generic base code 2 is not necessarily sprite 2.

Level 1 is the overhead island. Levels 2..16 are the fifteen missions; level
17 is the fortress. User-facing mission numbers are level minus one (1..16).
`DecodeIslandSymbol` numbers entrances in traversal order using
`IslandEntranceIndex+2`; M does not increment the counter, N/O/P do. It opens
the fortress barrier `l` when exactly fifteen flags in indices 2..17 equal
1. The game also marks a mission's flag when entering it, so preserve the
actual flag lifecycle in `ProcessPlayerTileContact` / program transitions
rather than treating the field name as proof that it means success only.
Blueprint flags and completed flags have 20 slots; only 17 levels exist.

## PC-speaker effects

Startup in `SAM.PAS` typed-reads one `TSpeakerSoundBank` from each SND file,
decrypting 7320 bytes per call. Effects 1..12 / 13..24 / 25..36 are in banks
01 / 02 / 03, respectively. Each effect occupies 610 bytes:

| Word column (Pascal) | Byte offset within effect | Meaning |
|---:|---:|---|
| 1..300 | 0..599 | signed frequencies in Hz; -1 terminates the sequence |
| 301 | 600 | effect priority, read by `StartSoundEffect` |
| 302 | 602 | unused by the shipped player (editor/legacy value) |
| 303 | 604 | sample-index modulus for forcing `NoSound` |
| 304..305 | 606..609 | unused by the shipped player; may contain residue |

These are synthesized square-wave frequency steps, **not PCM**, PIT divisors,
AdLib music or MIDI. At each fast timer tick, `TimerInterrupt` calls
`Crt.Sound(current sample)`, increments the one-based sample index, silences
if the **new** index modulo column 303 is zero, then checks the **next**
sample for -1 and stops. All supplied effects have a terminator at columns
5..300; all gate moduli are 2. Preserve signed -1 and zeros; do not play
the priority/tail storage. Playback details and the priority bug are in
[runtime.md](runtime.md).

## Configuration and high scores

`TGameConfiguration` is one **packed 467-byte** record; it is read/written
using Pascal typed `Read`/`Write`. No signature, version, checksum,
encryption, padding/alignment, or separate high-score file is present.

| Offset | Size | Field |
|---:|---:|---|
| 0 | 410 | ten `String[40]` score display lines, 41 bytes each |
| 410 | 40 | ten signed i32 ranked scores |
| 450 | 1 | sound enabled |
| 451,453,455,457,459,461 | 2 each | up, down, left, right, jump, fire set-1 scan codes |
| 463 | 2 | alternate video timing |
| 465 | 2 | joystick enabled |

`InsertPlayerHighScore` shifts both line and numerical arrays, pads the
entered name (inclusive loop), and appends a width-7 decimal score. Sort by
the i32 scores, not the text. The supplied SAM1 config is already customized;
SAM2/SAM3 contain the default 200000..110000 table and default bindings.
Missing-config defaults are arrows, Ctrl jump, Alt fire, sound on,
alternate video/joystick off (`LoadGameConfig`). The game does two `Reset`
calls with `IOResult`; it does not validate a short/malformed record as the
inspection tool does. Config is saved on normal exit.

## Saved games and snapshots

`TGameSnapshot` is packed, **72 bytes**, with these exact offsets. Byte
flags are not automatically 16-bit booleans even between word fields.

| Offset | Type/count | Field |
|---:|---|---|
| 0,2 | i16 each | player X,Y |
| 4 | i32 | score |
| 8,10,12 | i16 each | progress count, ammo, projectile limit |
| 14 | 20 bytes | per-level blueprint flags |
| 34,36 | i16 each | speed boost, speed time remaining |
| 38 | byte | controls reversed |
| 39 | i16 | confusion time remaining |
| 41,42 | byte each | confusion-ended message pending, slow movement |
| 43,45,47,49 | i16 each | slow time remaining, auxiliary value, entrance animation tick, entered level number |
| 51 | 20 bytes | completed-level flags |
| 71 | byte | extra-ammo cheat used |

`WriteSavedGame` rounds coordinates with `(position+8) and $FFF0`, writes
one record to `SAMn-<slot>.SAV` and closes it. Menus expose digit slots 0..9.
`CaptureGameSnapshot` keeps an in-memory copy on mission entry;
`RestoreGameSnapshot` supports return/death handling. The main menu reloads
the island and applies saved position/state. This is not a serialization of
the active actor/map state: there is no actor array, map mutation, health,
keys, floppy disk, dynamite, RNG seed or running speaker state in the record.
Do not promise resumable mid-frame saves using this legacy format.

## Full-screen PCX files

All 13 supplied APO/CRD/TTL/END files begin `0a 05 01 01`: PCX manufacturer
10, version 5, encoding 1 (RLE), 1 bit per pixel per plane. Header is 128
bytes; coordinates at 4..11 are xmin=0,ymin=0,xmax=319,ymax=199; bytes 16..63
contain sixteen RGB triplets; byte 65 is plane count 4; u16 at 66 is
bytes-per-line **per plane**, 40. Decoded size is 200×4×40 = 32000 bytes.
There is no mask. For each row the four contiguous 40-byte planes follow
one another, unlike the interleaved ProGraphx image format.

For RLE, a byte whose top two bits equal `11` means repeat the following
byte `value & 63` times; other bytes are literals. An isolated literal ≥192
is escaped as a one-byte run. Expand the complete raster, then use plane 0
as index bit 0 and the MSB as the leftmost pixel. All 13 files expand to
exactly 32000 bytes and consume the entire file; there is no 256-color
palette trailer. The inspector uses the embedded 16-color RGB palette for
its PNG; APO uses 170/85 components and the other headers use 171/87
approximations. Actual game palette programming is described in runtime.md.

`PcxDisplayFile` / `PcxRefillReadBuffer` in
[GENUS.ASM](../game/GENUS.ASM) use DOS open/read/seek/close with the 2048-byte
`PcxDefaultReadBuffer`, then `PcxDisplayBuffer` and
`PcxEgaDecodeContinuation` write EGA planes. The game selects Genus display
type 2, EGA 320×200, and calls `(filename,1,0,0)`. These files are never
asset-decrypted. `ShowTitleAndCredits` copies the credits to row 200 before
loading the title at row 0 and pans between them. SAM3 ending displays A
then B; episodes 1/2 each display one END screen. Story/order/help text and
the DOS exit screen are compiled strings, not separate asset formats.

## Episode checks and reproduction

Every episode uses the same layouts, sizes, bank order and symbol dispatcher.
Maps and sprite art differ. Byte-identical supplied files: all three APOs;
all three CRDs; sound bank 01 across all episodes; sound bank 03 across all
episodes; glyph bank file SAM202/SAM302; sound bank SAM202E/SAM302E. SAM102E
differs in effect 20. SAM1's CFG differs from the defaults; SAM2/SAM3 CFGs
decode to the same values (unused shortstring storage need not match).
Do not infer that equal filenames or equal lengths imply equal contents.

Run from the repository root:

```text
python -B tools/assets.py assets --out build/assets
python -B -m unittest tests.test_assets -v
```

The tool reads originals, checks fixed sizes/headers, and writes masked,
opaque and mask atlases (50 images, ten columns, two-pixel gutters), screen
PNGs, 51 text maps, and JSON retaining raw row hex, overlays, ignored bytes,
all sound words, configs and source hashes. Numeric sprite base + image
index - 1 gives the usual logical ID; `player` and glyph banks have their
own namespace. Maps use CP437 display glyphs for control codes; JSON hex is
the authoritative byte representation. It does not claim to simulate the
symbol expansion, compositing, hardware palette or audio waveform.

Verification output for this task is under
`build/workers/sol-formats/assets/` (270 generated files). All 34 data files
decoded, 57 bank headers matched, every level yielded 25 base rows, all 108
effects terminated within the sample area, and all 13 PCX streams ended
exactly. Synthetic tests cover key reset/NUL, sprite-record overlap, write
masks, row order/overlays, PCX planes/RLE/truncation, packed config/save
offsets, PNG CRC/raster, and refusal to export into input asset directories.
