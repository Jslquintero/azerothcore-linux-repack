"""Installer regression tests without a Docker daemon."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('repack_export', Path(__file__).with_name('export.py'))
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.folder = Path(self.temporary.name)
        for source in Path(__file__).with_name('runtime').glob('*.sh'):
            shutil.copy(source, self.folder / source.name)
            (self.folder / source.name).chmod(0o755)
        (self.folder / 'VERSION').write_text('test-release\n')
        self.bin = self.folder / 'bin'
        self.bin.mkdir()
        fake = self.bin / 'docker'
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$DOCKER_TEST_LOG"\n')
        fake.chmod(0o755)
        self.log = self.folder / 'docker.log'
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        DOCKER_TEST_LOG=str(self.log))

    def install(self):
        return subprocess.run(['bash', str(self.folder / 'instalar.sh')], env=self.env,
                              capture_output=True, text=True, timeout=10)

    def test_corruption_stops_before_loading_images(self):
        (self.folder / 'SHA256SUMS').write_text('0' * 64 + '  VERSION\n')
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('load ', self.log.read_text())
        self.assertFalse((self.folder / '.installed-version').exists())

    def test_new_install_records_version_after_seed_is_ready(self):
        digest = hashlib.sha256((self.folder / 'VERSION').read_bytes()).hexdigest()
        (self.folder / 'SHA256SUMS').write_text(digest + '  VERSION\n')
        with (self.bin / 'docker').open('a') as stream:
            stream.write('case "$*" in *"exec -T ac-database"*) echo test-release;; esac\n')
        self.assertEqual(self.install().returncode, 0)
        self.assertEqual((self.folder / '.installed-version').read_text(), 'test-release\n')
        self.assertEqual((self.folder / '.env').stat().st_mode & 0o777, 0o600)
        commands = self.log.read_text()
        self.assertIn('load -i images.tar.gz', commands)
        self.assertIn('run --rm --no-deps init-data', commands)
        self.assertNotIn('--build', commands)

    def test_same_version_reinstall_only_starts_existing_services(self):
        (self.folder / '.installed-version').write_text('test-release\n')
        self.assertEqual(self.install().returncode, 0)
        commands = self.log.read_text()
        self.assertIn('up -d --no-build --pull never ac-authserver ac-worldserver', commands)
        self.assertNotIn('load ', commands)
        self.assertNotIn('init-data', commands)
        self.assertNotIn('down', commands)

    def test_other_version_is_rejected_without_starting(self):
        (self.folder / '.installed-version').write_text('older-release\n')
        self.assertNotEqual(self.install().returncode, 0)
        commands = self.log.read_text()
        self.assertNotIn('up ', commands)
        self.assertNotIn('load ', commands)
        self.assertEqual((self.folder / '.installed-version').read_text(), 'older-release\n')

    def test_bootstrap_includes_required_static_rows_without_player_records(self):
        (self.folder / 'seed').mkdir()
        exporter.write_seed_defaults(self.folder)
        seed = (self.folder / 'seed/zz-defaults.sql').read_text()
        for table in ['active_arena_season', 'rbac_permissions', 'playerbots_names', 'playerbots_guild_names']:
            self.assertIn(f'INSERT INTO `{table}`', seed)
        for table in ['account', 'characters', 'account_access', 'item_instance']:
            self.assertNotIn(f'INSERT INTO `{table}`', seed)

    def test_runtime_uses_local_images_and_publishable_game_ports(self):
        images = {name: 'local/' + name for name in ['ac-database', 'ac-authserver', 'ac-worldserver']}
        exporter.compose_file(self.folder, images, {'AC_LOGIN_DATABASE_INFO': 'private-password'})
        config = json.loads((self.folder / 'compose.json').read_text())
        self.assertNotIn('private-password', json.dumps(config))
        self.assertFalse(config['networks']['default'].get('internal', False))
        self.assertNotIn('ports', config['services']['ac-database'])
        for service in config['services'].values():
            self.assertEqual(service['pull_policy'], 'never')
            self.assertNotIn('build', service)
            self.assertNotIn('container_name', service)
        self.assertTrue(config['services']['ac-authserver']['ports'][0].startswith('127.0.0.1:'))


if __name__ == '__main__':
    unittest.main()
