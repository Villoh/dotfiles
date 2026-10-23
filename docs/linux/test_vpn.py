#!/usr/bin/env python3
"""Run with python3 docs/linux/test_vpn.py. No network, sudo, or real services."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

SCRIPTS = Path(__file__).resolve().parents[2] / "dot_local/bin"
BASH = shutil.which("bash") or ""
assert BASH and shutil.which("jq"), "Tests require bash and jq"

# Only these stubs are reachable through fake sudo. Never run its arguments on the host.
STUB = r'''
import json, os, pathlib, subprocess, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
trace = pathlib.Path(os.environ["TRACE"])
def log(row):
    with trace.open("a") as f:
        f.write(json.dumps(row) + "\n")
log([name, *args])
statefile = pathlib.Path(os.environ["STATE"])
state = json.loads(statefile.read_text())
def save(): statefile.write_text(json.dumps(state))
if name == "sudo":
    if args[:2] == ["test", "-f"]:
        sys.exit(0 if os.environ.get("AUTH", "1") == "1" else 1)
    if args[:2] == ["sh", "-c"]:
        sys.exit(int(os.environ.get("LOAD_FAIL", "0")))
    if args and args[0] in ("systemctl", "systemd-run", "swanctl"):
        sys.exit(subprocess.call([str(pathlib.Path(sys.argv[0]).parent / args[0]), *args[1:]]))
    sys.exit("Unexpected sudo invocation")
if name == "systemctl":
    if args[0] == "is-active":
        unit = args[-1]
        active = unit in state.get("active", [])
        value = state.get("service", "inactive") if unit == "strongswan" else state.get("openvpn_state", "active" if active else "inactive")
        if "--quiet" not in args: print(value)
        sys.exit(0 if value == "active" else 3)
    if args[0] == "show":
        print("ActiveState=inactive\nSubState=dead\nResult=success")
    if args[0] == "start":
        state["service"] = "active"
        save()
    if args[0] == "stop":
        sys.exit(int(os.environ.get("STOP_FAIL", "0")))
if name == "systemd-run":
    sys.exit(int(os.environ.get("RUN_FAIL", "0")))
if name == "getent":
    sys.exit(int(os.environ.get("DNS_FAIL", "0")))
if name == "swanctl":
    if "--list-sas" in args:
        if os.environ.get("SAS_FAIL") == "1": sys.exit(1)
        if state.get("tunnel"): print("nordvpn: #1, ESTABLISHED, IKEv2")
    if "--initiate" in args:
        if os.environ.get("INIT_FAIL") == "1": sys.exit(1)
        state["tunnel"] = os.environ.get("NO_TUNNEL") != "1"
        save()
    if "--terminate" in args:
        if os.environ.get("TERM_FAIL") == "1": sys.exit(1)
        state["tunnel"] = False
        save()
if name == "curl":
    if os.environ.get("API_FAIL") == "1": sys.exit(22)
    url = args[-1]
    if os.environ.get("API_BAD") == "1":
        print("not json")
        sys.exit(0)
    if "/countries" in url:
        print(json.dumps([{"code": "ES", "id": 209, "name": "Spain"}]))
    elif "recommendations" in url:
        print(json.dumps([] if os.environ.get("EMPTY_SERVERS") == "1" else [{"load": 10, "hostname": os.environ.get("API_HOST", "es123.nordvpn.com"), "locations": [{"country": {"city": {"name": "Madrid"}}}]}]))
    else:
        print(json.dumps([{"load": 10, "hostname": os.environ.get("API_HOST", "es123.nordvpn.com"), "status": "online", "technologies": [{"identifier": "ikev2"}]}]))
if name == "fzf":
    rows = sys.stdin.read().splitlines()
    log(["choices", *rows])
    if os.environ.get("CANCEL") == "1" or not rows: sys.exit(130)
    print(rows[0])
'''

with tempfile.TemporaryDirectory(prefix="vpn-test-") as directory:
    root = Path(directory)
    home, bin_dir = root / "home", root / "bin"
    home.mkdir()
    bin_dir.mkdir()
    stub = bin_dir / "stub"
    stub.write_text(f"#!{sys.executable}\n" + STUB)
    stub.chmod(0o755)
    for name in ("sudo", "systemctl", "systemd-run", "openvpn", "swanctl", "getent", "curl", "fzf"):
        (bin_dir / name).symlink_to(stub)
    for relative in ("nordvpn/ovpn_udp/es123.nordvpn.com.udp.ovpn", "nordvpn/ovpn_udp/es123.nordvpn.com.udp_2.6.ovpn", "nordvpn/ovpn_tcp/es123.nordvpn.com.tcp.ovpn", "vpnd/udp/example.ovpn", "vpnd/tcp/example.ovpn"):
        path = home / ".config/openvpn" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("client\n")
    statefile, trace = root / "state.json", root / "trace.jsonl"

    def run(script, *args, state=None, env=None, input=None, ok=True):
        statefile.write_text(json.dumps(state or {}))
        trace.write_text("")
        variables = {**os.environ, "HOME": str(home), "PATH": f"{bin_dir}:{os.environ['PATH']}", "STATE": str(statefile), "TRACE": str(trace), **(env or {})}
        result = subprocess.run([BASH, str(SCRIPTS / script), *args], input=input, text=True, capture_output=True, env=variables, timeout=10)
        events = [json.loads(line) for line in trace.read_text().splitlines()]
        assert (result.returncode == 0) == ok, (script, args, result.returncode, result.stdout, result.stderr)
        return result, events

    for script in ("ovpn", "ikev2"):
        for args in ((), ("--help",)):
            result, events = run(script, *args)
            assert "Uso:" in result.stdout and not events
        for args in (("bogus",), ("stop", "../../bad"), ("status", "extra", "extra")):
            _, events = run(script, *args, ok=False)
            assert not any(row[0] == "sudo" for row in events)

    for args in (("start", "../../bad", "udp", "nordvpn"), ("start", "es123", "invalid", "nordvpn"), ("start", "es123", "udp", "unknown"), ("start", "es123", "--limit", "0"), ("start", "es123", "--limit")):
        _, events = run("ovpn", *args, ok=False)
        assert not any(row[0] == "sudo" for row in events)
    result, events = run("ovpn", "start", "es123", "udp", "nordvpn")
    launch = next(row for row in events if row[0] == "systemd-run")
    assert "--unit=openvpn-vpn-nordvpn.service" in launch and "--expand-environment=no" in launch
    assert "--auth-nocache" in launch and "--daemon" not in launch
    assert launch[launch.index("--auth-user-pass") + 1] == "/etc/openvpn/nordvpn/auth"
    assert "no confirma" in result.stdout
    _, events = run("ovpn", "start", "example")
    assert any(row[0] == "systemd-run" and "--unit=openvpn-vpn-vpnd.service" in row for row in events)
    _, events = run("ovpn", "start", "es123", "udp", "nordvpn", env={"AUTH": "0"}, ok=False)
    assert not any(row[0] == "systemd-run" for row in events)
    run("ovpn", "start", "es123", "udp", "nordvpn", env={"RUN_FAIL": "1"}, ok=False)
    _, events = run("ovpn", "start", "es123", "udp", "nordvpn", state={"active": ["openvpn-vpn-nordvpn.service"]}, env={"STOP_FAIL": "1"}, ok=False)
    assert not any(row[0] == "systemd-run" for row in events)
    _, events = run("ovpn", "start", "--limit", "7")
    assert any(row[0] == "curl" and "limit=7" in row[-1] for row in events)
    for env in ({"API_FAIL": "1"}, {"API_BAD": "1"}, {"EMPTY_SERVERS": "1"}):
        _, events = run("ovpn", "start", env=env)
        assert ["choices", "local\t?\tes123"] in events, "Fallback must deduplicate OpenVPN variants"
    _, events = run("ovpn", "start", env={"API_HOST": "es123.nordvpn.com;id"}, ok=False)
    assert not any(row[0] == "sudo" for row in events)
    _, events = run("ovpn", "start", env={"CANCEL": "1"}, ok=False)
    assert not any(row[0] == "sudo" for row in events)
    # Exercise the vpnd selector without the NordVPN directory.
    (home / ".config/openvpn/nordvpn").rename(home / "nordvpn-hidden")
    _, events = run("ovpn", "start")
    assert any(row[0] == "systemd-run" and "--unit=openvpn-vpn-vpnd.service" in row for row in events)
    run("ovpn", "status")
    _, events = run("ovpn", "stop")
    assert not any(row[0] == "sudo" for row in events)
    _, events = run("ovpn", "stop", "all", state={"active": ["openvpn-vpn-nordvpn.service", "openvpn-vpn-vpnd.service"]})
    assert sum(row[:3] == ["sudo", "systemctl", "stop"] for row in events) == 2
    run("ovpn", "stop", state={"openvpn_state": "unknown"}, ok=False)
    _, events = run("ovpn", "start", "example", state={"openvpn_state": "unknown"}, ok=False)
    assert not any(row[0] == "systemd-run" for row in events)

    for server in ("../../bad", "es123.nordvpn.com;id", "es123.other.com", "-es123.nordvpn.com"):
        _, events = run("ikev2", "start", server, ok=False)
        assert not any(row[0] == "sudo" for row in events)
    _, events = run("ikev2", "start", "es123.nordvpn.com", env={"DNS_FAIL": "1"}, ok=False)
    assert not any(row[0] == "sudo" for row in events)
    _, events = run("ikev2", "start", "ES123.NORDVPN.COM")
    load = next(row for row in events if row[:3] == ["sudo", "sh", "-c"])
    assert load[-1] == "es123.nordvpn.com" and "include /etc/swanctl/swanctl.conf" in load[3]
    assert "remote_addrs = %s" in load[3] and "sed" not in load[3]
    assert ["sudo", "swanctl", "--initiate", "--child", "nordvpn"] in events
    for env in ({"LOAD_FAIL": "1"}, {"INIT_FAIL": "1"}, {"NO_TUNNEL": "1"}):
        run("ikev2", "start", "es123.nordvpn.com", env=env, ok=False)
    _, events = run("ikev2", "start", "es123.nordvpn.com", state={"service": "active", "tunnel": True}, ok=False)
    assert not any(row[:3] == ["sudo", "systemctl", "start"] for row in events)
    run("ikev2", "start", input="1\n1\n")
    run("ikev2", "start", input="q\n", ok=False)
    for env in ({"API_FAIL": "1"}, {"API_BAD": "1"}, {"API_HOST": "es123.nordvpn.com;id"}):
        _, events = run("ikev2", "start", input="1\n1\n", env=env, ok=False)
        assert not any(row[0] == "sudo" for row in events)
    run("ikev2", "status")
    run("ikev2", "status", state={"service": "unknown"}, ok=False)
    run("ikev2", "status", state={"service": "active"}, env={"SAS_FAIL": "1"}, ok=False)
    run("ikev2", "stop")
    _, events = run("ikev2", "stop", state={"service": "active", "tunnel": True})
    assert ["sudo", "swanctl", "--terminate", "--ike", "nordvpn"] in events
    assert not any(row[0] == "systemctl" and any(arg in row for arg in ("stop", "restart")) for row in events)
    run("ikev2", "stop", state={"service": "active", "tunnel": True}, env={"TERM_FAIL": "1"}, ok=False)

print("VPN regression checks passed (mocked commands; no real VPN connection).")
