# Level symbols, actors and interactions

Symbols are single **byte values** in decoded 40-byte map rows. `#174` means
decimal byte 174, not the text “#174”. Printable symbols below are quoted;
the complete expansion tables use decimal bytes as the stable identity.
Art names here describe appearance/behavior; the authoritative identities
are actor kind and sprite base. The same code and symbol dispatch is built
for SAM1/SAM2/SAM3, with episode-specific maps/art. All 243 byte values
observed in the consumed base/foreground rows are accounted for by the
source dispatch or the NUL no-op. See [formats.md](formats.md) for row order,
foreground records and the bank-to-image mapping.

Source citations throughout refer to routines in
[SAMLEVEL.PAS](../game/SAMLEVEL.PAS) (placement/expansion),
[SAMPLAY.PAS](../game/SAMPLAY.PAS) (behavior/contact), and
[SAM.PAS](../game/SAM.PAS) (input, rendering and transitions).
Routine names are used because the concurrent readability pass moves lines.

## Shared rules

`DecodeLevelRow` clears a normal row, scans left-to-right, expands symbols,
calls mission actor placement for mission maps, calls `DecodeIslandSymbol`,
then handles `Y` player placement. `LoadLevelMap` loads row 24 first, then
0..23 with foreground insertions. Multi-cell objects often write **above or
left** of their marker; processing order is therefore significant. Foreground
mode only changes `CellObjectCode`, preserving base/middle/solid/support;
spaces do nothing. The leading `*` is also dispatched at column zero.
Two exceptions matter for a general decoder: the `;` trap explicitly forces
full writes for its top/bottom pieces even in a foreground row, and
`DecodeIslandSymbol` always uses its own foreground flag set to zero.
The supplied island maps have no foreground records.
NUL has no handler and leaves the normal row's cleared cell unchanged.

The 8-byte expanded cell is `(base,middle,object,solid,support)`; solidity
blocks all four inset player corners, while support is one-way landing
checked during the falling half of the jump. Base/middle images alone have
no pickup semantics: contact dispatch tests the **object** field. The
foreground field is both an image and a trigger, so stripping “decorative”
objects based on image appearance will lose behavior.

Player `Y` creates kind 99 in actor slot 1 at tile×16, standing right
(sprite pose 9), step 2. Its camera is centered then clamped to X 0..320,
Y 0..184. Island saved coordinates may override `Y`. There are 24 other
actor slots, and ten separate player-shot slots (normally only one or two
enabled). Placement appends without a capacity guard. Many runtime spawners
reuse slot 25 if no slot is free; a modern allocator changes that edge case.

`UpdateActorsAndShots` updates slots in ascending order. Ordinary actors
freeze outside a 32-pixel viewport margin; kinds 14, 21 and 28 continue
offscreen. `ActorRemovalPending` requests later erasure before slot release.
`DamagePlayerOnContact` uses a 10×16 contact box, three initial health,
30 gameplay-frame damage grace, flash and sound; fatal contact starts the
35-frame death sequence. Some hazards bypass health/grace and kill directly.
`ConsumeShotsAtActor` consumes overlapping player shots. Walkers generally
turn at solids or missing support; not all actor kinds obey gravity.

## Mission actor placement and behavior

Placement is `SpawnActorFromMapSymbol` except m, _, #209, #167 and b, which
are initialized directly in `DecodeLevelRow`. Step values are pixels per
gameplay update, not per timer tick. “3 hits” describes the initial counter;
the exact code may have vulnerable phases or decrement on animation state.

