#!/usr/bin/env python3
"""Run with python3 dev/test_herdr_packages.py; no real Herdr calls or installs."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def check():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        home = root / "home"
        source = root / "source"
        bins = root / "bin"
        bins.mkdir()
        registry = root / "registry.json"
        log = root / "calls.jsonl"
        inventory = source / "packages/linux/herdr-plugins.json"
        env = dict(os.environ, HOME=str(home), SOURCE=str(source), CALLS=str(log),
                   REGISTRY=str(registry), PATH=f"{bins}{os.pathsep}{os.environ['PATH']}")

        def stub(name, code):
            path = bins / name
            path.write_text(f"#!{sys.executable}\n" + code, encoding='utf-8')
            path.chmod(0o755)

        stub("chezmoi", "import os; print(os.environ['SOURCE'])\n")
        stub("gum", r"""import os, sys
args = sys.argv[1:]
if args[0] == 'choose':
    if '🧩 herdr' in args:
        print('🧩 herdr')
    elif '✓ Sí, usar chezmoi/packages/linux/' in args:
        print('✓ Sí, usar chezmoi/packages/linux/')
    else:
        print('\n'.join(a for a in args if a.startswith('test.')))
elif args[0] == 'confirm':
    assert os.read(0, 15) == b'terminal-input\n'
    sys.exit(int(os.environ.get('CANCEL', '0')))
elif args[0] == 'style':
    print(args[-1])
""")
        stub("herdr", r"""import json, os, sys
args = sys.argv[1:]
if args == ['plugin', 'list', '--json']:
    if os.environ.get('FAIL_LIST'):
        sys.exit(1)
    with open(os.environ['REGISTRY']) as src:
        print(json.dumps({'result': {'plugins': json.load(src)}}))
else:
    assert args[:2] in (['plugin', 'install'], ['plugin', 'link'], ['plugin', 'disable'])
    assert '--yes' not in args
    if args[1] == 'install':
        assert os.read(0, 15) == b'terminal-input\n', 'installer lost stdin'
    with open(os.environ['CALLS'], 'a') as out:
        out.write(json.dumps(args) + '\n')
    if os.environ.get('FAIL_INSTALL'):
        sys.exit(1)
""")

        def run(script, *args, ok=True, extra=None):
            result = subprocess.run(
                ['bash', str(REPO / 'dot_local/bin' / script), *args],
                env=env | (extra or {}), input='terminal-input\n' * 20,
                text=True, capture_output=True,
            )
            assert (result.returncode == 0) == ok, result.stdout + result.stderr
            return result

        local = home / 'tools/local plugin'
        local.mkdir(parents=True)
        (local / 'herdr-plugin.toml').write_text('id = "test.local"\n')
        entries = [
            {'plugin_id': 'test.floating', 'enabled': True,
             'source': {'kind': 'github', 'owner': 'example', 'repo': 'floating',
                        'resolved_commit': 'a' * 40, 'managed_path': str(home / 'cache')}},
            {'plugin_id': 'test.pinned', 'enabled': False,
             'source': {'kind': 'github', 'owner': 'example', 'repo': 'collection',
                        'subdir': 'plugins/demo', 'requested_ref': 'v1.2.3'}},
            {'plugin_id': 'test.local', 'enabled': False,
             'source': {'kind': 'local'}, 'plugin_root': str(local)},
            {'plugin_id': 'test.present', 'enabled': True,
             'source': {'kind': 'github', 'owner': 'example', 'repo': 'present'}},
        ]
        registry.write_text(json.dumps(entries))
        run('backup-packages', '--herdr')
        saved = inventory.read_text()
        records = json.loads(saved)
        assert [r['id'] for r in records] == sorted(e['plugin_id'] for e in entries)
        assert records[0]['ref'] is None
        assert records[1]['source'] == 'tools/local plugin'
        assert records[2]['source'] == 'example/collection/plugins/demo'
        assert records[2]['ref'] is None and records[2]['enabled'] is False
        assert str(home) not in saved and 'resolved_commit' not in saved
        run('backup-packages', '--interactive')
        assert inventory.with_suffix('.json.bak').read_text() == saved

        run('backup-packages', '--herdr', ok=False, extra={'FAIL_LIST': '1'})
        assert inventory.read_text() == saved
        for invalid in [None, [{'source': {'kind': 'unknown'}}],
                        [dict(entries[2], plugin_root='/outside/home/plugin')]]:
            registry.write_text(json.dumps(invalid))
            run('backup-packages', '--herdr', ok=False)
            assert inventory.read_text() == saved
        registry.write_text('[]')
        run('backup-packages', '--herdr')
        assert json.loads(inventory.read_text()) == []
        inventory.write_text(saved)

        # Existing plugins are left alone, even if their enabled state differs.
        registry.write_text(json.dumps([dict(entries[3], enabled=False)]))
        result = run('restore-packages')
        assert '[SKIP] test.present' in result.stdout
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        assert calls == [
            ['plugin', 'install', 'example/floating'],
            ['plugin', 'link', str(local), '--disabled'],
            ['plugin', 'install', 'example/collection/plugins/demo', '--ref', 'v1.2.3'],
            ['plugin', 'disable', 'test.pinned'],
        ], calls
        registry.write_text(json.dumps(entries))
        run('restore-packages')
        assert len(log.read_text().splitlines()) == len(calls)

        # Invalid inventories and unreadable live state must not cause installs.
        for invalid in [None, records + [records[0]],
                        [dict(records[0], enabled='false')],
                        [dict(records[1], source='../escape')],
                        [dict(records[1], source='/absolute/path')]]:
            inventory.write_text(json.dumps(invalid))
            run('restore-packages', ok=False)
        inventory.write_text(saved)
        run('restore-packages', ok=False, extra={'FAIL_LIST': '1'})
        registry.write_text(json.dumps([dict(entries[0], warnings=['manifest unavailable'])]))
        run('restore-packages', ok=False)
        assert len(log.read_text().splitlines()) == len(calls)

        registry.write_text('[]')
        inventory.write_text(json.dumps([records[1]]))
        run('restore-packages', ok=False, extra={'CANCEL': '1'})
        (local / 'herdr-plugin.toml').unlink()
        run('restore-packages', ok=False)
        assert len(log.read_text().splitlines()) == len(calls)
        inventory.write_text(json.dumps([records[2]]))
        result = run('restore-packages', ok=False, extra={'FAIL_INSTALL': '1'})
        assert '¡Instalación completada!' not in result.stdout
        assert len(log.read_text().splitlines()) == len(calls) + 1
        print('Herdr package backup/restore checks passed')


if __name__ == '__main__':
    check()
