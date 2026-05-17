#!/usr/bin/env bash
set -euo pipefail

moon package --list

python3 - <<'PY'
from pathlib import Path
import zipfile
import sys

publish_dir = Path("_build/publish")
packages = sorted(
    publish_dir.glob("*.zip"),
    key=lambda path: path.stat().st_mtime,
    reverse=True,
)

if not packages:
    print("Package artifact was not created under _build/publish.", file=sys.stderr)
    sys.exit(1)

package_path = packages[0]
with zipfile.ZipFile(package_path) as package:
    entries = {
        name.rstrip("/")
        for name in package.namelist()
        if name.rstrip("/")
    }

blocked_roots = {".github", "app", "cmd", "examples", "scripts", "tests"}
blocked_prefixes = tuple(root + "/" for root in blocked_roots)
blocked = [
    entry
    for entry in entries
    if entry in blocked_roots or entry.startswith(blocked_prefixes)
]

required = {
    "moon.mod.json",
    "moon.pkg",
    "README.mbt.md",
    "LICENSE",
    "mbt_on_rails.mbt",
    "pkg.generated.mbti",
    "src/app/runtime.mbt",
    "src/auth/session.mbt",
    "src/view/render.mbt",
}
missing = sorted(required.difference(entries))

if blocked:
    print("Package artifact contains non-production paths:", file=sys.stderr)
    for entry in blocked[:40]:
        print(f"  - {entry}", file=sys.stderr)
    if len(blocked) > 40:
        print(f"  ... and {len(blocked) - 40} more", file=sys.stderr)
    sys.exit(1)

if missing:
    print("Package artifact is missing required production paths:", file=sys.stderr)
    for entry in missing:
        print(f"  - {entry}", file=sys.stderr)
    sys.exit(1)

print(
    f"Package boundary OK: {len(entries)} files/directories checked in {package_path.name}."
)
PY
