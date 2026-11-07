#!/usr/bin/env python3
"""Deterministic documentation governance; registry uses the JSON subset of YAML."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from urllib.parse import unquote

class Blocked(Exception):
    pass

class Invalid(Exception):
    pass

def pairs(items):
    result = {}
    for k, v in items:
        if k in result:
            raise Invalid('duplicate key: ' + k)
        result[k] = v
    return result

def read_json(path):
    return json.loads(Path(path).read_text(), object_pairs_hook=pairs)

def git(root, *args):
    p = subprocess.run(['git', '-C', str(root), *args], capture_output=True)
    if p.returncode:
        raise Blocked('Git prerequisite unavailable: ' + ' '.join(args[:2]))
    return p.stdout

def files(root):
    return sorted(set(p for p in git(root, 'ls-files', '-z', '--cached', '--others', '--exclude-standard').decode().split('\0') if p and (root / p).is_file()))

def match(pattern, path):
    """POSIX glob, with **/ matching zero or more complete directories."""
    out = ''; i = 0
    while i < len(pattern):
        if pattern[i:i+3] == '**/':
            out += '(?:.*/)?'; i += 3
        elif pattern[i:i+2] == '**':
            out += '.*'; i += 2
        elif pattern[i] == '*':
            out += '[^/]*'; i += 1
        elif pattern[i] == '?':
            out += '[^/]'; i += 1
        else:
            out += re.escape(pattern[i]); i += 1
    return re.fullmatch(out, path) is not None

def registry(root):
    r = read_json(root / 'docs/ai/registry.yaml')
    try:
        import jsonschema
    except ImportError as e:
        raise Blocked('Run make docs-setup; jsonschema is required') from e
    try:
        jsonschema.validate(r, read_json(root / 'docs/ai/registry.schema.json'))
    except jsonschema.ValidationError as e:
        raise Invalid('Registry schema: '+e.message) from e
    return r

def digest(root):
    h = hashlib.sha256()
    for p in files(root):
        h.update(p.encode()); h.update(b'\0'); h.update((root / p).read_bytes())
    return h.hexdigest()

def subject(root, head=None):
    return {'commit': git(root, 'rev-parse', head or 'HEAD').decode().strip(),
            'source_digest': digest(root), 'check_run_id': os.getenv('GITHUB_RUN_ID')}

def diff_paths(root, base, head=None, worktree=False):
    git(root, 'rev-parse', '--verify', base + '^{commit}')
    args = ['diff', '--name-status', '-z', '--no-renames', base]
    if not worktree:
        if not head:
            raise Invalid('--head or --worktree is required')
        git(root, 'rev-parse', '--verify', head + '^{commit}')
        args.append(head)
    tokens = git(root, *args).decode().split('\0'); paths = []
    for i in range(0, len(tokens)-1, 2):
        paths.append({'status': tokens[i], 'path': tokens[i+1]})
    if worktree:
        tracked = {x['path'] for x in paths}
        paths.extend({'status': 'A', 'path': p} for p in git(root, 'ls-files', '--others', '--exclude-standard', '-z').decode().split('\0') if p and p not in tracked)
    return sorted(paths, key=lambda x: x['path'])

def route(r, paths, intent=''):
    owners = {}; domains = set(); findings = []
    for p in paths:
        cs = [c for c in r['components'] if any(match(g, p) for g in c['owned_paths'])]
        if len(cs) != 1:
            findings.append('ownership: ' + p); continue
        owners[p] = cs[0]['id']
        ds = [d['id'] for d in r['domains'] if any(match(g, p) for g in d['path_patterns'])]
        domains.update(ds)
        if not any(x != cs[0]['fallback_domain'] for x in ds) and cs[0]['id'] != 'governance' and not is_document_change(p):
            findings.append('unclassified_source_path: ' + p)
    for d in r['domains']:
        if any(t.lower() in intent.lower() for t in d['semantic_triggers']):
            domains.add(d['id'])
    for t in r['task_intents']:
        if t['id'] == intent:
            domains.update(t['domains'])
    changed_contracts = {d['id'] for d in r['documents']
                         if d['type'] == 'contract' and d['path'] in paths}
    for d in r['domains']:
        if changed_contracts.intersection(d['contracts']):
            domains.add(d['id'])
    reads = set(); contracts = set(); checks = {'docs-integrity', 'docs-tests'}
    for t in r['task_intents']:
        if t['id'] == intent:
            reads.update(t['required_reads']); checks.update(t['checks'])
    for d in r['domains']:
        if d['id'] in domains:
            reads.update(d['required_reads']); contracts.update(d['contracts']); checks.update(d['checks'])
    # Contracts have cross-component consumers; retain all their mandatory reads.
    for d in r['domains']:
        if set(d['contracts']) & contracts:
            reads.update(d['required_reads'])
    reads.update(contracts)
    return {'owners': owners, 'domains': sorted(domains), 'required_reads': sorted(reads),
            'contracts': sorted(contracts), 'required_checks': sorted(checks), 'findings': sorted(findings)}

def impact(root, r, base, head, worktree, intent=''):
    changes = diff_paths(root, base, head, worktree)
    now = route(r, [x['path'] for x in changes], intent)
    try:
        old = json.loads(git(root, 'show', base + ':docs/ai/registry.yaml'), object_pairs_hook=pairs)
    except Blocked:
        old = None  # Initial installation: baseline legitimately has no registry.
    if old:
        old_docs={x['id']:x for x in old['documents']}
        for doc in r['documents']:
            if doc['id'] in old_docs and old_docs[doc['id']]['status']=='active' and doc['status']=='draft':
                now['findings'].append('invalid lifecycle transition active->draft: '+doc['id'])
        prior = route(old, [x['path'] for x in changes], intent)
        # A newly classified source resolves an old fallback-only finding. Baseline
        # contracts and checks are still unioned below, including removed domains.
        prior['findings'] = [f for f in prior['findings'] if not (
            f.startswith('unclassified_source_path: ') and
            f.removeprefix('unclassified_source_path: ') in now['owners'] and
            f not in now['findings'])]
        # A removed path belongs to the baseline; an added path belongs to the candidate.
        # Keep baseline domain obligations, including matching domains for added paths.
        removed = {x['path'] for x in changes if x['status'] == 'D'}
        added = {x['path'] for x in changes if x['status'] == 'A'}
        now['findings'] = [f for f in now['findings'] if not any(
            f == 'ownership: ' + p and p in prior['owners'] for p in removed)]
        prior['findings'] = [f for f in prior['findings'] if not any(
            f == 'ownership: ' + p and p in now['owners'] for p in added)]
        for p in removed:
            if p in prior['owners']: now['owners'][p] = prior['owners'][p]
        for k in ['domains', 'required_reads', 'contracts', 'required_checks', 'findings']:
            now[k] = sorted(set(now[k]) | set(prior[k]))
    now['changes'] = changes
    # Documentation descriptions do not execute the described application behavior.
    technical = [x['path'] for x in changes if not is_document_change(x['path'])]
    now['technical_paths'] = technical
    selected = route(r, technical)['required_checks']
    if old:
        selected = sorted(set(selected) | set(route(old, technical)['required_checks']))
    now['required_checks'] = sorted(set(selected) | {'docs-integrity','docs-tests','fixture-equality'})
    return now

def is_document_change(p):
    return (p.endswith('.md') or p.startswith(('docs/', 'docs/tools/', '.claude/')) or
            p in ['Makefile', '.gitignore'] or
            (p.endswith(('.yml', '.yaml')) and '/.github/workflows/' in '/' + p))

def clean_markdown(s):
    return re.sub(r'(?ms)^\s*(`{3,}|~{3,})[^\n]*\n.*?^\s*\1\s*$', '', s)

def slugs(text):
    counts = {}; result = set()
    for h in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', clean_markdown(text), re.M):
        s = re.sub(r'[^\w\-\s]', '', h.lower()).strip().replace(' ', '-')
        n = counts.get(s, 0); counts[s] = n+1; result.add(s + ('-' + str(n) if n else ''))
    return result

def links(text):
    text = clean_markdown(text)
    inline = re.findall(r'(?<!!)\[[^\]\n]+\]\(([^\s)]+)(?:\s+[^)]*)?\)', text)
    defs = dict(re.findall(r'^\s*\[([^\]]+)\]:\s*(\S+)', text, re.M))
    used = re.findall(r'(?<!!)\[([^\]]+)\]\[([^\]]*)\]', text)
    for label, ref in used:
        key = ref or label
        inline.append(defs.get(key, '__missing_reference__'+key))
    return [x.strip('<>') for x in inline]

def authority_findings(documents):
    ids={x['id']:x for x in documents}; findings=[]
    for kind in ['supersession','mandatory']:
        graph={x:[] for x in ids}
        for doc in documents:
            if kind=='mandatory':
                for ref in doc.get('mandatory_reads',[]):
                    if ref not in ids or ids[ref]['status']!='active': findings.append('non-active authority read: '+ref)
                    if ref in ids:graph[doc['id']].append(ref)
            else:
                for ref in doc.get('superseded_by',[]):
                    if ref not in ids:findings.append('unknown successor: '+ref)
                    else:graph[doc['id']].append(ref)
                for ref in doc.get('supersedes',[]):
                    if ref not in ids:findings.append('unknown predecessor: '+ref)
                    else:graph[ref].append(doc['id'])
        done=set(); visiting=set()
        def visit(node):
            if node in visiting: return True
            if node in done:return False
            visiting.add(node)
            if any(visit(ref) for ref in graph[node]):return True
            visiting.remove(node);done.add(node);return False
        if any(visit(node) for node in graph if node not in done):findings.append(kind+' cycle')
    return findings

def rendered_index(r):
    lines = ['# Technical index', '',
             'Generated from registry.yaml by `make docs-generate`.', '',
             'Read the [root policy](../../AGENTS.md), then select affected domains below.',
             '[Shared engineering](engineering.md) covers common code and contribution rules.',
             '[Maintenance](workflows/docs-maintenance.md) covers records, tooling and verification.',
             '[Known gaps](KNOWN_GAPS.md) lists unfinished controls. [System map](../map.md) explains architecture.', '',
             '| Domain | Required reads | Checks |', '| --- | --- | --- |']
    docs = {d['id']: d for d in r['documents']}
    for d in sorted(r['domains'], key=lambda d: d['id']):
        refs = ', '.join('['+i+']('+os.path.relpath(docs[i]['path'], 'docs/ai')+')' for i in sorted(set(d['required_reads']+d['contracts'])))
        lines.append('| '+d['id']+' | '+refs+' | '+', '.join(sorted(d['checks']))+' |')
    lines += ['', '[Task records](changes/active/) contain the current scope and check results.']
    return '\n'.join(lines).rstrip()+'\n'

def fixture_findings(root):
    a = root/'tauapi-be/pkg/billingexpr/testdata/frontend_simulation.json'
    b = root/'tauapi-fe/testdata/contracts/frontend_simulation.json'
    findings = [] if a.read_bytes() == b.read_bytes() else ['billing fixture snapshot differs']
    local = read_json(root/'docs/ai/contracts/billing-fixture.json')
    if local['sha256'] != hashlib.sha256(a.read_bytes()).hexdigest(): findings.append('local billing fixture revision/hash differs')
    return findings

def route_findings(root):
    c = read_json(root/'tauapi-ops/ROUTE_CONTRACT.json')['frontend_pages']
    found = []
    for p in (root/'tauapi-fe/src/routes').rglob('*.tsx'):
        for route_path in re.findall(r'createFileRoute\([\'\"]([^\'\"]+)', p.read_text()):
            parts = [x for x in route_path.split('/') if x and not x.startswith(('_', '('))]
            route_path = '/' + '/'.join(parts)
            first = route_path.split('/$')[0].rstrip('/') or '/'
            if first not in c['exact'] and not any(first == x or first.startswith(x+'/') for x in c['prefix']):
                found.append('unregistered literal frontend route: '+str(p.relative_to(root))+': '+route_path)
    return sorted(found)

def check(root, r):
    findings = []; ids = {}; docpaths = set()
    checks = {x['id'] for x in r['checks']}; areas = {x['id'] for x in r['components']}
    for d in r['documents']:
        if d['id'] in ids: findings.append('duplicate document ID: '+d['id'])
        ids[d['id']] = d; docpaths.add(d['path'])
        if d['owner_area'] not in areas: findings.append('unknown owner: '+d['id'])
        p = root/d['path']
        if not p.is_file(): findings.append('missing document: '+d['path']); continue
        for source in d['source_paths']:
            if not (root/source).exists(): findings.append('missing source: '+source)
        for x in d['checks']:
            if x not in checks: findings.append('unknown check: '+x)
        if d['status'] != 'active': continue
        text = p.read_text()
        if len(text.strip()) < 25: findings.append('empty active document: '+d['path'])
        for link in links(text):
            if re.match(r'^(https?:|mailto:|app:)', link): continue
            path, _, anchor = unquote(link).partition('#')
            target = (p.parent/path).resolve() if path else p
            if not target.is_relative_to(root.resolve()) or not target.exists():
                findings.append('broken link: '+d['path']+' -> '+link)
            elif anchor and target.suffix == '.md' and anchor not in slugs(target.read_text()):
                findings.append('broken anchor: '+d['path']+' -> '+link)
        prose = re.sub(r'`[^`]*`', '', clean_markdown(text))
        if d['path'] == 'tauapi-be/docs/plugin-api/v1.md':
            prose = '\n'.join('|'.join(line.split('|')[:-2])+'|' if line.startswith('|') else line for line in prose.splitlines())
        if d['audience'] == 'ai' and re.search(r'[\u4e00-\u9fff]', prose):
            findings.append('English prose contains CJK: '+d['path'])
        if d['audience'] == 'human' and not re.search(r'[\u4e00-\u9fff]', prose):
            findings.append('Chinese prose missing: '+d['path'])
    for doc in r['documents']:
        for ref in doc['related_docs']:
            if ref not in ids: findings.append('unknown document reference: '+ref)
    for collection in ['components','domains','checks','task_intents']:
        seen = set()
        for item in r[collection]:
            if item['id'] in seen: findings.append('duplicate '+collection+' ID: '+item['id'])
            seen.add(item['id'])
    for d in r['domains']:
        for i in d['required_reads'] + d['contracts']:
            if i not in ids or ids[i]['status'] != 'active': findings.append('non-active required read: '+i)
        for c in d['checks']:
            if c not in checks: findings.append('unknown check: '+c)
    for c in r['components']:
        for k in ['policy', 'index']:
            if c[k] not in ids: findings.append('missing component entry: '+c[k])
    for c in r['checks']:
        if not (root/c['cwd']).is_dir(): findings.append('invalid check cwd: '+c['id'])
        if c['runner'] not in RUNNERS: findings.append('unsupported runner: '+c['runner'])
        elif c['cwd'] != RUNNERS[c['runner']][1] or c['prerequisites'] != RUNNERS[c['runner']][2]: findings.append('runner declaration mismatch: '+c['id'])
    findings += authority_findings(r['documents'])
    allpaths = files(root)
    for p in allpaths:
        if p.endswith('.md') and p not in docpaths:
            findings.append('unregistered document: '+p)
        if '/' not in p and p.lower().endswith('.md') and p not in ['AGENTS.md', 'README.md']:
            findings.append('unexpected root document: '+p)
        cs = [c for c in r['components'] if any(match(g,p) for g in c['owned_paths'])]
        if len(cs) != 1: findings.append('ownership: '+p)
    for doc in r['documents']:
        if doc['provenance'] == 'first_party' and doc['audience'] == 'human' and doc['path'] not in ['README.md', 'docs/map.md', 'docs/CHANGELOG.md']:
            findings.append('unexpected Chinese guide: '+doc['path'])
    for g in r['generated']:
        if not (root/g['generator']).exists(): findings.append('missing generator: '+g['generator'])
        if (root/g['path']).read_text() != rendered_index(r): findings.append('stale generated navigation: '+g['path'])
    findings += fixture_findings(root) + route_findings(root)
    return sorted(set(findings))

# Literal supported runner definitions; no execution of registry/Markdown commands.
RUNNERS = {
 'docs-integrity': (['{python}','docs/tools/docsctl.py','check','--format','json'], '.', [], 120),
 'docs-tests': (['{python}','-m','unittest','discover','-s','docs/tools/tests','-v'], '.', [], 120),
 'fixture-equality': (['{python}','docs/tools/docsctl.py','fixture-check'], '.', [], 30),
 'backend-tests': (['make','test'], 'tauapi-be', [], 1800),
 'backend-build': (['make','build'], 'tauapi-be', [], 900),
 'frontend-typecheck': (['bun','run','typecheck'], 'tauapi-fe', [], 600),
 'frontend-tests': (['bun','run','test'], 'tauapi-fe', [], 1200),
 'frontend-build': (['bun','run','build'], 'tauapi-fe', [], 900),
 'frontend-lint': (['{python}','docs/tools/docsctl.py','lint-check'], '.', [], 600),
 'plugins-lint': (['make','lint-plugins'], 'tauapi-be', [], 600),
 'plugins-format': (['make','format-plugins-check'], 'tauapi-be', [], 600),
 'billing-go': (['go','test','./pkg/billingexpr','-run','TestFrontendSimulationContract'], 'tauapi-be', [], 600),
 'billing-fe': (['bun','run','test','src/features/pricing/lib/__tests__/billing-expression.test.ts'], 'tauapi-fe', [], 600),
 'database-matrix': (['go','test','-v','./model/...'], 'tauapi-be', ['TEST_MYSQL_DSN','TEST_POSTGRES_DSN','DOCS_DB_UPGRADE_EVIDENCE'], 1800),
 'route-analysis': (['{python}','tauapi-ops/scripts/generate-nginx.py','--contract','tauapi-ops/ROUTE_CONTRACT.json','--mode','live','--check-plugins','tauapi-be/plugins/tasks'], '.', [], 120),
 'isolated-builds': (['bash','tauapi-ops/scripts/verify-independent-builds.sh','all'], '.', [], 3600),
 'libraries-build': (['{python}','docs/tools/docsctl.py','libraries-build'], '.', [], 1200),
 'shell-syntax': (['bash','-n','tauapi-ops/scripts/verify-independent-builds.sh'], '.', [], 30),
}

def dispositions(root, record, imp):
    r = read_json(root/record)
    import jsonschema
    try:
        jsonschema.validate(r, read_json(root/'docs/ai/schemas/change-v1.schema.json'))
    except jsonschema.ValidationError as e:
        raise Invalid('Change schema: '+e.message) from e
    findings = []
    for c in imp['contracts']:
        x = r['dispositions'].get(c)
        if not x or x['status'] not in ['updated','reviewed_unchanged','not_applicable'] or not x['reason'] or not x['evidence']:
            findings.append('missing contract disposition: '+c)
    return findings

def evidence_findings(root, path, expected, required):
    if not path.is_file(): return ['missing required report: '+str(path)]
    try:
        import jsonschema
        result=read_json(path)
        jsonschema.validate(result, read_json(root/'docs/ai/schemas/check-result-v1.schema.json'))
    except Exception: return ['malformed required report: '+str(path)]
    if result['check_id'] != required or result['subject'] != expected:
        return ['wrong report subject/check: '+str(path)]
    if result['status'] != 'passed' or result['exit_code'] != 0 or not result['command'] or result['required_skips']:
        return ['unsuccessful required report: '+str(path)]
    if not result['started_at'] or not result['finished_at'] or not result['evidence_refs']:
        return ['incomplete required evidence: '+str(path)]
    return []

def execute(root, ids, out, subj):
    out.mkdir(parents=True, exist_ok=True); results=[]
    tool_versions={'python':sys.version.split()[0]}
    for tool, option in [('go','version'),('bun','--version'),('make','--version')]:
        if shutil.which(tool):
            v=subprocess.run([tool,option],capture_output=True,text=True,timeout=10)
            if v.returncode==0: tool_versions[tool]=v.stdout.splitlines()[0]
    for cid in ids:
        argv,cwd,envs,timeout = RUNNERS[cid]
        argv=[sys.executable if a=='{python}' else a for a in argv]
        start=dt.datetime.now(dt.timezone.utc).isoformat(); status='not_run'; code=None; log=''; blocker=None
        missing=[e for e in envs if not os.getenv(e)]
        if missing or not shutil.which(argv[0]):
            status='blocked'; blocker='Missing prerequisites: '+', '.join(missing or [argv[0]])
        else:
            try:
                p=subprocess.run(argv,cwd=root/cwd,env={**os.environ,'GOWORK':'off','TAUAPI_VERIFY_REV':subj['commit']},capture_output=True,text=True,timeout=timeout)
                log=p.stdout+p.stderr
                for name in ['TEST_MYSQL_DSN','TEST_POSTGRES_DSN']:
                    if os.getenv(name): log=log.replace(os.environ[name], '<redacted:'+name+'>')
                code=p.returncode; status='passed' if code==0 else 'failed'
                if cid=='database-matrix' and ('--- SKIP:' in log or 'SKIP' in log): status='blocked'; blocker='Required database tests skipped'
                # Never accept an arbitrary path as proof of upgrade/matrix execution.
                if cid=='database-matrix':
                    proof=read_json(os.environ['DOCS_DB_UPGRADE_EVIDENCE'])
                    if proof.get('commit')!=subj['commit'] or not all(proof.get(k) for k in ['fresh','upgrade','repeat_start','data_constraints','engine_versions','log_database']):
                        status='blocked'; blocker='Missing candidate-bound real database lifecycle evidence'
            except subprocess.TimeoutExpired:
                status='blocked'; blocker='Runner timeout'
            except (OSError,ValueError) as e:
                status='blocked'; blocker=type(e).__name__
        logpath=out/(cid+'.log'); logpath.write_text(log)
        result={'schema_version':1,'check_id':cid,'required':True,'subject':subj,'working_directory':cwd,'command':argv,
                'tool_versions':tool_versions,'environment_class':'isolated_ci' if os.getenv('CI') else 'local_worktree',
                'started_at':start,'finished_at':dt.datetime.now(dt.timezone.utc).isoformat(),'exit_code':code,'status':status,
                'required_skips': ['database skip'] if cid=='database-matrix' and 'SKIP' in log else [],'findings':[], 'evidence_refs':[str(logpath)],'blocker':blocker}
        (out/(cid+'.json')).write_text(json.dumps(result,indent=2)+'\n'); results.append(result)
    return results

def lint_findings(root):
    baseline=read_json(root/'docs/tools/frontend-lint-baseline.json')
    version=subprocess.run(['bun','run','--silent','lint','--version'],cwd=root/'tauapi-fe',capture_output=True,text=True)
    if baseline['version'] not in version.stdout: return ['Lint version differs from reviewed baseline']
    result=subprocess.run(['bun','run','lint','--format','json'],cwd=root/'tauapi-fe',capture_output=True,text=True)
    try: diagnostics=json.loads(result.stdout)['diagnostics']
    except (ValueError,KeyError): return ['Lint runner did not produce diagnostic JSON']
    if result.returncode not in [0,1]: return ['Lint runner failed internally']
    actual=[]
    for x in diagnostics:
        label=x['labels'][0]['span'] if x['labels'] else {'line':0,'column':0}
        actual.append({'rule':x['code'],'file':x['filename'],'severity':x['severity'],'line':label['line'],'column':label['column'],'message_sha256':hashlib.sha256(x['message'].encode()).hexdigest()})
    encoded=lambda x: json.dumps(x,sort_keys=True)
    current={encoded(x) for x in actual}; old={encoded(x) for x in baseline['diagnostics']}
    return (['New lint diagnostic: '+x for x in sorted(current-old)] +
            ['Remove fixed lint baseline entry: '+x for x in sorted(old-current)])

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--root', type=Path)
    sub=ap.add_subparsers(dest='cmd',required=True)
    for name in ['inventory','check','audit','fixture-check','libraries-build','lint-check']:
        s=sub.add_parser(name);s.add_argument('--format',choices=['json','text'],default='text')
    s=sub.add_parser('generate');s.add_argument('--check',action='store_true');s.add_argument('--write',action='store_true')
    s=sub.add_parser('sync-fixture');s.add_argument('--write',action='store_true',required=True)
    s=sub.add_parser('route');s.add_argument('--path',action='append',default=[]);s.add_argument('--intent',default='');s.add_argument('--format',default='json')
    for name in ['impact','verify-change','run-checks']:
        s=sub.add_parser(name);s.add_argument('--base',required=True);s.add_argument('--head');s.add_argument('--worktree',action='store_true');s.add_argument('--format',default='json');s.add_argument('--intent',default='');s.add_argument('--record');s.add_argument('--evidence-dir',type=Path,default=Path('.docs-reports'))
    args=ap.parse_args();root=args.root or Path(git(Path.cwd(),'rev-parse','--show-toplevel').decode().strip());root=root.resolve()
    findings=[]; data={};r=registry(root)
    if args.cmd in ['check','audit']:
        findings=check(root,r)
        if args.cmd=='audit':
            data['known_gaps']=sorted(set(re.findall(r'GAP-\d+', (root/'docs/ai/KNOWN_GAPS.md').read_text())))
            data['external_enforcement']='not_run; inspect remote CI and merge settings separately'
    elif args.cmd=='inventory':data={'paths':files(root)}
    elif args.cmd=='route':data=route(r,args.path,args.intent);findings=data['findings']
    elif args.cmd=='generate':
        if args.write:
            (root/'docs/ai/INDEX.md').write_text(rendered_index(r))
        else:
            if (root/'docs/ai/INDEX.md').read_text()!=rendered_index(r):findings=['stale generated navigation; run make docs-generate']
    elif args.cmd=='lint-check':findings=lint_findings(root)
    elif args.cmd=='fixture-check':findings=fixture_findings(root)
    elif args.cmd=='sync-fixture':
        source=root/'tauapi-be/pkg/billingexpr/testdata/frontend_simulation.json'
        shutil.copyfile(source,root/'tauapi-fe/testdata/contracts/frontend_simulation.json')
        path=root/'docs/ai/contracts/billing-fixture.json'; local=read_json(path)
        new_hash=hashlib.sha256(source.read_bytes()).hexdigest()
        if local['sha256'] != new_hash:
            local['sha256']=new_hash; local['local_revision']+=1
            path.write_text(json.dumps(local,indent=2)+'\n')
    elif args.cmd=='libraries-build':
        for module in ['relaykit','tokenkit']:
            p=subprocess.run(['go','build','./...'],cwd=root/'tauapi-be'/module,env={**os.environ,'GOWORK':'off'},stdout=sys.stderr,stderr=sys.stderr)
            if p.returncode:findings.append('Independent module build failed: '+module)
    else:
        data=impact(root,r,args.base,args.head,args.worktree,args.intent);findings=data['findings'][:]
        if args.cmd in ['verify-change','run-checks']:
            if not args.record:raise Invalid('--record is required')
            if args.record == 'auto':
                records = [x['path'] for x in data['changes'] if x['path'].startswith('docs/ai/changes/') and x['path'].endswith('.json') and x['status'] != 'D']
                if len(records) != 1: raise Invalid('Expected one changed task JSON record; specify --record explicitly')
                args.record = records[0]
            findings+=dispositions(root,args.record,data)
            if not args.worktree:
                if git(root,'rev-parse','HEAD').decode().strip()!=git(root,'rev-parse',args.head).decode().strip() or git(root,'status','--porcelain','--untracked-files=all').strip():
                    raise Blocked('Revision execution requires a clean checkout of candidate HEAD')
            if args.cmd=='run-checks' and not findings:
                before=digest(root); data['results']=execute(root,data['required_checks'],args.evidence_dir,subject(root,args.head))
                if digest(root)!=before:findings.append('Inputs changed during validation')
                findings += ['required check '+x['check_id']+': '+x['status'] for x in data['results'] if x['status']!='passed']
    result={'schema_version':1,'check_id':args.cmd,'status':'failed' if findings else 'passed','subject':subject(root,getattr(args,'head',None)), 'scope':'repository','findings':sorted(set(findings)),**data}
    result['findings']=sorted(set(findings))
    if getattr(args,'format','text')=='json':print(json.dumps(result,ensure_ascii=False,sort_keys=True))
    else:print('\n'.join(result['findings']) if findings else args.cmd+': passed')
    if any(x.get('status') == 'blocked' for x in data.get('results', [])):
        return 3
    return 1 if findings else 0

if __name__=='__main__':
    try:sys.exit(main())
    except Blocked as e:
        print(json.dumps({'schema_version':1,'status':'blocked','blocker':str(e)}));sys.exit(3)
    except (Invalid,json.JSONDecodeError) as e:
        print(json.dumps({'schema_version':1,'status':'failed','findings':[str(e)]}));sys.exit(1)
    except Exception as e:
        print(json.dumps({'schema_version':1,'status':'failed','findings':['checker error: '+type(e).__name__+': '+str(e)]}));sys.exit(4)