| Symbol | Kind | Initial sprite / step | Behavior and update citation |
|---|---:|---|---|
| `8` | 1 | 351 / 1 | Ground guard; wall/ledge reversal, contact damage. One hit awards 100 and converts it to dropped bonus kind 5000. `UpdateBasicActor` case 1. |
| `9` | 2 | 359 / 1 | Tougher guard; hit flashes and degrades to kind 1/sprite 351, facing the player. `UpdateBasicActor` case 2. |
| `0` | 3 | 367 / 2 | Faster guard; hit degrades to kind 2/sprite 359. `UpdateBasicActor` case 3. |
| `g` | 4 | 375 / 2 | Shooting guard; random initial cooldown 50..99, fires forward when vertically aligned and facing player; hit degrades to kind 3. `UpdateBasicActor` case 4. |
| `G` | 5 | 383 / 2 | Shooting guard tier; initial cooldown 30..49, hit degrades to kind 4. `UpdateBasicActor` case 5. |
| #127 | 6 | 609 / 2 | Animated moving bomb/hazard; wall reversal, contact damage, lifetime counter, two-hit counter, then explosion sprite 625. `UpdateBasicActor` case 6. |
| `R` | 10 | 464 / 0 | Fixed right-firing emitter; random initial interval 55..74, projectile from X+8. `UpdateBasicActor` case 10. |
| `Q` | 11 | 465 / 0 | Fixed left-firing emitter, projectile from X-8. `UpdateBasicActor` case 11. |
| `<` | 12 | 487 / 0 | Solid right-firing emitter; projectile starts X+16. `UpdateBasicActor` case 12. |
| `=` | 13 | 491 / 0 | Solid left-firing emitter; projectile starts X-16. `UpdateBasicActor` case 13. |
| `;` | 15 | 435 / 0 | Vertical three-cell trap: top object 428 at y-2, bottom 427 at y, animated center y-1. Extends/retracts using a 30-tick cycle plus random phase; contact damages. `UpdateBasicActor` case 15. |
| `>` | 16 | 435 / 0 | Horizontal three-cell trap: endpoint objects 433 at x-2 and 434 at x; animated center x-1. `UpdateBasicActor` case 16. |
| `?` | 17 | 435 / 0 | Periodically appearing animated spike/trap, damage tested at y+8. `UpdateBasicActor` case 17. |
| `A` | 18 | 435 / 0 | Opposite-facing periodic trap, damage at y-8. `UpdateBasicActor` case 18. |
| `m` | 20 | 445 / 1 | Animated horizontal contact hazard, reverses at solids. `UpdateBasicActor` case 20. |
| `_` | 21 | 495 or 497 / 1 | Direction-dependent horizontal hazard, reverses at solid cells and keeps updating offscreen. `UpdateBasicActor` case 21. |
| #209 | 26 | 717 / 0 | Animated collectible; overlapping player awards 10000 then becomes rising score popup. `UpdateBasicActor` case 26. |
| #167 | 27 | 675 / 0 | Pushable/falling support object: responds to adjacent player, falls in 8-pixel steps when unsupported, supports player on top. `UpdateBasicActor` case 27. |
| `b` | 28 | 676 / 2 | Moving platform, turns at walls, carries player horizontally and updates camera; updates offscreen. `UpdateBasicActor` case 28. |
| `V` | 30 | 801 / 2 | Two-cell-tall patrolling shooter, turns at walls/edges, fires sprite 825, initial hit counter 3; death awards 1000. `UpdateActorsAndShots` case 30. |
| `X` | 31 | 817 / 2 | Tall phased shooter, fires sprite 827; cooldown/state transitions affect animation and vulnerability, hit counter starts 3; 1000 points. `UpdateActorsAndShots` case 31. |
| `#` | 32 | 151 / 0 | Radar dish objective. Three shots decrement counter; destruction sets `LevelRadarDestroyed`, awards 5000 and converts to a popup. `UpdateActorsAndShots` case 32. |
| `c` | 33 | 837 / 2 | Tall patrol/contact enemy, reverses on obstruction, periodically emits fast projectile 199; three-hit counter, 500 points. `UpdateActorsAndShots` case 33. |
| `e` | 34 | 117 / 2 | Ground patrol, three-hit counter, contact damage; death awards 1000 and emits projectiles in both directions. `UpdateActorsAndShots` case 34. |
| `u` | 35 | 109 / 0 | Stationary animated contact enemy, three hits and 1000 points. `UpdateActorsAndShots` case 35. |
| `v` | 36 | 113 / 0 | Stationary upward launcher when player is aligned above it and `CeilingLauncherDisabled=0`; counters start at 10. `UpdateActorsAndShots` case 36 requests sprite 114, direction -1, speed 8, creating lethal kind 37. |
| `n` | 38 | 133 / 2 | Moving hazard layer: random initial delays, pauses and leaves a stationary 30-frame kind-40 hazard below itself, then resumes/reverses at walls. Shot is consumed without killing the emitter. `UpdateActorsAndShots` case 38. |
| `$` | 39 | 101 / 2 | Tall phased shooter variant of kind 31, initial health 3, sprite 827 shots and 1000-point death. `UpdateActorsAndShots` case 39. |
| `[` | 41 | 435 / 0 | Invisible proximity trigger; when player approaches within 8 pixels, scans upward to a ceiling, produces falling object 619; catching it awards 5000. `UpdateActorsAndShots` case 41. |
| #174 | 42 | 851 / 2 | Two-cell-wide ground patroller, contact at both halves, reverses on walls/ledges; three hits, 500 points. `UpdateActorsAndShots` case 42. |
| `@` | 43 | 305 / 0 | Decorative animation above base object 302; randomized initial phase and Random(5) phase reset. `UpdateActorsAndShots` case 43. |
| #212 | 44 | 309 / 0 | Stationary animated contact hazard. `UpdateActorsAndShots` case 44. |
| `x` | 44 | 259 / 0 | Same contact-hazard update, different artwork. `UpdateActorsAndShots` case 44. |

Initial actor fields and all static cell side effects are also recoverable
directly from the cited placement routines. Ground guards and many larger
enemies choose initial facing with Random(2); their animation counters use
different ranges per facing. Do not turn the sprite base into the actor kind:
guards change both, and several unrelated kinds share blank sprite 435.

Runtime-only kinds have no direct map symbol:

