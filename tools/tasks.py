"""Routing, task packets, worker waves and intake.

    python tools/tasks.py plan                         route + rank every open routine (build/tasks/plan.json)
    python tools/tasks.py show [--route R] [--limit N]
    python tools/tasks.py wave N [--route PASCAL] [--unit u3] [--min-size A] [--max-size B] [--dry-run]
    python tools/tasks.py intake [PACKET_DIR ...]      re-verify every claim fresh; never promotes
    python tools/tasks.py release FUNCTION             drop a lease (dead or cancelled worker)

Routes: PASCAL (a routine the harness proves), ASM ({$L} object code: unit-level),
INIT (unit initialisation block: unit-level), MAIN (program body: unit-level),
LIBRARY (Borland runtime from TURBO.TPL), ACCEPTED.  layout/routine-kinds.json
(supervisor-curated) overrides the heuristics.

The supervisor owns canonical integration: intake prints the promote batch for
re-verified EQUAL candidates and never promotes.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import BUILD, EPISODES, EVIDENCE, LAYOUT, RECIPES, ROOT, atomic_json, load_json, rel  # noqa: E402
import context as ctxmod  # noqa: E402
import harness  # noqa: E402
import search  # noqa: E402

PLAN = BUILD / "tasks" / "plan.json"
LEASES = BUILD / "tasks" / "leases.json"
WORKERS = BUILD / "workers"
LIBRARY = ("crt", "dos", "sys")
RESULT_STATUSES = ("EQUAL_CANDIDATE", "PARTIAL_EQUAL", "NEAR", "BLOCKED")

REVIEW_PATTERNS = [
    (r"(?i)\bgoto\b", "goto: check whether structured statements produce the same code"),
    (r"(?i)\b(junk|pad|dummy|unused|filler)\w*\b", "possible steering variable"),
    (r"(?i)\bMem[WL]?\s*\[\s*\$?[0-9A-F]+\s*:", "absolute Mem[] access: fine for BIOS/VRAM, not for program data"),
    (r"(?i)\bPtr\s*\(\s*DSeg", "pointer built from DSeg: use the global"),
    (r"(?i)\$[0-9A-F]{3,4}\b", "hex literal: make sure it is a real constant, not an address of a global"),
]


def review_flags(text: str) -> list:
    t = harness._strip_comments(text)
    return [msg for rx, msg in REVIEW_PATTERNS if re.search(rx, t)]


def kinds() -> dict:
    p = LAYOUT / "routine-kinds.json"
    return load_json(p)["kinds"] if p.exists() else {}


def route_all() -> list:
    atlas = load_json(EVIDENCE / "atlas.json")
    accepted = {p.stem for p in RECIPES.glob("*.json")}
    cur = kinds()
    cen = load_json(BUILD / "census" / "sam1.json")
    inits = {(atlas["units"][[s["para"] for s in cen["segments"]].index(s)], o) for s, o in cen["inits"]}
    leases = load_json(LEASES) if LEASES.exists() else {}
    _, callers = ctxmod.call_graph(atlas, "sam1")
    import oracle
    img, _ = oracle.load_image("sam1")
    seg_start = {atlas["units"][k]: s["start"] for k, s in enumerate(cen["segments"])}
    rows = []
    for lid, r in atlas["routines"].items():
        e1 = r["episodes"].get("sam1") or next(iter(r["episodes"].values()))
        if lid in accepted:
            route = "ACCEPTED"
        elif lid in cur:
            route = cur[lid]
        elif r["unit"] in LIBRARY:
            route = "LIBRARY"
        elif (e1["unit"], e1["entry"]) in inits:
            route = "INIT"
        elif lid == "p_1148":
            route = "MAIN"
        elif "sam1" in r["episodes"] and img[seg_start[e1["unit"]] + e1["entry"]:][:3] != b"\x55\x89\xe5":
            route = "CHECK"     # no TP frame: assembly or frameless Pascal; curate in routine-kinds.json
        else:
            route = "PASCAL"
        rows.append({"function": lid, "unit": r["unit"], "size": r["size"], "route": route,
                     "episodes": sorted(r["episodes"]), "same_bytes": r["identical_bytes"],
                     "same_shape": r["identical_shape"], "callers": len(callers.get(lid, ())),
                     "lease": leases.get(lid)})
    # small, shape-identical, many callers first
    rows.sort(key=lambda x: (x["route"] != "PASCAL", not x["same_shape"], x["size"], -x["callers"]))
    return rows


def plan() -> dict:
    rows = route_all()
    doc = {"made_at": time.strftime("%Y-%m-%dT%H:%M:%S"), "targets": rows}
    atomic_json(PLAN, doc)
    return doc


RULES = """- Write only inside {dir}/.  Never modify src/, recipes/, layout/, evidence/, tools/, tests/,
  probes/, assets/; never run tools/promote.py or git commit.
