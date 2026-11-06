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
        result=subprocess.run([str(python),str(root/'docs/tools/docsctl.py'),'check','--format','json'],cwd=root,capture_output=True,text=True,timeout=30)
        report=json.loads(result.stdout)
    except (OSError,ValueError,subprocess.TimeoutExpired):
        print('Documentation hook checker error; no successful validation.',file=sys.stderr);return 1
    if result.returncode==1:
        print(json.dumps({'decision':'block','reason':'Documentation completion findings: '+ '; '.join(report.get('findings',[])[:5])+'. Fix or report blocked; continuation is bounded.'}));return 0
    if result.returncode:
        print('Documentation check blocked/internal failure; report honestly, rely on CI gate.',file=sys.stderr);return 1
    try:
        changed=subprocess.run(['git','diff','--name-only','-z','HEAD'],cwd=root,capture_output=True,text=True,timeout=5)
        untracked=subprocess.run(['git','ls-files','--others','--exclude-standard','-z'],cwd=root,capture_output=True,text=True,timeout=5)
        if changed.returncode or untracked.returncode:raise ValueError('Git status unavailable')
        paths=set((changed.stdout+untracked.stdout).split('\0'))-{''}
        paths={x for x in paths if x!='文档管理体系构建指导.md'}
        records=sorted(x for x in paths if x.startswith('docs/ai/changes/') and x.endswith('.json') and (root/x).is_file())
        if paths:
            if len(records)!=1:
                print(json.dumps({'decision':'block','reason':'Changed work needs one updated task JSON record with explicit contract dispositions. Report a genuine blocker if it cannot be completed.'}));return 0
            task=json.loads((root/records[0]).read_text())
            result=subprocess.run([str(python),str(root/'docs/tools/docsctl.py'),'verify-change','--base',task['base_revision'],'--worktree','--record',records[0],'--format','json'],cwd=root,capture_output=True,text=True,timeout=20)
            if result.returncode==1:
                report=json.loads(result.stdout)
                print(json.dumps({'decision':'block','reason':'Missing task completion dispositions: '+ '; '.join(report.get('findings',[])[:5])}));return 0
            if result.returncode:raise ValueError('Impact verification unavailable')
    except (OSError,ValueError,KeyError,subprocess.TimeoutExpired):
        print('Documentation completion prerequisites unavailable; report blocked and rely on CI.',file=sys.stderr);return 1
    print('Documentation structure and available completion dispositions passed; technical CI evidence remains required.',file=sys.stderr)
    return 0

if __name__=='__main__':sys.exit(main())
