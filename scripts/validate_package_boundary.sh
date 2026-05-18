#!/usr/bin/env bash
set -euo pipefail

moon package --list

python3 - <<'PY'
from pathlib import Path
import zipfile
import json
import subprocess
import sys
import tempfile

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

with tempfile.TemporaryDirectory(prefix="mbor-package-consumer-") as tmp:
    tmp_path = Path(tmp)
    package_dir = tmp_path / "package"
    consumer_dir = tmp_path / "consumer"
    consumer_dir.mkdir()
    with zipfile.ZipFile(package_path) as package:
        package.extractall(package_dir)

    (consumer_dir / "moon.mod.json").write_text(
        json.dumps(
            {
                "name": "codex/mbt_on_rails_package_consumer",
                "version": "0.1.0",
                "readme": "README.mbt.md",
                "repository": "",
                "license": "Apache-2.0",
                "keywords": [],
                "description": "External consumer smoke test for the packaged mbt_on_rails artifact.",
                "deps": {
                    "ubugeeei/mbt_on_rails": {
                        "path": "../package",
                    }
                },
            },
            indent=2,
        )
    )
    (consumer_dir / "moon.pkg").write_text(
        'import { "ubugeeei/mbt_on_rails" @mbor }\n'
    )
    (consumer_dir / "consumer.mbt").write_text(
        "///|\n"
        "pub fn smoke_path() -> String {\n"
        "  @mbor.normalize_path(\"posts/42\")\n"
        "}\n"
        "\n"
        "///|\n"
        "pub fn smoke_response() -> @mbor.Response {\n"
        "  @mbor.ok_json(\"{\\\"ok\\\":true}\")\n"
        "}\n"
    )
    result = subprocess.run(
        ["moon", "check"],
        cwd=consumer_dir,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode != 0:
        print("Packaged artifact failed external consumer smoke check.", file=sys.stderr)
        print(result.stdout, file=sys.stderr)
        sys.exit(result.returncode)

print(
    f"Package boundary OK: {len(entries)} files/directories checked in {package_path.name}; external consumer moon check passed."
)
PY
