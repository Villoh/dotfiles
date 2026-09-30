#!/usr/bin/env python3
"""Offline check: python3 dev/test_mise_packages.py. No real installs/updates."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def check():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        bins = root / "bin"
        bins.mkdir()
        source = root / "source"
        inventory = source / "packages/linux/mise-tools.txt"
        registry = root / "registry.json"
        log = root / "calls.jsonl"
        gum_log = root / "gum.jsonl"
        env = dict(os.environ, PATH=str(bins), SOURCE=str(source),
                   REGISTRY=str(registry), CALLS=str(log), GUM_CALLS=str(gum_log))
        # Isolated PATH prevents accidental use of real package managers.
        for name in ("bash", "mkdir", "dirname", "basename", "cp", "wc", "jq", "awk", "cat"):
            binary = shutil.which(name)
            assert binary, f"Required command missing: {name}"
            (bins / name).symlink_to(binary)

        def stub(name, code):
            path = bins / name
            path.write_text(f"#!{sys.executable}\n" + code)
            path.chmod(0o755)

        stub("chezmoi", "import os; print(os.environ['SOURCE'])\n")
        stub("gum", r'''import json, os, sys
args = sys.argv[1:]
with open(os.environ['GUM_CALLS'], 'a') as out:
    out.write(json.dumps(args) + '\n')
if args[0] == 'choose':
    if '🧰 mise' in args:
        print('🧰 mise')
    elif '✓ Sí, usar chezmoi/packages/linux/' in args:
        print('✎ No, quiero elegir otras ubicaciones' if os.environ.get('CUSTOM_FILE')
              else '✓ Sí, usar chezmoi/packages/linux/')
    else:
        print(os.environ.get('SELECT', '\n'.join(a for a in args if '@' in a)))
elif args[0] == 'input':
    print(os.environ['CUSTOM_FILE'])
elif args[0] == 'style':
    print(args[-1])
''')
        stub("mise", r'''import json, os, sys
args = sys.argv[1:]
with open(os.environ['CALLS'], 'a') as out:
    out.write(json.dumps(args) + '\n')
if args == ['ls', '--installed', '--json']:
    if os.environ.get('FAIL_LIST'):
        sys.exit(1)
    print(open(os.environ['REGISTRY']).read())
elif args[0] == 'install':
    assert args[1] == '--' and len(args) == 3
    assert os.read(0, 15) == b'terminal-input\n', 'installer lost stdin'
    sys.exit(int(os.environ.get('FAIL_INSTALL', '0')))
elif args == ['upgrade']:
    assert os.read(0, 15) == b'terminal-input\n', 'updater lost stdin'
    sys.exit(int(os.environ.get('FAIL_UPDATE', '0')))
else:
    raise AssertionError(args)
''')

        def run(script, *args, ok=True, extra=None):
            result = subprocess.run(
                [str(bins / "bash"), str(REPO / "dot_local/bin" / script), *args],
                env=env | (extra or {}), input="terminal-input\n" * 20,
                text=True, capture_output=True,
            )
            assert (result.returncode == 0) == ok, result.stdout + result.stderr
            return result

        def calls(command):
            return [args for line in log.read_text().splitlines()
                    if (args := json.loads(line))[0] == command]

        registry.write_text(json.dumps({
            "node": [{"version": "22.1.0"}, {"version": "20.11.1"},
                     {"version": "22.1.0"}, {"version": "system"}],
            "npm:@example/tool": [{"version": "1.2.3"}],
            "aqua:cli/cli": [{"version": "2.70.0"}],
            "python": [{"version": "3.12.0", "symlinked_to": "/external/python"}],
        }))
        saved = "aqua:cli/cli@2.70.0\nnode@20.11.1\nnode@22.1.0\nnpm:@example/tool@1.2.3\n"
        result = run("backup-packages", "--mise")
        assert inventory.read_text() == saved
        assert "system/linked versions omitted" in result.stderr
        run("backup-packages", "--interactive")
        assert inventory.with_suffix(".txt.bak").read_text() == saved
        run("backup-packages")  # Default backup reaches mise even without pacman.
        assert inventory.read_text() == saved
        run("backup-packages", "--mise", ok=False, extra={"FAIL_LIST": "1"})
        assert inventory.read_text() == saved
        for invalid in ("broken JSON", "null", "[]", '{"node":{}}',
                        '{"node":[{}]}', '{"node":[{"version":42}]}',
                        '{"bad tool":[{"version":"1"}]}',
                        json.dumps({"node": [{"version": "20\n"}]}),
                        json.dumps({"node\n": [{"version": "20"}]})):
            registry.write_text(invalid)
            run("backup-packages", "--mise", ok=False)
            assert inventory.read_text() == saved
        registry.write_text("{}")
        run("backup-packages", "--mise")
        assert inventory.read_text() == ""
        inventory.write_text(saved)
        (bins / "jq").unlink()
        run("backup-packages", "--mise", ok=False)
        assert inventory.read_text() == saved
        jq = shutil.which("jq")
        assert jq
        (bins / "jq").symlink_to(jq)

        run("restore-packages", "--mise")
        expected = [["install", "--", spec] for spec in saved.splitlines()]
        assert calls("install") == expected
        run("restore-packages", extra={"SELECT": "node@22.1.0"})
        assert calls("install")[-1] == ["install", "--", "node@22.1.0"]
        custom = root / "custom tools.txt"
        custom.write_text("npm:@example/tool@1.2.3")  # No final newline.
        run("restore-packages", extra={"CUSTOM_FILE": str(custom)})
        assert calls("install")[-1] == ["install", "--", "npm:@example/tool@1.2.3"]
        count = len(calls("install"))
        for invalid in ("node@22.1.0\n--help\n", "node\n", "node@\n", "node@1 2\n", ""):
            inventory.write_text(invalid)
            run("restore-packages", "--mise", ok=False)
            assert len(calls("install")) == count
        inventory.write_text(saved)
        result = run("restore-packages", "--mise", ok=False, extra={"FAIL_INSTALL": "1"})
        assert "¡Instalación completada!" not in result.stdout
        assert "--mise" in run("restore-packages", "--help").stdout

        run("update-packages", "--mise")
        run("update-packages", "mise")
        run("update-packages", "--all")
        run("update-packages")
        assert calls("upgrade") == [["upgrade"]] * 4
        run("update-packages", "--mise", ok=False, extra={"FAIL_UPDATE": "1"})
        (bins / "gum").rename(bins / "gum-disabled")
        run("update-packages", "--mise")  # Explicit update needs no menu dependency.
        run("update-packages", "--mise", ok=False, extra={"FAIL_UPDATE": "1"})
        (bins / "gum-disabled").rename(bins / "gum")
        (bins / "mise").rename(bins / "mise-disabled")
        run("backup-packages", "--mise")
        assert inventory.read_text() == saved
        run("restore-packages", "--mise", ok=False)
        run("update-packages", "--mise", ok=False)
        (bins / "mise-disabled").rename(bins / "mise")
        inventory.unlink()
        run("restore-packages", "--mise", ok=False)
        print("mise Bash backup/restore/update checks passed")


if __name__ == "__main__":
    check()