| Kind | Origin / purpose |
|---:|---|
| 7 | Enemy bullet in `GameActors`, created by `SpawnEnemyProjectile`, horizontal collision/damage in `UpdateBasicActor`. Player shots also use kind 7 but live in the separate `PlayerShots` array, created by keyboard/joystick fire at step 8. |
| 14,19,37,40,137 | Projectile variants created by `SpawnEnemyProjectile`; exact mapping follows below. |
| 25 | Retained patrol case with timed reversal and shootable dropped bonus; no direct placement/spawn assignment found in the game source. `UpdateBasicActor` case 25. |
| 22 | Dynamite placed at blast door, countdown/explosion damages and clears the two-cell door into exit object 638. `ProcessPlayerTileContact`, `UpdateBasicActor` case 22. |
| 23 | Mine explosion after contact with object 624. `ProcessPlayerTileContact`, `UpdateBasicActor` case 23. |
| 5000 | Dropped guard bonus (sprite 391): shoot for 100 or collect for 1000, then popup. `UpdateActorsAndShots`. |
| 5001 | Rising score popup, normally 16-frame lifetime, moves up two pixels per update. `SpawnScorePopup`, `UpdateActorsAndShots`. |

`SpawnEnemyProjectile` scans for an inactive `GameActors` slot, starting
at 1 and stopping at 25; if full, it does not spawn. Its sprite dispatch is:

| Requested sprite | Actual sprite | Kind / motion |
|---:|---:|---|
| 0 | 39 | 7, ordinary horizontal bullet |
| 470,125,126 | same | 7, horizontal projectile art variants |
| 825,827 | same | 19, animated horizontal projectile |
| 114 | 114 | 37, Y direction set from Direction; instant-kill collision |
| 199 | 114 | 137, Y direction set from Direction; ordinary contact damage |
| 137 | 137 | 40, timed contact hazard with counter B=30; its caller supplies step 0 |
| other nonzero | same | 14, animated horizontal contact projectile |

Spawn X is aligned with `$FFF8` except requested sprite 137. The common
spawn initializes X direction from Direction even for vertical variants;
their update branch chooses the actual movement axis. All of these use
the actor pool and may compete with enemies, bonuses and score popups.

## Items, hazards and mission progression

All effects in this table dispatch through `ProcessPlayerTileContact`, called
by `CheckPlayerTileContacts` at the four inset player corners. Most pickups
clear their object code, request HUD redraw, and play a sound. Contact is
automatic; an extra use-key action is not implied.

| Symbol | Object code | Effect |
|---|---:|---|
| `+`, `-`, `/` | 421,423,425 | Three key inventory flags. |
| `,`, `.`, `4` | 422,424,426 | Solid matching doors; consume corresponding key and clear object+solid flag. |
| `s` | 301 | Ammo +5, cap 99. |
| `^` | 314 | 5000 points, raises simultaneous shot limit to at most 2. |
| `N` | 313 | 250 points; speed boost +4 with timer 216. |
| `:` | 466 | Reverse left/right; confusion timer 216 and message. |
| `H` | 468 | Slow movement; timer 216. |
| `P` | 304 | Blueprint, 2000 points, level blueprint flag and episode-completion flag. |
| #132 | 605 | Floppy disk and 500 points. |
| #131 | 604 | Computer needs disk; consumes it and removes all laser object 603 cells scanned in rows 1..24, then shows message. |
| #130 | 603 | Laser field: instant death unless god mode; buffer-alternating visibility. |
| `t` | 635 | Dynamite inventory and 500 points. |
| `q` | 637 (top 633) | Solid two-cell blast door; consumes dynamite and creates actor 22. Its explosion exposes exit object 638. |
| `M` | 624 | Mine: creates kind 23 explosion, locks input and starts death unless god mode. |
| backtick, `D`, `O`, `U` | 499,613,615,616 | Instant-death contact tiles unless god mode. `E` gives object 614 with one-way support; it does not share these fatal cases. |
| `w` | 183 (top 179) | Teleporter, on island and missions. Align within ±2 pixels (source excludes exact equality), lock input, 19-frame animation, locate another pad in row/column scan, offset landing X ±3 by neighboring solidity. |
| `r` | 607 | Reveals invisible objects -1 as middle tile 608 and one-way support; redraws both buffers with 100 ms delay per revealed cell. |
| #211 | -1 | Initially invisible/non-supporting cell; made visible/supporting by r. |
| #140,#141,#142 | 621,622,623 | Ordered bonus letters: 100 each for first/second, third awards 10000 if order remains valid, otherwise 100; all are removed. |
| `T`, #1 | 316,619 | 1000-point objects. |
| `W` | 618 | 250-point object. |
| backslash | 620 | 500-point object. |
| `]`, `d`, `f`, `h` | 629,630,631,632 | 100 / 1000 / 500 / 100 points. |
| `K` | 606 | 500-point object. |

The contact dispatcher additionally handles codes 44 (+500), 49 (+100 and
counter), 322 (+1000 and special movement for 432 frames), 323..325 (+100
and remove support), and 617 (increment progress). These are retained code
paths, but `DecodeLevelRow` does not directly produce them from a mission
symbol. Do not invent map tokens for them. Static scene/foreground symbols
not listed as actors/items above are specified by their exact layer and
collision expansions in the tables below.

