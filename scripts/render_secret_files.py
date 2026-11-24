#!/usr/bin/env python3
"""Render the single private felddy config.json secret, without shell evaluation."""
from pathlib import Path
import json
import os
import re
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENV = ROOT / ".env"
SECRETS = ROOT / "secrets"
KEYS = ("USERNAME", "PASSWORD", "ADMIN_KEY", "LICENSE_KEY")


def fail(message):
    raise SystemExit("Configuration error: " + message)


def parse_env(path):
    if path.is_symlink() or not path.is_file():
        fail(".env must be a regular file")
    values = {}
    for number, original in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = original.strip()
        if not line or line.startswith("#"):
            continue
        name, sep, value = line.partition("=")
        name, value = name.strip(), value.strip()
        if not sep or not re.fullmatch(r"[A-Z][A-Z0-9_]*", name) or name in values:
            fail(f"invalid or duplicate key on line {number}")
        if value.startswith("'"):
            if len(value) < 2 or not value.endswith("'"):
                fail(f"unterminated quote on line {number}")
            value = value[1:-1].replace("\\'", "'")
        elif value.startswith('"'):
            if len(value) < 2 or not value.endswith('"'):
                fail(f"unterminated quote on line {number}")
            value = value[1:-1].replace('\\"', '"').replace("\\\\", "\\")
        if any(ord(c) < 32 for c in value):
            fail(f"control character on line {number}")
        values[name] = value
    return values


def main():
    os.umask(0o077)
    values = parse_env(ENV)
    ENV.chmod(0o600)
    payload = {}
    for key in KEYS:
        name = "FOUNDRY03_" + key
        value = values.get(name, "")
        if not value or "REPLACE_ME" in value:
            fail(f"set {name} in .env")
        payload["foundry_" + key.lower()] = value
    if SECRETS.is_symlink() or not SECRETS.is_dir():
        fail("secrets/ must be a regular directory")
    SECRETS.chmod(0o700)
    dest = SECRETS / "foundry03.json"
    if dest.is_symlink() or (dest.exists() and not dest.is_file()):
        fail("unsafe secrets/foundry03.json path")
    contents = (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    if dest.exists() and dest.read_bytes() == contents:
        dest.chmod(0o600)
        return
    tmp = None
    try:
        with tempfile.NamedTemporaryFile(dir=SECRETS, prefix=".new-secret-", delete=False) as output:
            tmp = Path(output.name)
            os.fchmod(output.fileno(), 0o600)
            output.write(contents)
            output.flush()
            os.fsync(output.fileno())
        os.replace(tmp, dest)
    finally:
        if tmp is not None and tmp.exists():
            tmp.unlink()
    print("Private Foundry03 secret prepared (no values printed).")


if __name__ == "__main__":
    try:
        main()
    except (OSError, UnicodeError):
        fail("unable to read or write the private configuration; check permissions")
