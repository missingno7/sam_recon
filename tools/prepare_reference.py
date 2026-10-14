"""Prepare/verify TP5 episode builds for differential checks only.

The normal port build reads committed placement metadata and never calls this
tool. DATA offsets still come from the translator, never a MAP. All build output
stays inside this snapshot, including when the canonical verifier is imported.
"""
import json
import sys
from pathlib import Path
from pas2c_paths import ROOT, WORK

sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / 'tools'))
import verify
# Restore staging-module priority after importing the canonical check helpers.
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Canonical compare may populate an oracle cache on a clean checkout. Keep that
# optional materialization here too, never in the canonical build directory.
verify.oracle.OUT = WORK / 'build/oracle'
for episode in ('sam1','sam2','sam3'):
    work = (WORK / 'build/reference' / episode).resolve()
    assert WORK.resolve() in work.parents and work != WORK.resolve()
    if not (work / 'SAM.EXE').exists() or not (work / 'SAM.MAP').exists():
        verify.build(ROOT / 'game', episode, work)
    result = verify.compare(episode, work / 'SAM.EXE')
    (work.parent / (episode+'-check.json')).write_text(json.dumps(result, indent=2) + '\n')
    print(episode,json.dumps(result, indent=2))
    if not result['ok']:
        raise SystemExit(1)