Exit object 638 works only when `LevelRadarDestroyed` is set; otherwise the
player is pushed away and shown the radar warning. Successful exit marks
the mission flag and starts the exit animation/island return. Full health
awards **25000**. If the episode blueprint flag is set, exit requests the
ending. `ProcessPlayerTileContact`, program exit animation and
`SAMUI.ShowEpisodeEnding` implement the sequence. Keys, floppy disk,
dynamite, health and temporary mission state are reset by
`SAMDATA.ResetLevelTransientState`; saved state is the smaller structure in
formats.md.

## Island symbols

`DecodeIslandSymbol` applies only when current level is 1. Upper/lower case
and digits retain different meanings from missions. A is walkable tile 501;
B..G are solid island terrain; H/I/K/L select backdrop; J uses 661. U is
solid tile 521, a is solid tile 527, and the other terrain pieces have the
exact fields shown in the table. The barrier l is solid tile 508 until
exactly fifteen mission flags in indices 2..17 are set; it then becomes
walkable backdrop.

M/N/O/P mark entrances with base field `IslandEntranceIndex+2` and object
513/514/515/516. Completed versions are 517/518/519/520, which no longer
take the active-entrance contact branch (513..516). M leaves the counter
alone; N/O/P each increment it. `ProcessPlayerTileContact` reads the target
**from the base field**, captures the island snapshot, sets entered-level
state and loads the mission. It marks the flag on entry; return/warp/death
handling in the main program can clear it. Fortress availability depends
on that actual lifecycle, not merely the flag's name.

The island dispatcher contains two w handlers: the first writes object 687,
then the second overwrites it with teleporter 183 and writes 179 above it.
This duplicate is deliberate in the reconstructed source; keep the latter
effect. `Y`, spaces and NUL retain their shared meanings.

## Exact symbol-to-cell expansion tables

Notation: each cell write is `dx,dy: base/middle/object; solid,support`,
relative to the marker. `bg` means `LevelBackdropTile`; `b` means generic
backdrop placeholder 2, resolved later by drawing. Numeric flags are 0/1.
Several writes separated by semicolons are applied in source order. These
are ordinary-row arguments to `SetAndDrawLevelCell`; foreground mode only
applies their object component, except writes marked `[full]`, which force
ordinary mode. Actor placement still occurs when its symbol
is processed; the foreground marker does not make an alternate actor format.
Decimal byte IDs remove Markdown/CP437 ambiguity (`#124` is the vertical bar,
`#92` backslash, `#96` backtick). Tables transcribe all placement calls from
`DecodeLevelRow`, `SpawnActorFromMapSymbol`, and `DecodeIslandSymbol`;
conditional entrance/barrier rows are explained immediately above.

<!-- SYMBOL_TABLES -->

### Mission/shared writes

