#!/usr/bin/env python3
"""Run with python3 dev/test_omarchy_packages.py; no network or real installs."""

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
        plugins = home / ".config/omarchy/plugins"
        plugins.mkdir(parents=True)
        source = root / "source"
        bins = root / "bin"
        bins.mkdir()
        log = root / "calls"
        env = dict(os.environ, HOME=str(home), SOURCE=str(source), CALLS=str(log),
                   PATH=f"{bins}:{os.environ['PATH']}")

        def stub(name, code):
            path = bins / name
            path.write_text(f"#!{sys.executable}\n" + code)
            path.chmod(0o755)

        stub("chezmoi", "import os; print(os.environ['SOURCE'])\n")
        stub("gum", r"""import sys
args = sys.argv[1:]
if args[0] == 'choose':
    if '🧩 omarchy' in args:
        print('🧩 omarchy')
    elif '✓ Sí, usar chezmoi/packages/linux/' in args:
        print('✓ Sí, usar chezmoi/packages/linux/')
    else:
        print('\n'.join(a for a in args if a.startswith(('https://', '--bad'))))
elif args[0] == 'style':
    print(args[-1])
""")
        stub("omarchy", r"""import json, os, sys
assert sys.stdin.readline() == 'terminal-input\n', 'installer lost stdin'
with open(os.environ['CALLS'], 'a') as out:
    out.write(json.dumps(sys.argv[1:]) + '\n')
sys.exit(int(os.environ.get('FAIL_OMARCHY', '0')))
""")

        def run(script, *args, ok=True, extra=None):
            result = subprocess.run(
                ['bash', str(REPO / 'dot_local/bin' / script), *args],
                env=env | (extra or {}), input='terminal-input\n',
                text=True, capture_output=True,
            )
            assert (result.returncode == 0) == ok, result.stdout + result.stderr
            return result

        def plugin(name, url=None):
            path = plugins / name
            subprocess.run(['git', 'init', '-q', str(path)], check=True)
            if url:
                subprocess.run(['git', '-C', str(path), 'remote', 'add', 'origin', url], check=True)
            return path

        present = 'https://github.com/example/present.git'
        missing = 'https://github.com/example/missing.git'
        installed = plugin('example.present', present)
        (installed / 'local-change.txt').write_text('not backed up')
        (plugins / 'custom.local').mkdir()
        plugin('example.duplicate', present)
        inventory = source / 'packages/linux/omarchy-plugins.txt'

        result = run('backup-packages', '--omarchy')
        assert inventory.read_text() == present + '\n'
        assert 'local changes are NOT included' in result.stderr
        assert 'back up this plugin separately' in result.stderr
        run('backup-packages', '--interactive')
        assert inventory.with_suffix('.txt.bak').read_text() == present + '\n'

        broken = plugin('example.broken')
        run('backup-packages', '--omarchy', ok=False)
        assert inventory.read_text() == present + '\n'
        broken.rename(root / 'broken')
        plugins.rename(root / 'saved-plugins')
        run('backup-packages', '--omarchy')
        assert inventory.read_text() == present + '\n'
        plugins.mkdir()
        run('backup-packages', '--omarchy')
        assert inventory.read_text() == ''
        plugins.rmdir()
        (root / 'saved-plugins').rename(plugins)

        inventory.write_text(present + '\n' + missing + '\n' + missing + '\n')
        result = run('restore-packages')
        assert '[SKIP]' in result.stdout
        assert log.read_text() == '["plugin", "add", "' + missing + '"]\n'
        result = run('restore-packages', ok=False, extra={'FAIL_OMARCHY': '1'})
        assert '¡Instalación completada!' not in result.stdout
        calls = log.read_text()
        inventory.write_text('--bad-option\n')
        run('restore-packages', ok=False)
        assert log.read_text() == calls
        print('Omarchy package backup/restore checks passed')


if __name__ == '__main__':
    check()
