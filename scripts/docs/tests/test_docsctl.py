"""Boundary tests for governance failures, impact unions and candidate evidence."""
import contextlib
import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('docsctl',ROOT/'scripts/docs/docsctl.py')
d=importlib.util.module_from_spec(spec);spec.loader.exec_module(d)

class DocumentationChecks(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        self.r=d.registry(ROOT)
        # Isolated document/source fixture, without application dependencies or credentials.
        for doc in self.r['documents']:
            p=self.root/doc['path'];p.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(ROOT/doc['path'],p)
        for doc in self.r['documents']:
            for source in doc['source_paths']:
                p=self.root/source
                if p.exists():continue
                p.parent.mkdir(parents=True,exist_ok=True)
                if (ROOT/source).is_dir():p.mkdir(exist_ok=True)
                else:p.write_bytes((ROOT/source).read_bytes())
        for path in ['docs/ai/registry.yaml','docs/ai/registry.schema.json','docs/ai/schemas/change-v1.schema.json','scripts/docs/docsctl.py','tauapi-ops/ROUTE_CONTRACT.json','tauapi-be/pkg/billingexpr/testdata/frontend_simulation.json','tauapi-fe/testdata/contracts/frontend_simulation.json','docs/ai/changes/active/docs-system-bootstrap.json','docs/ai/schemas/migration-v1.schema.json','docs/ai/schemas/check-result-v1.schema.json','docs/ai/migrations/obligation-map.yaml','docs/ai/contracts/billing-fixture.json']:
            p=self.root/path;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/path,p)
        p=self.root/'docs/ai/migrations/bootstrap-inventory.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text('{"schema_version":1,"revision":"fixture","items":[]}')
        subprocess.run(['git','init','-q',str(self.root)],check=True)

    def test_clean_fixture_passes(self):
        self.assertEqual(d.check(self.root,self.r),[])

    def test_broken_relative_link_is_rejected(self):
        p=self.root/'docs/ai/INDEX.md';p.write_text(p.read_text()+'\n[missing](missing.md)\n')
        self.assertTrue(any('broken link:' in x for x in d.check(self.root,self.r)))

    def test_broken_heading_anchor_is_rejected(self):
        p=self.root/'docs/ai/INDEX.md';p.write_text(p.read_text()+'\n[missing](#missing-heading)\n')
        self.assertTrue(any('broken anchor:' in x for x in d.check(self.root,self.r)))

    def test_reference_links_and_fenced_examples(self):
        self.assertEqual(d.links('```md\n[x](example.md)\n```\n[x][ref]\n[ref]: real.md\n'),['real.md'])

    def test_missing_source_is_rejected(self):
        self.r['documents'][0]['source_paths']=['tauapi-be/missing.go']
        self.assertTrue(any('missing source:' in x for x in d.check(self.root,self.r)))

    def test_duplicate_document_id_is_rejected(self):
        self.r['documents'].append(copy.deepcopy(self.r['documents'][0]))
        self.assertTrue(any('duplicate document ID:' in x for x in d.check(self.root,self.r)))

    def test_unknown_check_is_rejected(self):
        self.r['documents'][0]['checks']=['unknown']
        self.assertIn('unknown check: unknown',d.check(self.root,self.r))

    def test_duplicate_parser_keys_are_rejected(self):
        with self.assertRaises(d.Invalid):json.loads('{"id":1,"id":2}',object_pairs_hook=d.pairs)

    def test_glob_direct_deep_and_boundary(self):
        self.assertTrue(d.match('a/**/*.go','a/direct.go'))
        self.assertTrue(d.match('a/**/*.go','a/deep/deeper/file.go'))
        self.assertFalse(d.match('a/*.go','a/deep/file.go'))
        self.assertFalse(d.match('a/**','ab/file.go'))

    def test_unowned_source_is_rejected(self):
        self.assertIn('ownership: new-tree/file.go',d.route(self.r,['new-tree/file.go'])['findings'])

    def test_overlapping_plugin_billing_routing_union(self):
        result=d.route(self.r,['tauapi-be/plugins/tasks/example/index.js'])
        self.assertTrue({'be-plugins','be-billing'} <= set(result['domains']))
        self.assertTrue({'billing-and-quota','task-plugins','routing-and-origin'} <= set(result['contracts']))

    def test_chinese_intent_routes_both_refresh_consumers(self):
        result=d.route(self.r,[],'诊断登录刷新循环')
        self.assertTrue({'fe-auth','be-auth'} <= set(result['domains']))

    def test_stale_generated_index_fails_without_repair(self):
        p=self.root/'docs/ai/TASK_INDEX.md';p.write_text('stale\n')
        self.assertTrue(any('stale generated' in x for x in d.check(self.root,self.r)))
        self.assertEqual(p.read_text(),'stale\n')

    def test_generation_is_deterministic(self):
        self.assertEqual(d.rendered_index(self.r),d.rendered_index(copy.deepcopy(self.r)))

    def test_changed_billing_snapshot_is_rejected(self):
        p=self.root/'tauapi-fe/testdata/contracts/frontend_simulation.json';p.write_text('{}')
        self.assertEqual(d.fixture_findings(self.root),['billing fixture snapshot differs'])

    def test_literal_frontend_route_omitted_from_split_is_rejected(self):
        p=self.root/'tauapi-fe/src/routes/new.tsx';p.write_text("createFileRoute('/brand-new-page')({})")
        self.assertTrue(d.route_findings(self.root))

    def test_required_database_without_credentials_is_blocked(self):
        with unittest.mock.patch.dict(os.environ,{},clear=True):
            result=d.execute(self.root,['database-matrix'],self.root/'.docs-reports',{'commit':'candidate','source_digest':'digest','check_run_id':None})
        self.assertEqual(result[0]['status'],'blocked')
        self.assertIsNone(result[0]['exit_code'])

    def test_unicode_spaces_addition_and_deletion_preserve_paths(self):
        p=self.root/'docs/ai/空 格.md';p.write_text('# test')
        d.git(self.root,'add','-A');d.git(self.root,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','fixture')
        p.rename(self.root/'docs/ai/new name.md')
        changes=d.diff_paths(self.root,'HEAD',worktree=True)
        self.assertIn({'status':'D','path':'docs/ai/空 格.md'},changes)
        self.assertIn({'status':'A','path':'docs/ai/new name.md'},changes)

    def test_missing_baseline_is_blocked(self):
        with self.assertRaises(d.Blocked):d.diff_paths(self.root,'absent',worktree=True)

    def test_reasoned_unchanged_disposition_is_valid(self):
        p=self.root/'docs/ai/changes/active/docs-system-bootstrap.json';r=json.loads(p.read_text())
        r['dispositions']['authentication']={'status':'reviewed_unchanged','reason':'Only navigation changes; credentials and flows retain behavior.','evidence':['tauapi-be/service/auth_session.go']};p.write_text(json.dumps(r))
        self.assertEqual(d.dispositions(self.root,str(p.relative_to(self.root)),{'contracts':['authentication']}),[])

    def test_missing_and_wrong_candidate_evidence_are_rejected(self):
        expected={'commit':'candidate','source_digest':'digest','check_run_id':'run'}
        path=self.root/'report.json'
        self.assertTrue(d.evidence_findings(self.root,path,expected,'docs-integrity'))
        path.write_text('{}')
        self.assertTrue(d.evidence_findings(self.root,path,expected,'docs-integrity'))
        report=json.loads((ROOT/'docs/ai/templates/check-result.json').read_text())
        report.update(check_id='docs-integrity',subject={'commit':'other','source_digest':'digest','check_run_id':'run'})
        path.write_text(json.dumps(report))
        self.assertTrue(d.evidence_findings(self.root,path,expected,'docs-integrity'))

    def test_baseline_mapping_survives_candidate_removal(self):
        path=self.root/'docs/ai/registry.yaml';path.write_text(json.dumps(self.r))
        d.git(self.root,'add','-A');d.git(self.root,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','baseline')
        candidate=copy.deepcopy(self.r)
        candidate['domains']=[x for x in candidate['domains'] if x['id']!='be-plugins']
        path.write_text(json.dumps(candidate))
        target=self.root/'tauapi-be/plugins/tasks/new.js';target.parent.mkdir(parents=True,exist_ok=True);target.write_text('// changed plugin')
        impact=d.impact(self.root,candidate,'HEAD',None,True)
        self.assertIn('be-plugins',impact['domains'])
        self.assertIn('task-plugins',impact['contracts'])

    def test_fallback_only_source_requires_classification(self):
        result=d.route(self.r,['tauapi-be/unmapped-new-package/code.go'])
        self.assertTrue(any('unclassified_source_path' in x for x in result['findings']))

    def test_unknown_normative_schema_field_is_rejected(self):
        import jsonschema
        registry=copy.deepcopy(self.r);registry['domains'][0]['unknown']=True
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(registry,d.read_json(ROOT/'docs/ai/registry.schema.json'))

    def test_session_hook_and_malformed_input(self):
        hook=ROOT/'scripts/docs/hooks/adapter.py'
        good=subprocess.run([os.sys.executable,str(hook)],input=json.dumps({'hook_event_name':'SessionStart'}),text=True,capture_output=True)
        self.assertEqual(good.returncode,0)
        self.assertIn('docs/ai/INDEX.md',json.loads(good.stdout)['hookSpecificOutput']['additionalContext'])
        bad=subprocess.run([os.sys.executable,str(hook)],input='{',text=True,capture_output=True)
        self.assertNotEqual(bad.returncode,0)

    def test_stop_hook_continuation_is_bounded(self):
        hook=ROOT/'scripts/docs/hooks/adapter.py'
        result=subprocess.run([os.sys.executable,str(hook)],input=json.dumps({'hook_event_name':'Stop','stop_hook_active':True}),text=True,capture_output=True)
        self.assertEqual(result.returncode,0)
        self.assertFalse(result.stdout)

    def test_independent_verifier_requires_candidate_and_rejects_invalid_mode(self):
        script=ROOT/'tauapi-ops/scripts/verify-independent-builds.sh'
        env={k:v for k,v in os.environ.items() if k!='TAUAPI_VERIFY_REV'}
        missing=subprocess.run(['bash',str(script),'fe'],env=env,capture_output=True)
        self.assertEqual(missing.returncode,3)
        invalid=subprocess.run(['bash',str(script),'invalid'],env=env,capture_output=True)
        self.assertEqual(invalid.returncode,2)

    def test_stop_hook_rejection_error_and_unavailable_prerequisite(self):
        import io
        hook_spec=importlib.util.spec_from_file_location('docs_hook',ROOT/'scripts/docs/hooks/adapter.py')
        hook=importlib.util.module_from_spec(hook_spec);hook_spec.loader.exec_module(hook)
        for code,payload,expected in [(1,{'findings':['broken link']},0),(3,{'status':'blocked'},1),(4,{'status':'failed'},1)]:
            output=io.StringIO()
            with mock.patch('sys.stdin',io.StringIO('{"hook_event_name":"Stop"}')), mock.patch('sys.stdout',output), mock.patch.object(hook.subprocess,'run',return_value=subprocess.CompletedProcess([],code,json.dumps(payload),'')):
                self.assertEqual(hook.main(),expected)
            if code==1:self.assertEqual(json.loads(output.getvalue())['decision'],'block')
        with mock.patch('sys.stdin',io.StringIO('{"hook_event_name":"Stop"}')), mock.patch.object(hook.Path,'exists',return_value=False):
            self.assertEqual(hook.main(),1)

    def test_authority_cycles_fail_but_ordinary_crosslinks_are_allowed(self):
        docs=[{'id':'a','status':'active','mandatory_reads':['b']},{'id':'b','status':'active','mandatory_reads':['a']}]
        self.assertIn('mandatory cycle',d.authority_findings(docs))
        docs=[{'id':'a','status':'historical','superseded_by':['b']},{'id':'b','status':'active','supersedes':['a']}]
        self.assertEqual(d.authority_findings(docs),[])
        docs[1]['superseded_by']=['a']
        self.assertIn('supersession cycle',d.authority_findings(docs))

    def test_both_changed_fixtures_need_local_revision_update(self):
        for p in ['tauapi-be/pkg/billingexpr/testdata/frontend_simulation.json','tauapi-fe/testdata/contracts/frontend_simulation.json']:
            (self.root/p).write_text('{}')
        self.assertIn('local billing fixture revision/hash differs',d.fixture_findings(self.root))

    def test_stop_hook_reports_changed_work_without_dispositions(self):
        import io
        hook_spec=importlib.util.spec_from_file_location('docs_completion_hook',ROOT/'scripts/docs/hooks/adapter.py')
        hook=importlib.util.module_from_spec(hook_spec);hook_spec.loader.exec_module(hook)
        results=[subprocess.CompletedProcess([],0,'{}',''),subprocess.CompletedProcess([],0,'tauapi-be/model/new.go\0',''),subprocess.CompletedProcess([],0,'','')]
        output=io.StringIO()
        with mock.patch('sys.stdin',io.StringIO('{"hook_event_name":"Stop"}')), mock.patch('sys.stdout',output), mock.patch.object(hook.subprocess,'run',side_effect=results):
            self.assertEqual(hook.main(),0)
        self.assertEqual(json.loads(output.getvalue())['decision'],'block')
        self.assertIn('task JSON record',json.loads(output.getvalue())['reason'])

from unittest import mock
if __name__=='__main__':unittest.main()