- Every compile goes through `python tools/search.py {dir}/cand.pas --function {fid} --worker {worker}`
  (add `--asm` for a side-by-side listing, `--episodes sam1` to iterate faster on one episode).  Do not
  run TPC by hand.
- No {{$L}}, no `absolute`, nothing that manufactures equality.  inline() only for a single instruction
  Pascal cannot express (CLI = inline($FA), STI = inline($FB)); it is reviewed.
- Name game routines by logical id (u3_6ea9, p_0be5, ...) and globals d_XXXX by their SAM1 offset
  (layout/data.json); give globals their real Pascal types.  Borland names for System/Crt/Dos
  (ExitProc, TextAttr, ClrScr, GetIntVec, Port[], Mem[], ...) are used as is.
- One controlled change per attempt; say what you expect it to change.
- Stop at EQUAL in every episode the routine exists in; or when three hypotheses of one family give
  identical emission; or when you can name the concrete mechanism and the next discriminating
  experiment (that is a blocker).  A large routine or an ugly first diff is not a blocker.
- Time box: about {minutes} minutes.  Report what you have when it runs out.
"""

FACTS = """- Compiler: Turbo Pascal 5.0 (TPC), profile in layout/profiles.json; the harness decides near/far
  from the original (do not write {$F+}).  TP 5.0 has no `asm` statement and no `far`/`near` directives.
- TP 5.0 does not optimise: every statement compiles on its own, so the original listing reads almost
  line by line as Pascal.  Locals are allocated downwards from BP in declaration order (a function
  result first); `sub sp,N` gives the frame size; `ret N`/`retf N` gives the parameter bytes
  (parameters are pushed left to right, so the LAST parameter is nearest to BP: [bp+4] in a near
  routine, [bp+6] in a far one; VAR parameters and large value parameters are 4-byte far pointers).
- Boolean expressions are short-circuit ($B-).  `push cs; call near X` is a call to a FAR routine of
  the same unit; `call near X` a near one; `9A off:seg` a far call to another unit or the runtime.
- Strings: string literals used by a routine are emitted just before its entry (context shows them).
- Globals: the harness reproduces the original data segment exactly, so DS offsets must come out
  raw-identical; declare each global you use in {@decls} with its type, named d_<its real SAM1
  start offset>.  An array or record covering several referenced offsets is declared once.  Careful:
  TP folds the low bound into the displacement, so `a[i]` of `array[1..N] of T` (size s) shows
  as `[di + start - s]`: a displacement named in the context may lie BEFORE the array's start;
  name the global by its real start (any d_XXXX is accepted, not only names from layout/data.json).
