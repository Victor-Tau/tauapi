#!/usr/bin/env python3
"""Claude hook boundary: lightweight, read-only, one bounded Stop continuation."""
import json
from pathlib import Path
import subprocess
import sys


def main():
    try:
        payload=json.load(sys.stdin)
        if not isinstance(payload,dict):raise ValueError('expected object')
    except (ValueError,TypeError):
        print('Documentation hook: malformed event input',file=sys.stderr);return 1
    root=Path(__file__).resolve().parents[3]
    event=payload.get('hook_event_name')
    if event=='SessionStart':
        print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext':'Read docs/ai/INDEX.md and active change records. On resume reconcile Git diff and reload affected contracts.'}}));return 0
    if event!='Stop':
        print('Documentation hook: unsupported event',file=sys.stderr);return 1
    if payload.get('stop_hook_active'):
        print('Documentation hook: bounded continuation exhausted; report remaining blockers.',file=sys.stderr);return 0
    python=root/'.docs-venv/bin/python'
    if not python.exists():
        print('Documentation hook unavailable: run make docs-setup. CI remains required.',file=sys.stderr);return 1
    try:
        result=subprocess.run([str(python),str(root/'scripts/docs/docsctl.py'),'check','--format','json'],cwd=root,capture_output=True,text=True,timeout=30)
        report=json.loads(result.stdout)
    except (OSError,ValueError,subprocess.TimeoutExpired):
        print('Documentation hook checker error; no successful validation.',file=sys.stderr);return 1
    if result.returncode==1:
        print(json.dumps({'decision':'block','reason':'Documentation completion findings: '+ '; '.join(report.get('findings',[])[:5])+'. Fix or report blocked; continuation is bounded.'}));return 0
    if result.returncode:
        print('Documentation check blocked/internal failure; report honestly, rely on CI gate.',file=sys.stderr);return 1
    print('Documentation structure passed; verify task dispositions and technical evidence before handoff.',file=sys.stderr)
    return 0

if __name__=='__main__':sys.exit(main())