| Decimal byte / printable label | Cell writes in source order | Spawn |
|---|---|---|
| #0 | no dispatch; normal row remains cleared | |
| #1 | 0,0: b/0/619; 0,0 |  |
| #2 | 0,0: b/161/0; 0,0 |  |
| #3 | 0,0: b/162/0; 0,0 |  |
| #4 | 0,0: b/155/0; 0,0 |  |
| #5 | -1,0: 156/0/0; 0,1<br>0,0: 157/0/0; 0,1 |  |
| #6 | 0,0: b/158/0; 0,0 |  |
| #7 | 0,0: b/174/0; 0,0 |  |
| #8 | -1,0: b/181/0; 0,1<br>0,0: b/182/0; 0,1 |  |
| #11 | 0,0: b/178/0; 0,1 |  |
| #12 | -1,0: b/185/0; 0,1<br>0,0: b/186/0; 0,1 |  |
| #14 | 0,0: b/733/0; 0,0 |  |
| #15 | 0,0: b/734/0; 0,0 |  |
| #16 | 0,0: b/735/0; 0,0 |  |
| #17 | 0,0: b/737/0; 0,0 |  |
| #18 | 0,0: b/741/0; 0,0 |  |
| #19 | 0,0: b/743/0; 0,0 |  |
| #20 | 0,-1: b/745/0; 0,0<br>0,0: b/749/0; 0,0 |  |
| #21 | 0,0: b/746/0; 0,0 |  |
| #22 | 0,0: b/750/0; 0,0 |  |
| #23 | 0,0: b/677/0; 0,0 |  |
| #24 | 0,0: b/678/0; 0,0 |  |
| #25 | 0,-1: b/251/0; 0,1<br>0,0: b/255/0; 0,0 |  |
| #27 | -1,-1: b/252/0; 0,1<br>0,-1: b/253/0; 0,1<br>-1,0: b/256/0; 0,0<br>0,0: b/257/0; 0,0 |  |
| #28 | 0,-1: b/254/0; 0,1<br>0,0: b/258/0; 0,0 |  |
| #30 | 0,0: 8/0/0; 0,0 |  |
| #31 | 0,0: bg/166/0; 1,0 |  |
| #32 space | 0,0: b/0/0; 0,0 |  |
| #33 `!` | 0,0: 751/0/0; 0,0 |  |
| #35 `#` | 0,0: b/0/0; 0,0 | actor 32 |
| #36 `$` | 0,0: b/0/0; 0,0 | actor 39 |
| #37 `%` | -1,0: b/0/452; 0,0<br>0,0: b/0/453; 0,0 |  |
| #38 `&` | -1,-1: 455/0/0; 1,0<br>0,-1: 456/0/0; 1,0<br>-1,0: 459/0/0; 1,0<br>0,0: 460/0/0; 1,0 |  |
| #40 `(` | -1,-1: 457/0/0; 1,0<br>0,-1: 458/0/0; 1,0<br>-1,0: 461/0/0; 1,0<br>0,0: 462/0/0; 1,0 |  |
| #41 `)` | 0,0: b/0/463; 0,0 |  |
| #42 `*` | 0,0: b/0/467; 0,0 |  |
| #43 `+` | 0,0: b/0/421; 0,0 |  |
| #44 `,` | 0,0: b/0/422; 1,0 |  |
| #45 `-` | 0,0: b/0/423; 0,0 |  |
| #46 `.` | 0,0: b/0/424; 1,0 |  |
| #47 `/` | 0,0: b/0/425; 0,0 |  |
| #48 `0` | 0,0: b/0/0; 0,0 | actor 3 |
| #49 `1` | 0,0: 1/0/0; 1,0 |  |
| #50 `2` | 0,0: 3/0/0; 1,0 |  |
| #51 `3` | 0,0: 4/0/0; 1,0 |  |
| #52 `4` | 0,0: b/0/426; 1,0 |  |
| #53 `5` | 0,0: 5/0/0; 0,0 |  |
| #54 `6` | 0,0: 6/0/0; 0,0 |  |
| #55 `7` | 0,0: 7/0/0; 0,0 |  |
| #56 `8` | 0,0: b/0/0; 0,0 | actor 1 |
| #57 `9` | 0,0: b/0/0; 0,0 | actor 2 |
| #58 `:` | 0,0: b/0/466; 0,0 |  |
| #59 `;` | 0,-2: b/0/428; 1,0 [full]<br>0,-1: b/0/0; 0,0<br>0,0: b/0/427; 1,0 [full] | actor 15 |
| #60 `<` | 0,0: b/0/487; 1,0 | actor 12 |
| #61 `=` | 0,0: b/0/491; 1,0 | actor 13 |
| #62 `>` | -2,0: b/0/433; 1,0<br>-1,0: b/0/0; 0,0<br>0,0: b/0/434; 1,0 | actor 16 |
| #63 `?` | 0,0: b/0/0; 0,0 | actor 17 |
| #64 `@` | 0,0: b/0/302; 0,0 | actor 43 |
| #65 `A` | 0,0: b/0/0; 0,0 | actor 18 |
| #66 `B` | 0,0: bg/753/0; 0,1 |  |
| #67 `C` | 0,0: 755/0/0; 1,0 |  |
| #68 `D` | 0,0: b/0/613; 0,0 |  |
| #69 `E` | 0,0: bg/0/614; 0,1 |  |
| #70 `F` | 0,0: bg/756/0; 1,0 |  |
| #71 `G` | 0,0: b/0/0; 0,0 | actor 5 |
| #72 `H` | 0,0: b/0/468; 0,0 |  |
| #73 `I` | 0,0: bg/0/0; 0,1 |  |
| #74 `J` | 0,0: bg/757/0; 1,0 |  |
| #75 `K` | 0,0: b/0/606; 0,0 |  |
| #76 `L` | 0,0: bg/789/0; 1,0 |  |
| #77 `M` | 0,0: b/0/624; 0,0 |  |
| #78 `N` | 0,0: b/0/313; 0,0 |  |
| #79 `O` | 0,0: b/0/615; 0,0 |  |
| #80 `P` | 0,0: b/0/304; 0,0 |  |
| #81 `Q` | 0,0: b/465/0; 0,0 | actor 11 |
| #82 `R` | 0,0: b/464/0; 0,0 | actor 10 |
| #83 `S` | 0,0: b/0/790; 0,0 |  |
| #84 `T` | 0,0: b/0/316; 0,0 |  |
| #85 `U` | 0,0: b/0/616; 0,0 |  |
| #86 `V` | 0,0: b/0/0; 0,0 | actor 30 |
| #87 `W` | 0,0: b/0/618; 0,0 |  |
| #88 `X` | 0,0: b/0/0; 0,0 | actor 31 |
| #89 `Y` | 0,0: b/0/0; 0,0 | player 99 |
| #90 `Z` | -1,-1: b/795/0; 0,1<br>0,-1: b/796/0; 0,1<br>-1,0: b/799/0; 0,0<br>0,0: b/800/0; 0,0 |  |
| #91 `[` | 0,0: b/0/0; 0,0 | actor 41 |
| #92 `\` | 0,0: b/0/620; 0,0 |  |
| #93 `]` | 0,0: b/0/629; 0,0 |  |
| #94 `^` | 0,0: b/0/314; 0,0 |  |
| #95 `_` | 0,0: b/0/0; 0,0 | actor 21 |
| #96 | 0,0: b/0/499; 0,0 |  |
| #97 `a` | 0,0: 500/0/0; 1,0 |  |
| #98 `b` | 0,0: b/0/0; 0,0 | actor 28 |
| #99 `c` | 0,0: b/0/0; 0,0 | actor 33 |
| #100 `d` | 0,0: b/0/630; 0,0 |  |
| #101 `e` | 0,0: b/0/0; 0,0 | actor 34 |
| #102 `f` | 0,0: b/0/631; 0,0 |  |
| #103 `g` | 0,0: b/0/0; 0,0 | actor 4 |
| #104 `h` | 0,0: b/0/632; 0,0 |  |
| #105 `i` | 0,0: 441/0/0; 0,0 |  |
| #106 `j` | 0,0: bg/442/0; 0,1 |  |
| #107 `k` | 0,0: bg/443/0; 1,0 |  |
| #108 `l` | 0,0: bg/444/0; 0,1 |  |
| #109 `m` | 0,0: b/0/0; 0,0 | actor 20 |
| #110 `n` | 0,0: b/0/0; 0,0 | actor 38 |
| #111 `o` | 0,0: bg/417/0; 1,0 |  |
| #112 `p` | -1,0: b/159/0; 0,0<br>0,0: b/160/0; 0,0 |  |
| #113 `q` | 0,-1: b/0/633; 1,0<br>0,0: b/0/637; 1,0 |  |
| #114 `r` | 0,0: b/0/607; 0,0 |  |
| #115 `s` | 0,0: b/0/301; 0,0 |  |
| #116 `t` | 0,0: b/0/635; 0,0 |  |
| #117 `u` | 0,0: b/0/0; 0,0 | actor 35 |
| #118 `v` | 0,0: b/0/0; 0,0 | actor 36 |
| #119 `w` | 0,-1: b/0/179; 1,0<br>0,0: b/0/183; 0,0 |  |
| #120 `x` | 0,0: b/0/0; 0,0 | actor 44 |
| #121 `y` | -1,0: 318/0/0; 0,1<br>0,0: 319/0/0; 0,1 |  |
| #122 `z` | 0,0: b/317/0; 0,0 |  |
| #124 | 0,0: b/419/0; 0,0 |  |
| #126 `~` | 0,0: b/420/0; 0,0 |  |
| #127 | 0,0: b/0/0; 0,0 | actor 6 |
| #128 | 0,0: b/0/601; 0,0 |  |
| #129 | 0,0: b/0/602; 0,0 |  |
| #130 | 0,0: b/0/603; 0,0 |  |
| #131 | 0,0: b/0/604; 0,0 |  |
| #132 | 0,0: b/0/605; 0,0 |  |
| #133 | -3,0: b/0/221; 0,0<br>-2,0: b/0/222; 0,1<br>-1,0: b/0/223; 0,0<br>0,0: b/0/224; 0,0 |  |
| #134 | -2,0: b/0/229; 0,0<br>-1,0: b/0/230; 0,1<br>0,0: b/0/231; 0,0 |  |
| #135 | -1,0: 323/0/0; 0,1<br>0,0: 324/0/0; 0,1 |  |
| #136 | 0,0: b/345/0; 0,0 |  |
| #137 | 0,0: b/346/0; 0,0 |  |
| #138 | 0,0: b/347/0; 0,0 |  |
| #139 | -1,0: bg/163/0; 1,0<br>0,0: bg/164/0; 1,0 |  |
| #140 | 0,0: b/0/621; 0,0 |  |
| #141 | 0,0: b/0/622; 0,0 |  |
| #142 | 0,0: b/0/623; 0,0 |  |
| #143 | 0,0: bg/651/0; 1,0 |  |
| #144 | 0,0: 652/0/0; 1,0 |  |
| #145 | 0,0: bg/653/0; 1,0 |  |
| #146 | 0,0: bg/654/0; 0,1 |  |
| #147 | 0,0: 655/0/0; 1,0 |  |
| #148 | 0,0: 656/0/0; 1,0 |  |
| #149 | 0,0: b/449/0; 0,0 |  |
| #150 | 0,0: b/0/658; 0,0 |  |
| #151 | 0,0: b/0/659; 0,0 |  |
| #152 | 0,0: b/0/660; 0,0 |  |
| #153 | 0,0: 661/0/0; 0,0 |  |
| #154 | -1,0: bg/166/0; 1,0<br>0,0: bg/165/0; 1,0 |  |
| #155 | 0,0: b/0/663; 0,0 |  |
| #156 | 0,0: b/0/664; 0,0 |  |
| #157 | 0,0: b/665/0; 0,0 |  |
| #158 | 0,0: b/666/0; 0,0 |  |
| #159 | 0,0: bg/791/0; 1,0 |  |
| #160 | 0,0: 792/0/0; 1,0 |  |
| #161 | 0,0: bg/793/0; 1,0 |  |
| #162 | 0,0: b/348/0; 0,1 |  |
| #163 | 0,0: bg/671/0; 0,1 |  |
| #164 | 0,0: bg/672/0; 0,1 |  |
| #165 | 0,0: bg/673/0; 0,1 |  |
| #166 | 0,0: bg/674/0; 0,1 |  |
| #167 | 0,0: b/0/0; 0,0 | actor 27 |
| #168 | 0,0: b/0/175; 0,0 |  |
| #169 | 0,0: b/0/176; 0,0 |  |
| #170 | 0,0: b/0/177; 0,0 |  |
| #171 | 0,-1: 194/0/0; 0,1<br>0,0: 198/0/0; 0,0 |  |
| #172 | 0,0: b/197/0; 0,0 |  |
| #173 | 0,0: 193/0/0; 0,1 |  |
| #174 | 0,0: b/0/0; 0,0 | actor 42 |
| #175 | 0,0: 349/0/0; 0,0 |  |
| #176 | 0,0: b/0/684; 0,0 |  |
| #177 | 0,0: b/0/685; 0,0 |  |
| #178 | 0,0: b/0/686; 0,0 |  |
| #179 | 0,0: b/0/687; 0,0 |  |
| #180 | 0,0: b/0/688; 0,0 |  |
| #181 | 0,0: b/0/689; 0,0 |  |
| #182 | 0,0: b/681/0; 0,0 |  |
| #183 | 0,0: b/0/691; 0,0 |  |
| #184 | 0,0: b/0/692; 0,0 |  |
| #185 | 0,0: b/0/693; 0,0 |  |
| #186 | -1,0: 690/0/0; 0,1<br>0,0: 694/0/0; 0,1 |  |
| #187 | 0,0: 695/0/0; 0,0 |  |
| #188 | 0,0: 698/0/0; 0,0 |  |
| #189 | 0,0: 696/0/0; 0,0 |  |
| #190 | 0,0: 697/0/0; 0,0 |  |
| #191 | -1,0: 679/0/0; 0,1<br>0,0: 680/0/0; 0,1 |  |
| #192 | -1,0: 699/0/0; 0,1<br>0,0: 700/0/0; 0,1 |  |
| #193 | 0,0: 701/0/0; 1,0 |  |
| #194 | 0,0: 702/0/0; 1,0 |  |
| #195 | 0,0: 703/0/0; 1,0 |  |
| #196 | 0,0: 704/0/0; 1,0 |  |
| #197 | 0,0: 705/0/0; 1,0 |  |
| #198 | 0,0: 706/0/0; 1,0 |  |
| #199 | 0,0: 707/0/0; 1,0 |  |
| #200 | 0,0: 708/0/0; 1,0 |  |
| #201 | 0,0: 709/0/0; 1,0 |  |
| #202 | 0,0: b/0/710; 0,0 |  |
| #203 | 0,0: bg/0/711; 0,1 |  |
| #204 | 0,0: bg/0/712; 0,1 |  |
| #205 | 0,0: bg/0/713; 0,1 |  |
| #206 | 0,0: b/0/714; 0,0 |  |
| #207 | 0,0: b/0/715; 0,0 |  |
| #208 | 0,0: b/0/716; 0,0 |  |
| #209 | 0,0: b/0/0; 0,0 | actor 26 |
| #210 | -1,-1: 191/0/0; 0,1<br>0,-1: 192/0/0; 0,1<br>-1,0: 195/0/0; 0,0<br>0,0: 196/0/0; 0,0 |  |
| #211 | 0,0: bg/0/-1; 0,0 |  |
| #212 | 0,0: b/0/0; 0,0 | actor 44 |
| #213 | 0,0: bg/721/0; 0,1 |  |
| #214 | 0,0: bg/722/0; 0,1 |  |
| #215 | 0,0: bg/723/0; 0,1 |  |
| #216 | -1,0: 268/0/0; 0,1<br>0,0: 269/0/0; 0,1 |  |
| #217 | 0,0: b/725/0; 0,0 |  |
| #218 | 0,0: bg/726/0; 0,1 |  |
| #219 | 0,0: bg/727/0; 0,1 |  |
| #220 | 0,0: bg/728/0; 0,1 |  |
| #221 | 0,0: b/729/0; 0,0 |  |
| #222 | 0,0: bg/730/0; 0,1 |  |
| #223 | 0,0: 201/0/0; 0,1 |  |
| #224 | 0,0: 202/0/0; 0,1 |  |
| #225 | 0,0: 203/0/0; 0,1 |  |
| #226 | 0,0: 205/0/0; 0,0 |  |
| #227 | 0,0: 206/0/0; 0,0 |  |
| #228 | 0,0: 207/0/0; 0,0 |  |
| #229 | 0,0: 758/0/0; 1,0 |  |
| #230 | 0,0: b/0/759; 0,0 |  |
| #231 | 0,0: b/0/760; 0,0 |  |
| #232 | 0,0: b/0/761; 0,0 |  |
| #233 | 0,0: b/0/762; 0,0 |  |
| #234 | 0,0: b/0/763; 0,0 |  |
| #235 | 0,0: b/0/764; 0,0 |  |
| #236 | 0,0: b/0/765; 0,0 |  |
| #237 | -1,0: 199/0/0; 0,1<br>0,0: 200/0/0; 0,1 |  |
| #238 | -2,0: b/264/0; 0,1<br>-1,0: b/265/0; 0,1<br>0,0: b/266/0; 0,1 |  |
| #239 | 0,-1: b/263/0; 0,1<br>0,0: b/267/0; 0,0 |  |
| #241 | 0,0: 775/0/0; 1,0 |  |
| #242 | 0,0: 776/0/0; 1,0 |  |
| #243 | 0,0: 777/0/0; 1,0 |  |
| #244 | 0,0: 778/0/0; 1,0 |  |
| #245 | 0,0: 779/0/0; 1,0 |  |
| #246 | 0,0: 780/0/0; 1,0 |  |
| #247 | 0,0: 781/0/0; 1,0 |  |
| #248 | 0,0: 782/0/0; 1,0 |  |
| #249 | 0,0: 783/0/0; 1,0 |  |
| #250 | 0,0: 784/0/0; 1,0 |  |
| #251 | 0,0: 785/0/0; 1,0 |  |
| #252 | 0,0: 786/0/0; 1,0 |  |
| #253 | 0,0: bg/787/0; 1,0 |  |
| #254 | 0,0: 788/0/0; 1,0 |  |