"""

SCHEMA = """Write {dir}/result.json:
{{"task": "{task}", "function": "{fid}", "status": "EQUAL_CANDIDATE|PARTIAL_EQUAL|NEAR|BLOCKED",
 "candidate": "{dir}/cand.pas", "episodes_equal": ["sam1", ...],
 "first_diff": "for NEAR/BLOCKED: offset and what differs", "mechanism": "for BLOCKED: the concrete
 mechanism", "next_experiment": "for BLOCKED", "notes": "steering, doubts, anything the reviewer
 must know", "names": {{"{fid}": "a descriptive name if the behaviour is clear", "d_XXXX": "..."}}}}
Final reply: at most 15 lines (status, episodes, what remains)."""


def packet(fid: str, worker: str, minutes: int) -> Path:
    atlas = load_json(EVIDENCE / "atlas.json")
    r = atlas["routines"][fid]
    task = f"fn-{fid}"
    d = WORKERS / worker / task
    d.mkdir(parents=True, exist_ok=True)
    eps = sorted(r["episodes"])
    for ep in eps:
        lines = [f"{k:16s} {v}" for k, v in ctxmod.facts(fid, ep).items()] + [""] + ctxmod.annotate(fid, ep)
        (d / f"context-{ep}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
        if r["identical_shape"]:
            break
    (d / "skeleton.pas").write_text(ctxmod.skeleton(fid, eps[0]), encoding="latin-1")
    epnote = ""
    if not r["identical_shape"]:
        epnote = ("\n## Episode differences\nThis routine differs between episodes (see every context-*.txt).  "
                  "Write ONE source; put the differences in {$IFDEF SAM1} / {$IFDEF SAM2} / {$IFDEF SAM3} "
                  "blocks (search.py compiles each episode with /DSAMn), as small as the evidence allows.\n")
    rel_d = rel(d)
    prompt = f"""# Task {task}: recover `{fid}` as Turbo Pascal 5.0 source

Your name: {worker}

You are an independent worker in the sam_recon matching-decompilation project (Apogee's Secret
Agent, 1992; repository root {ROOT}).  Goal: Pascal source whose pinned Turbo Pascal 5.0 compilation,
inside the proof harness, is byte-for-byte identical to the original routine `{fid}` (unit
{r['unit']}, {r['size']} bytes) in every episode it exists in ({', '.join(eps)}), with all references
bound (callees by logical id, runtime routines by identity, segment relocations).

Read first: {rel_d}/context-*.txt (annotated original: facts, literal strings, listing with callee ids
and global names), {rel_d}/skeleton.pas (template), and accepted examples in src/routines/*.pas.
`python tools/context.py <id>` shows any other routine (e.g. a callee, to learn its parameters).
AGENTS.md explains the project rules.

## Rules
{RULES.format(dir=rel_d, fid=fid, worker=worker, minutes=minutes)}
## Compiler facts
{FACTS}{epnote}
## Candidate format
    {{@decls}}   type/const declarations, and the globals the routine uses (var d_XXXX: T; typed
               constants const d_XXXX: T = value;)
    {{@stubs}}   one header per called game routine: procedure u5_0f9b(X: Word); function ...;
    {{@body}}    the routine itself (nested routines inside it), named {fid}

## Result
{SCHEMA.format(dir=rel_d, task=task, fid=fid)}
"""
    (d / "PROMPT.md").write_text(prompt, encoding="utf-8")
    leases = load_json(LEASES) if LEASES.exists() else {}
    leases[fid] = {"worker": worker, "packet": rel_d, "time": time.strftime("%Y-%m-%dT%H:%M:%S")}
    atomic_json(LEASES, leases)
    return d


def wave(n: int, route: str, unit: str | None, lo: int, hi: int, dry: bool, model: str, effort: str,
         minutes: int) -> list:
    doc = plan()
    picks = [x for x in doc["targets"] if x["route"] == route and not x["lease"]
             and (unit is None or x["unit"] == unit) and lo <= x["size"] <= hi][:n]
    out = []
    for x in picks:
        worker = f"luna-{x['function']}"
        if dry:
            out.append({"function": x["function"], "size": x["size"]})
            continue
        d = packet(x["function"], worker, minutes)
        out.append({"function": x["function"], "worker": worker, "packet": rel(d),
                    "launch": f"python ~/.codex-dashboard/cx.py run -n {worker} -C {ROOT.as_posix()} "
                              f"-m {model} -e {effort} < {(d / 'PROMPT.md').as_posix()}"})
    return out


def intake(dirs: list) -> list:
    leases = load_json(LEASES) if LEASES.exists() else {}
    if not dirs:
        dirs = [ROOT / v["packet"] for v in leases.values()]
    out = []
    for d in map(Path, dirs):
        rp = d / "result.json"
        if not rp.exists():
            continue
        try:
            res = json.loads(rp.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as exc:
            out.append({"packet": rel(d), "error": f"result.json unreadable: {exc}"})
            continue
        fid = res.get("function")
        if (RECIPES / f"{fid}.json").exists():
            continue                # already accepted
        cand = ROOT / res.get("candidate", "") if res.get("candidate") else d / "cand.pas"
        row = {"function": fid, "packet": rel(d), "claimed": res.get("status"), "notes": res.get("notes", "")}
        if cand.exists():
            text = cand.read_text(encoding="latin-1")
            row["review"] = review_flags(text)
            _, options = search.profile_options(None)
            eq, other = [], {}
            for ep in EPISODES:
                r, _ = search.run_episode(text, fid, ep, options, fresh=True)
                if r.status == "MISSING":
                    continue
                if r.status == "EQUAL":
                    eq.append(ep)
                else:
                    other[ep] = r.short()
            row["verified_equal"] = eq
            row["not_equal"] = other
            row["candidate"] = rel(cand)
        out.append(row)
    atomic_json(BUILD / "tasks" / f"intake-{time.strftime('%Y%m%d-%H%M%S')}.json", out)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("plan")
    s = sub.add_parser("show")
    s.add_argument("--route")
    s.add_argument("--limit", type=int, default=40)
    w = sub.add_parser("wave")
    w.add_argument("n", type=int)
    w.add_argument("--route", default="PASCAL")
    w.add_argument("--unit")
    w.add_argument("--min-size", type=int, default=0)
    w.add_argument("--max-size", type=int, default=1 << 30)
    w.add_argument("--dry-run", action="store_true")
    w.add_argument("--model", default="gpt-6-luna")
    w.add_argument("--effort", default="xhigh")
    w.add_argument("--minutes", type=int, default=30)
    i = sub.add_parser("intake")
    i.add_argument("dirs", nargs="*")
    rl = sub.add_parser("release")
    rl.add_argument("function")
    a = ap.parse_args()
    if a.cmd == "plan":
        doc = plan()
        counts = {}
        for x in doc["targets"]:
            counts[x["route"]] = counts.get(x["route"], 0) + 1
        print(json.dumps(counts, indent=1))
    elif a.cmd == "show":
        for x in plan()["targets"]:
            if a.route and x["route"] != a.route:
                continue
            print(f"{x['function']:16s} {x['route']:8s} {x['size']:6d} B  shape {'=' if x['same_shape'] else '~'}  "
                  f"callers {x['callers']:2d}  {'leased ' + x['lease']['worker'] if x['lease'] else ''}")
            a.limit -= 1
            if a.limit <= 0:
                break
    elif a.cmd == "wave":
        for x in wave(a.n, a.route, a.unit, a.min_size, a.max_size, a.dry_run, a.model, a.effort, a.minutes):
            print(json.dumps(x))
    elif a.cmd == "intake":
        rows = intake(a.dirs)
        batch = []
        for r in rows:
            print(json.dumps(r, indent=1))
            if r.get("verified_equal"):
                batch.append(f"{r['function']} {r['candidate']}")
        if batch:
            p = BUILD / "tasks" / "promote-batch.txt"
            p.write_text("\n".join(batch) + "\n", encoding="utf-8")
            print(f"review, then: python tools/promote.py --batch {rel(p)}")
    elif a.cmd == "release":
        leases = load_json(LEASES) if LEASES.exists() else {}
        leases.pop(a.function, None)
        atomic_json(LEASES, leases)
    return 0


if __name__ == "__main__":
    sys.exit(main())
