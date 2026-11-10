#!/usr/bin/env python3
"""Package a working server, keeping world content but excluding all player records."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys
import tarfile
import time

ROOT = Path(__file__).resolve().parents[2]


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def docker(*args, **kwargs):
    return run('docker', *args, **kwargs)


def checksum(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def validate_client_patch(path):
    try:
        import mpyq
    except ImportError as error:
        raise RuntimeError('Packaging requires mpyq to verify client DBCs: python3 -m pip install mpyq') from error
    with path.open('rb') as stream:
        archive = mpyq.MPQArchive(stream, listfile=False)
        for dbc in (ROOT / 'client-patches/DBFilesClient').glob('*.dbc'):
            content = archive.read_file('DBFilesClient\\' + dbc.name)
            if content is None or hashlib.sha256(content).hexdigest() != checksum(dbc):
                raise RuntimeError(f'Client MPQ does not match the versioned server DBC: {dbc.name}')


def sql(container, query):
    return output('docker', 'exec', container, 'sh', '-c',
                  'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql --protocol=TCP -h127.0.0.1 -uroot -Nse "$1"', 'sh', query)


def write_seed_defaults(dest):
    """Static bootstrap rows, never sampled from live account/character records."""
    defaults = {
        'auth': ['rbac_permissions', 'rbac_linked_permissions', 'rbac_default_permissions', 'motd'],
        'characters': ['active_arena_season', 'addons', 'warden_action', 'worldstates', 'world_state'],
    }
    target = dest / 'seed/zz-defaults.sql'
    temporary = target.with_suffix('.tmp')
    with temporary.open('w') as stream:
        for database, tables in defaults.items():
            stream.write(f'USE acore_{database};\n')
            for table in tables:
                stream.write((ROOT / f'data/sql/base/db_{database}/{table}.sql').read_text())
                stream.write('\n')
        stream.write('USE acore_characters;\n')
        for table in ['playerbots_names', 'playerbots_guild_names', 'playerbots_arena_team_names']:
            stream.write((ROOT / f'modules/mod-playerbots/data/sql/characters/base/{table}.sql').read_text())
            stream.write('\n')
    temporary.replace(target)


def clean_seed(dest, images, temporary, source_database):
    network = temporary + '-net'
    database = temporary + '-db'
    password = secrets.token_hex(24)
    docker('network', 'create', '--internal', network, stdout=subprocess.DEVNULL)
    try:
        docker('run', '-d', '--pull=never', '--name', database, '--network', network,
               '-e', 'MYSQL_ROOT_PASSWORD=' + password, images['ac-database'],
               '--innodb-flush-log-at-trx-commit=2', '--sync-binlog=0', '--skip-log-bin',
               stdout=subprocess.DEVNULL)
        for _ in range(180):
            try:
                if sql(database, 'SELECT 1') == '1':
                    break
            except subprocess.CalledProcessError:
                pass
            time.sleep(2)
        else:
            raise RuntimeError('Temporary MySQL did not start')
        # Read schemas only for private databases. Never copy their row data.
        # The working world is the release's golden content, including module migrations
        # that legacy upstream SQL can no longer reproduce on the current schema.
        transfer = dest / 'seed-transfer.sql'
        for databases, schema_only in [(['acore_auth', 'acore_characters'], True), (['acore_world'], False)]:
            dump_command = ('MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump -uroot '
                            '--single-transaction --skip-lock-tables --set-gtid-purged=OFF '
                            '--no-tablespaces --skip-triggers ')
            if schema_only:
                dump_command += '--no-data '
            with transfer.open('wb') as stream:
                docker('exec', source_database, 'sh', '-c',
                       dump_command + '--databases ' + ' '.join(databases), stdout=stream)
            with transfer.open('rb') as stream:
                docker('exec', '-i', database, 'sh', '-c',
                       'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot', stdin=stream)
        transfer.unlink()
        # Required client-build metadata contains no account information.
        with (ROOT / 'data/sql/base/db_auth/build_info.sql').open('rb') as stream:
            docker('exec', '-i', database, 'sh', '-c',
                   'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot acore_auth', stdin=stream)
        with (ROOT / 'data/sql/base/db_auth/realmlist.sql').open('rb') as stream:
            docker('exec', '-i', database, 'sh', '-c',
                   'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot acore_auth', stdin=stream)
        sql(database, 'CREATE DATABASE acore_playerbots CHARACTER SET utf8mb4')
        bot_sql = ROOT / 'modules/mod-playerbots/data/sql/playerbots'
        for folder in ['base', 'updates', 'custom']:
            for path in sorted((bot_sql / folder).glob('*.sql')):
                with path.open('rb') as stream:
                    docker('exec', '-i', database, 'sh', '-c',
                           'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot acore_playerbots', stdin=stream)
        sql(database, "UPDATE acore_auth.realmlist SET address='127.0.0.1', "
            "localAddress='127.0.0.1', name='AzerothCore Offline', port=8085 WHERE id=1")
        if sql(database, 'SELECT COUNT(*) FROM acore_auth.account') != '0':
            raise RuntimeError('Seed contains accounts; refusing to distribute it')
        if sql(database, 'SELECT COUNT(*) FROM acore_characters.characters') != '0':
            raise RuntimeError('Seed contains characters; refusing to distribute it')
        version = (dest / 'VERSION').read_text().strip()
        sql(database, 'CREATE DATABASE repack_meta; CREATE TABLE repack_meta.installation '
            '(ready INT NOT NULL, version VARCHAR(100) NOT NULL); '
            f"INSERT INTO repack_meta.installation VALUES (1, '{version}')")
        seed = dest / 'seed'
        seed.mkdir()
        # Metadata is dumped last: runtime health checks cannot pass during import.
        with (seed / 'initial.sql').open('wb') as stream:
            docker('exec', database, 'sh', '-c',
                   'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump -uroot --single-transaction '
                   '--set-gtid-purged=OFF --no-tablespaces --databases '
                   'acore_auth acore_characters acore_world acore_playerbots repack_meta', stdout=stream)
        write_seed_defaults(dest)
    finally:
        for name in [database]:
            subprocess.run(['docker', 'rm', '-fv', name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(['docker', 'network', 'rm', network], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def compose_file(dest, images, gameplay):
    connection = 'ac-database;3306;root;${REPACK_DB_PASSWORD:?Run instalar.sh};'
    env = {key: str(value) for key, value in gameplay.items() if value is not None}
    env.update({
        'AC_LOGIN_DATABASE_INFO': connection + 'acore_auth',
        'AC_CHARACTER_DATABASE_INFO': connection + 'acore_characters',
        'AC_WORLD_DATABASE_INFO': connection + 'acore_world',
        'AC_PLAYERBOTS_DATABASE_INFO': connection + 'acore_playerbots',
        'AC_DATA_DIR': '/azerothcore/env/dist/data',
        'AC_LOGS_DIR': '/azerothcore/env/dist/logs',
        'AC_UPDATES_ENABLE_DATABASES': '0',
        'AC_PLAYERBOTS_UPDATES_ENABLE_DATABASES': '0',
        'AC_AI_PLAYERBOT_MIN_RANDOM_BOTS': '100',
        'AC_AI_PLAYERBOT_MAX_RANDOM_BOTS': '100',
    })
    services = {
        'init-data': {
            'image': images['ac-worldserver'], 'pull_policy': 'never', 'user': '0:0',
            'network_mode': 'none', 'profiles': ['setup'], 'entrypoint': ['/bin/bash', '-ec'],
            'command': ['if [ -f /data/.repack-data-ready ]; then '
                        'cmp /data/.repack-data-ready /bundle/VERSION || '
                        '{ echo "Existing data belongs to another version" >&2; exit 1; }; else '
                        'tar -xzf /bundle/data.tar.gz -C /data; '
                        'cp /bundle/VERSION /data/.repack-data-ready; fi; '
                        'cp -rn /azerothcore/env/ref/etc/. /etc-ac/; '
                        'chown -R 1000:1000 /etc-ac /logs'],
            'volumes': ['./data.tar.gz:/bundle/data.tar.gz:ro,z', './VERSION:/bundle/VERSION:ro,z', 'data:/data',
                        'config:/etc-ac', 'logs:/logs'],
        },
        'ac-database': {
            'image': images['ac-database'], 'pull_policy': 'never', 'restart': 'unless-stopped',
            'environment': {'MYSQL_ROOT_PASSWORD': '${REPACK_DB_PASSWORD:?Run instalar.sh}'},
            'volumes': ['database:/var/lib/mysql', './seed:/docker-entrypoint-initdb.d:ro,z'],
            'healthcheck': {'test': ['CMD-SHELL', 'MYSQL_PWD="$$MYSQL_ROOT_PASSWORD" '
                                   'mysql --protocol=TCP -h127.0.0.1 -uroot '
                                   '-Nse "SELECT ready FROM repack_meta.installation" | grep -qx 1'],
                            'interval': '5s', 'timeout': '5s', 'retries': 240},
        },
    }
    for name in ['ac-authserver', 'ac-worldserver']:
        services[name] = {
            'image': images[name], 'pull_policy': 'never', 'restart': 'unless-stopped',
            'environment': env if name == 'ac-worldserver' else {
                'AC_LOGIN_DATABASE_INFO': connection + 'acore_auth',
                'AC_UPDATES_ENABLE_DATABASES': '0', 'AC_LOGS_DIR': '/azerothcore/env/dist/logs'},
            'volumes': ['config:/azerothcore/env/dist/etc', 'logs:/azerothcore/env/dist/logs'],
            'depends_on': {'ac-database': {'condition': 'service_healthy'}},
            'stdin_open': True, 'tty': True,
        }
    services['ac-authserver']['ports'] = ['127.0.0.1:${REPACK_AUTH_PORT:-3724}:3724']
    services['ac-worldserver']['ports'] = ['127.0.0.1:${REPACK_WORLD_PORT:-8085}:8085']
    services['ac-worldserver']['stop_grace_period'] = '2m'
    services['ac-worldserver']['volumes'] += [
        'data:/azerothcore/env/dist/data:ro', './modules:/azerothcore/modules:ro,z']
    (dest / 'compose.json').write_text(json.dumps({
        'services': services, 'volumes': {key: {} for key in ['database', 'data', 'config', 'logs']},
        'networks': {'default': {}},
    }, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='New output directory (must not exist)')
    parser.add_argument('--world-container', default='ac-worldserver')
    parser.add_argument('--database-container', default='ac-database',
                        help='Working release database: exports world content and empty auth/character schemas only')
    parser.add_argument('--client-patch', type=Path, default=ROOT / 'env/dist/client-patches/patch-z.mpq')
    args = parser.parse_args()
    dest = args.output.resolve()
    if dest.exists():
        parser.error('Output already exists; use a new directory')
    if dest.is_relative_to(ROOT):
        parser.error('Output must be outside the source tree')
    if not args.client_patch.is_file():
        parser.error('Matching patch-z.mpq is required (--client-patch)')
    validate_client_patch(args.client_patch)
    os.chdir(ROOT)
    output('docker', 'info', '--format', '{{.OSType}}')
    config = json.loads(output('docker', 'compose', 'config', '--format', 'json'))
    source = json.loads(output('docker', 'inspect', args.world_container))[0]
    mounts = [item for item in source['Mounts'] if item['Destination'].rstrip('/') == '/azerothcore/env/dist/data']
    if len(mounts) != 1:
        raise RuntimeError('Cannot identify server data mount')
    images = {}
    identity = {}
    for name in ['ac-database', 'ac-worldserver', 'ac-authserver']:
        tag = config['services'][name]['image']
        info = json.loads(output('docker', 'image', 'inspect', tag))[0]
        if info['Os'] != 'linux' or info['Architecture'] != 'amd64':
            raise RuntimeError(f'{tag}: this exporter currently supports linux/amd64 only')
        identity[name] = info['Id']
        images[name] = 'acore-offline/' + name + ':' + info['Id'].split(':')[1][:16]
    if source['Image'] != identity['ac-worldserver']:
        raise RuntimeError('Running worldserver differs from selected image; align images before packaging')
    dest.mkdir(parents=True)
    version = time.strftime('%Y%m%d-%H%M%S') + '-' + output('git', 'rev-parse', '--short', 'HEAD')
    (dest / 'VERSION').write_text(version + '\n')
    (dest / 'manifest.json').write_text(json.dumps({
        'version': version, 'platform': 'linux/amd64', 'images': identity,
        'source_commit': output('git', 'rev-parse', 'HEAD'),
        'source_dirty': bool(output('git', 'status', '--porcelain')),
        'client_patch_sha256': checksum(args.client_patch),
        'seed_strategy': 'working world content; auth/characters schema only; fresh playerbots SQL',
    }, indent=2) + '\n')
    for name, tag in images.items():
        docker('tag', identity[name], tag)
    print('Preparing clean SQL seed in an isolated internal network...', flush=True)
    clean_seed(dest, images, 'repack-build-' + secrets.token_hex(6), args.database_container)
    package_payload(dest, images, config, args.client_patch, mounts[0])


def package_payload(dest, images, config, client_patch, mount):
    print('Copying server data from read-only volume...', flush=True)
    source_path = mount.get('Name') if mount['Type'] == 'volume' else mount['Source']
    mount_arg = f'type={mount["Type"]},source={source_path},target=/source,readonly'
    with (dest / 'data.tar.gz').open('wb') as stream:
        docker('run', '--rm', '--pull=never', '--network', 'none', '--user', '0:0',
               '--mount', mount_arg, '-v', f'{ROOT / "client-patches/DBFilesClient"}:/custom:ro,z',
               '--entrypoint', 'bash', images['ac-worldserver'], '-ec',
               'set -o pipefail; '
               'for d in Cameras dbc maps mmaps vmaps; do '
               'test -n "$(find /source/$d -type f -print -quit)"; done; '
               'mkdir -p /tmp/repack/dbc; cp -a /source/dbc/. /tmp/repack/dbc/; '
               'cp /custom/*.dbc /tmp/repack/dbc/; '
               'tar -cf - -C /tmp/repack dbc -C /source Cameras maps mmaps vmaps | gzip -1', stdout=stream)
    # Verify the packaged copy, after overlaying versioned custom DBCs.
    with tarfile.open(dest / 'data.tar.gz', 'r:gz') as archive:
        for path in (ROOT / 'client-patches/DBFilesClient').glob('*.dbc'):
            member = archive.extractfile('dbc/' + path.name)
            if member is None or hashlib.sha256(member.read()).hexdigest() != checksum(path):
                raise RuntimeError(f'Server DBC mismatch: {path.name}')
    print('Saving immutable runtime images...', flush=True)
    runtime_images = [images[key] for key in ['ac-database', 'ac-worldserver', 'ac-authserver']]
    with (dest / 'images.tar.gz').open('wb') as stream:
        save = subprocess.Popen(['docker', 'save', *runtime_images], stdout=subprocess.PIPE)
        try:
            with gzip.GzipFile(fileobj=stream, mode='wb', compresslevel=1, mtime=0) as compressed:
                shutil.copyfileobj(save.stdout, compressed)
        finally:
            save.stdout.close()
        if save.wait() != 0:
            raise RuntimeError('docker save failed')
    # Runtime module assets only, never build objects or local configuration/secrets.
    shutil.copy2(ROOT / 'AUTHORS', dest / 'AUTHORS')
    for module in (ROOT / 'modules').iterdir():
        if not module.is_dir():
            continue
        for name in ['data', 'conf']:
            source_dir = module / name
            if source_dir.is_dir():
                shutil.copytree(source_dir, dest / 'modules' / module.name / name,
                                ignore=shutil.ignore_patterns('*.conf', '*.local.*', '__pycache__'))
        for license_file in module.glob('LICENSE*'):
            if license_file.is_file():
                target = dest / 'modules' / module.name
                target.mkdir(parents=True, exist_ok=True)
                shutil.copy2(license_file, target / license_file.name)
    client = dest / 'client'
    client.mkdir()
    shutil.copy2(client_patch, client / 'patch-z.mpq')
    shutil.copytree(ROOT / 'client-patches/AddOns/AcoreRacialTooltips', client / 'AcoreRacialTooltips')
    for path in (ROOT / 'apps/repack/runtime').iterdir():
        shutil.copy2(path, dest / path.name)
        if path.suffix == '.sh':
            (dest / path.name).chmod(0o755)
    compose_file(dest, images, config['services']['ac-worldserver']['environment'])
    with (dest / 'SHA256SUMS').open('w') as stream:
        for path in sorted(dest.rglob('*')):
            if path.is_file() and path.name != 'SHA256SUMS':
                stream.write(f'{checksum(path)}  {path.relative_to(dest)}\n')
    print(f'Ready: {dest}\nRun ./instalar.sh in that directory. Live databases were only read, never changed.')


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as error:
        # Command arguments can contain disposable database credentials.
        sys.exit(f'Packaging stopped: command failed with exit code {error.returncode}. See output above.')
