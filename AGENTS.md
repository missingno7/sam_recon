# Agent rules (supervisor and workers)

## Roles

* **Supervisor** (one interactive session): plans waves, launches workers, runs
  intake, reviews and promotes, curates blockers, changes shared tools/layout,
  commits. Canonical source (`src/`), recipes, layout and evidence have exactly
  one writer, enforced by the canonical lock in `tools/promote.py`.
* **Workers** (independent agents, e.g. GPT-6 Luna xhigh via the codex-workers
  skill): each owns `build/workers/<worker>/<task>/` and nothing else.

## Worker rules

1. Write only inside your task directory. Never modify `src/`, `recipes/`,
   `layout/`, `evidence/`, `tools/`, `tests/`, `probes/`, `assets/`.
   Never run `tools/promote.py`, `git commit`, or delete lock files.
2. Every compile goes through `tools/search.py CAND.pas --function ID --worker NAME`.
   It builds the proof harness (exact original data segment, stub units) per
   episode, compares strictly and logs the attempt. Do not run TPC by hand.
3. No `inline(...)` machine code, no `{$L}`, no `absolute`, no byte emission,
   nothing that manufactures equality. Never alter the oracle or the tool pins.
4. One controlled change per attempt; say what you expect it to change.
5. Stop at EQUAL; or when three hypotheses of one family give identical
   emission; or when you can name the concrete mechanism and the next
   discriminating experiment (a blocker). A large routine is not a blocker.
6. Report steering (dummy variables that only force offsets) in `notes`.
7. Finish with `result.json` (schema in your PROMPT.md) and a reply of at most
   15 lines.

## Naming in candidate source

* Routines: logical ids `<unit>_<SAM1 entry offset>` (`p_0e33`, `u3_6ea9`);
  routines that only exist in SAM2/SAM3 are `<unit>_sam2_<offset>`.
* Globals: `d_XXXX`, the SAM1 DS offset (`layout/data.json` binds them per episode).
* Borland runtime: real names (`ExitProc`, `GetIntVec`, `Port[]`, `ClrScr`, ...).
* Semantic names come later through aliases curated by the supervisor.

## Candidate format

```
{@decls}     types, untyped constants, and the globals the routine uses with their types
{@stubs}     one header per called game routine (by logical id)
{@body}      the routine (nested routines inside it), named by its logical id
```

The harness decides near/far/interrupt from the original; same-unit callees
become forward-declared stubs in the harness program, other units' callees
interface procedures of stub units.

## Supervisor loop

```bash
python tools/tasks.py plan
python tools/tasks.py wave 4 --max-size 400       # packets + cx launch commands
# launch each printed command as its own background task
python tools/tasks.py intake                       # re-verifies every claim fresh; never promotes
# review: real types for globals, literals for text, no steering, structured control flow
python tools/promote.py --batch build/tasks/promote-batch.txt
python tools/validate.py --write-progress && git commit
```

Grow the wave only while compiles and intake keep up. When two workers report
the same mechanism, stop dispatching that family, fix it once (harness,
profile, tool), record the rule in `evidence/compiler-rules.json`, then
release the blocked tasks.