### Island writes

These supplement the shared space/Y rules. Repeated conditional writes
in M/N/O/P/l select the completed/uncompleted or locked/unlocked branch,
rather than all executing. The two w dispatches both execute.

| Decimal byte / printable label | Cell writes / conditional alternatives |
|---|---|
| #48 `0` | 0,0: 525/0/0; 0,0 |
| #65 `A` | 0,0: 501/0/0; 0,0 |
| #66 `B` | 0,0: 502/0/0; 1,0 |
| #67 `C` | 0,0: 503/0/0; 1,0 |
| #68 `D` | 0,0: 504/0/0; 1,0 |
| #69 `E` | 0,0: 505/0/0; 1,0 |
| #70 `F` | 0,0: 506/0/0; 1,0 |
| #71 `G` | 0,0: 507/0/0; 1,0 |
| #72 `H` | 0,0: bg/0/0; 0,0 |
| #73 `I` | 0,0: bg/0/0; 0,0 |
| #74 `J` | 0,0: 661/0/0; 0,0 |
| #75 `K` | 0,0: bg/0/0; 0,0 |
| #76 `L` | 0,0: bg/0/0; 0,0 |
| #77 `M` | 0,0: entrance+2/0/517; 0,0<br>0,0: entrance+2/0/513; 0,0 |
| #78 `N` | 0,0: entrance+2/0/518; 0,0<br>0,0: entrance+2/0/514; 0,0 |
| #79 `O` | 0,0: entrance+2/0/519; 0,0<br>0,0: entrance+2/0/515; 0,0 |
| #80 `P` | 0,0: entrance+2/0/520; 0,0<br>0,0: entrance+2/0/516; 0,0 |
| #81 `Q` | 0,0: 517/0/0; 0,0 |
| #82 `R` | 0,0: 518/0/0; 0,0 |
| #83 `S` | 0,0: 519/0/0; 0,0 |
| #84 `T` | 0,0: 520/0/0; 0,0 |
| #85 `U` | 0,0: 521/0/0; 1,0 |
| #86 `V` | 0,0: 522/0/0; 0,0 |
| #87 `W` | 0,0: 523/0/0; 0,0 |
| #88 `X` | 0,0: 524/0/0; 0,0 |
| #90 `Z` | 0,0: 526/0/0; 0,0 |
| #97 `a` | 0,0: 527/0/0; 1,0 |
| #98 `b` | 0,0: 528/0/0; 0,0 |
| #99 `c` | 0,0: 529/0/0; 0,0 |
| #100 `d` | 0,0: 530/0/0; 0,0 |
| #101 `e` | 0,0: 531/0/0; 0,0 |
| #102 `f` | 0,0: 532/0/0; 1,0 |
| #103 `g` | 0,0: 533/0/0; 1,0 |
| #104 `h` | 0,0: 534/0/0; 0,0 |
| #105 `i` | 0,0: 535/0/0; 0,0 |
| #106 `j` | 0,0: 536/0/0; 0,0 |
| #107 `k` | 0,0: 537/0/0; 0,0 |
| #108 `l` | 0,0: 508/0/0; 1,0<br>0,0: bg/0/0; 0,0 |
| #109 `m` | 0,0: bg/0/665; 0,0 |
| #110 `n` | 0,0: bg/0/666; 0,0 |
| #111 `o` | 0,0: bg/671/0; 0,1 |
| #112 `p` | 0,0: bg/672/0; 0,1 |
| #113 `q` | 0,0: bg/673/0; 0,1 |
| #114 `r` | 0,0: bg/674/0; 0,1 |
| #115 `s` | 0,0: 683/0/0; 0,0 |
| #116 `t` | 0,0: bg/0/684; 0,0 |
| #117 `u` | 0,0: bg/0/685; 0,0 |
| #118 `v` | 0,0: bg/0/686; 0,0 |
| #119 `w` | 0,0: bg/0/687; 0,0<br>0,-1: b/0/179; 1,0<br>0,0: b/0/183; 0,0 |
| #120 `x` | 0,0: bg/0/688; 0,0 |
| #121 `y` | 0,0: bg/0/689; 0,0 |
| #122 `z` | 0,0: 690/0/0; 0,0 |
