"""Exercise release packaging and immutable assets without services or publication."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SCRIPTS = ROOT / 'tauapi-ops/scripts'


class ReleasePolicyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = {**os.environ, 'PATH': f'{self.bin}:/usr/bin:/bin',
                    'STATE_DIR': str(self.root), 'BUILD_LOG': str(self.root / 'build.log')}
        for name in ('sha256sum', 'shasum'):
            self.stub(name, '#!/bin/sh\nexit 99\n')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)
        return path

    def run_command(self, *args):
        return subprocess.run(args, env=self.env, text=True, capture_output=True)

    def commit_components(self):
        for name in ('tauapi-fe', 'tauapi-be'):
            component = self.repo / name
            component.mkdir()
            for notice in ('LICENSE', 'NOTICE', 'THIRD-PARTY-LICENSES.md'):
                (component / notice).write_text('Upstream attribution\n')
            (component / 'VERSION').write_text('1.2.3\n')
            (component / 'UPSTREAM.json').write_text(json.dumps({'upstream_commit': 'upstream'}))
        (self.repo / 'tauapi-fe/package.json').write_text('{"packageManager":"bun@test"}')
        for module in ('relaykit', 'tokenkit'):
            (self.repo / 'tauapi-be' / module).mkdir()
            (self.repo / 'tauapi-be' / module / 'go.mod').write_text('module example\n')
        for args in [('init', '-q'), ('add', '.'),
                     ('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                      'commit', '-qm', 'fixture')]:
            subprocess.run(['git', '-C', str(self.repo), *args], check=True)

    def test_backend_packages_only_amd64_without_checksum_files(self):
        self.commit_components()
        self.stub('go', '''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ['BUILD_LOG'], 'a') as log:
    log.write(json.dumps([os.getenv('GOOS'), os.getenv('GOARCH'), args]) + '\\n')
if args[0] == 'list': print('/tmp/module')
elif args[0] == 'version': print('go version test linux/amd64')
elif '-o' in args: pathlib.Path(args[args.index('-o') + 1]).write_text('executable')
''')
        output = self.root / 'out'
        result = self.run_command('bash', str(SCRIPTS / 'build-backend-binaries.sh'),
                                  '--repo', str(self.repo), '--rev', 'HEAD', '--out', str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([p.name for p in output.iterdir()], ['tauapi-be-v1.2.3-linux-amd64.tar.gz'])
        with tarfile.open(next(output.iterdir())) as archive:
            names = {m.name.removeprefix('./') for m in archive.getmembers() if m.isfile()}
            self.assertEqual(names, {'new-api', 'LICENSE', 'NOTICE', 'THIRD-PARTY-LICENSES.md', 'release-manifest.json'})
            manifest = json.load(archive.extractfile('./release-manifest.json'))
            self.assertEqual((manifest['goos'], manifest['goarch']), ('linux', 'amd64'))
        builds = [json.loads(line) for line in (self.root / 'build.log').read_text().splitlines()]
        targets = [(os_name, arch) for os_name, arch, args in builds if '-o' in args]
        self.assertEqual(targets, [('linux', 'amd64')])

    def test_frontend_packages_manifest_and_assets_without_sidecars(self):
        self.commit_components()
        bun = self.stub('bun', '''#!/usr/bin/env python3
import os, pathlib, sys
if sys.argv[1:] == ['--version']: print('test')
elif sys.argv[1:] == ['run', 'build']:
    dist = pathlib.Path('dist'); dist.mkdir(); (dist/'static').mkdir()
    (dist/'index.html').write_text('/_ui/' + os.environ['TAUAPI_RELEASE_ID'] + '/static/app.js')
    (dist/'static/app.js').write_text('app')
''')
        self.env['BUN_BIN'] = str(bun)
        output = self.root / 'out'
        result = self.run_command('bash', str(SCRIPTS / 'build-frontend.sh'), '--repo', str(self.repo),
                                  '--rev', 'HEAD', '--release-id', 'test-release', '--out', str(output))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({p.name for p in output.iterdir()}, {'test-release.tar.gz', 'test-release.manifest.json'})
        with tarfile.open(output / 'test-release.tar.gz') as archive:
            names = {m.name.removeprefix('./') for m in archive.getmembers() if m.isfile()}
        self.assertEqual(names, {'index.html', 'static/app.js', 'ui-version.json', 'release-manifest.json',
                                 'LICENSE', 'NOTICE', 'THIRD-PARTY-LICENSES.md'})
        self.assertNotIn('SHA256=', result.stdout)

    def test_docker_build_selects_linux_amd64(self):
        self.commit_components()
        self.stub('docker', '''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['BUILD_LOG'], 'a') as log: log.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1:3] == ['image', 'inspect']: print('test-image-id')
''')
        result = self.run_command('bash', str(SCRIPTS / 'build-backend.sh'), '--repo', str(self.repo),
                                  '--rev', 'HEAD', '--out', str(self.root / 'out'))
        self.assertEqual(result.returncode, 0, result.stderr)
        builds = [json.loads(line) for line in (self.root / 'build.log').read_text().splitlines()]
        build = next(args for args in builds if args[0] == 'build')
        self.assertEqual(build[build.index('--platform') + 1], 'linux/amd64')

    def test_backup_restore_uses_blake2_and_accepts_legacy_dump(self):
        ops = self.root / 'ops'
        ops.mkdir()
        for name in ('backup.sh', 'restore-check.sh'):
            shutil.copyfile(SCRIPTS / name, ops / name)
        images = self.root / 'images.env'
        images.write_text('POSTGRES_IMAGE=test-postgres\nBACKEND_MASTER_IMAGE=test-backend\n')
        (ops / 'lib.sh').write_text('''set -euo pipefail
require_root() { :; }
container_id() { echo test-container; }
log() { :; }
die() { echo "$1" >&2; exit "$2"; }
''')
        self.env.update(BACKUP_ROOT=str(self.root / 'backups'), RUNTIME_ROOT=str(self.root),
                        IMAGES_ENV=str(images))
        self.stub('df', '#!/bin/sh\nprintf "Avail\\n99999999\\n"\n')
        self.stub('docker', '''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['BUILD_LOG'], 'a') as log: log.write(json.dumps(args) + '\\n')
if 'pg_dump' in args: print('dump data')
elif 'psql' in args: print('20')
elif 'wget' in args: print('{"status":true,"data":{"server_address":"test"}}')
''')
        result = self.run_command('bash', str(ops / 'backup.sh'), '--no-prune')
        self.assertEqual(result.returncode, 0, result.stderr)
        dump = next((self.root / 'backups/db').glob('*.dump'))
        self.assertTrue(Path(str(dump) + '.b2').is_file())
        self.assertFalse(Path(str(dump) + '.sha256').exists())
        result = self.run_command('bash', str(ops / 'restore-check.sh'), str(dump))
        self.assertEqual(result.returncode, 0, result.stderr)
        original = dump.read_bytes()
        dump.write_bytes(b'corrupt dump')
        (self.root / 'build.log').unlink()
        result = self.run_command('bash', str(ops / 'restore-check.sh'), str(dump))
        self.assertEqual(result.returncode, 3, result.stderr)
        self.assertFalse((self.root / 'build.log').exists(), 'Corruption must fail before starting containers')
        dump.write_bytes(original)
        Path(str(dump) + '.b2').unlink()
        Path(str(dump) + '.sha256').write_text('unread legacy checksum')
        result = self.run_command('bash', str(ops / 'restore-check.sh'), str(dump))
        self.assertEqual(result.returncode, 0, result.stderr)

    def compare_assets(self, release, public):
        return self.run_command('bash', '-c',
                                'source "$1"; compare_public_assets "$2" "$3"',
                                'test', str(SCRIPTS / 'lib-frontend.sh'), str(release), str(public))

    def test_public_asset_comparison_rejects_changes_missing_extra_and_links(self):
        release, public = self.root / 'release', self.root / 'public'
        release.mkdir()
        for name in ('index.html', 'ui-version.json', 'release-manifest.json'):
            (release / name).write_text('metadata')
        (release / 'static').mkdir()
        (release / 'static/app.js').write_text('first')
        shutil.copytree(release / 'static', public / 'static')
        self.assertEqual(self.compare_assets(release, public).returncode, 0)
        # Legacy checksum metadata must never be read or verified.
        (release / 'SHA256SUMS').write_text('invalid legacy metadata')
        self.assertEqual(self.compare_assets(release, public).returncode, 0)
        for change in ('changed', 'missing', 'extra', 'symlink', 'nested-metadata'):
            with self.subTest(change=change):
                asset = public / 'static/app.js'
                if change == 'changed':
                    original = asset.stat()
                    asset.write_text('other')
                    os.utime(asset, ns=(original.st_atime_ns, original.st_mtime_ns))
                elif change == 'missing': asset.unlink()
                elif change == 'extra': (public / 'extra.js').write_text('extra')
                elif change == 'symlink':
                    asset.unlink(); asset.symlink_to(release / 'static/app.js')
                else: (release / 'static/index.html').write_text('required nested file')
                self.assertNotEqual(self.compare_assets(release, public).returncode, 0)
                shutil.rmtree(public)
                shutil.copytree(release / 'static', public / 'static')


if __name__ == '__main__':
    unittest.main()
