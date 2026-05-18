#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import difflib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLE_DIRS = [
    ROOT / "examples/demo_blog",
    ROOT / "examples/resource_app",
]


def generated_paths(generated_file: Path) -> set[str]:
    text = generated_file.read_text()
    return set(re.findall(r'@support\.mbtv_path\("([^"]+)"\)', text))


def strip_script_line(line: str) -> str:
    out: list[str] = []
    in_string = False
    quote = ""
    escaped = False
    index = 0
    while index < len(line):
        ch = line[index]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                in_string = False
            out.append(" ")
            index += 1
            continue
        if ch in {'"', "'"}:
            in_string = True
            quote = ch
            out.append(" ")
            index += 1
            continue
        if ch == "/" and index + 1 < len(line) and line[index + 1] == "/":
            break
        out.append(ch)
        index += 1
    return "".join(out)


def component_imports(source: str) -> set[str]:
    match = re.search(r"<script setup>(.*?)</script>", source, re.S)
    if not match:
        return set()
    imports: set[str] = set()
    for line in match.group(1).splitlines():
        cleaned = strip_script_line(line)
        for name in re.findall(r"\bcomponent\s+([A-Z][A-Za-z0-9]*)", cleaned):
            imports.add(name)
    return imports


def component_usages(source: str) -> set[str]:
    match = re.search(r"<template>(.*?)</template>", source, re.S)
    if not match:
        return set()
    return set(re.findall(r"<([A-Z][A-Za-z0-9]*)\b", match.group(1)))


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def run_generator(
    package_dir: Path,
    frontend_path: Path,
    output_path: Path,
    target: str = "native",
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "moon",
            "run",
            "--target",
            target,
            "cmd/generate_example_types",
            "--",
            relative(package_dir),
            relative(frontend_path),
            str(output_path),
        ],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def run_generator_without_args(target: str = "native") -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "moon",
            "run",
            "--target",
            target,
            "cmd/generate_example_types",
        ],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def run_native_generator_binary_without_args() -> subprocess.CompletedProcess[str]:
    build_result = subprocess.run(
        ["moon", "build", "--target", "native", "cmd/generate_example_types"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if build_result.returncode != 0:
        return build_result
    binary = ROOT / "_build/native/debug/build/cmd/generate_example_types/generate_example_types.exe"
    return subprocess.run(
        [str(binary)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def validate_generated_types(example: Path, failures: list[str]) -> None:
    checked_in = example / "generated_types.mbt"
    generated: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix="generated_types.check.",
            suffix=".mbt",
            dir=example,
            delete=False,
        ) as tmp:
            generated = Path(tmp.name)
        result = run_generator(example, example / "frontend.mbt", generated)
        if (
            result.returncode != 0
            or "generate_example_types:" in result.stdout
            or generated.stat().st_size == 0
        ):
            failures.append(
                f"{example.name}: generated type regeneration failed:\n{result.stdout.strip()}"
            )
            return

        with tempfile.TemporaryDirectory(prefix="mbor-generated-types-build-") as build_tmp:
            format_result = subprocess.run(
                ["moon", "fmt", "--target-dir", build_tmp, str(generated)],
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
        if format_result.returncode != 0:
            failures.append(
                f"{example.name}: regenerated type formatting failed:\n{format_result.stdout.strip()}"
            )
            return

        expected = checked_in.read_text()
        actual = generated.read_text()
        if expected != actual:
            diff = "\n".join(
                difflib.unified_diff(
                    expected.splitlines(),
                    actual.splitlines(),
                    fromfile=relative(checked_in),
                    tofile=f"regenerated/{checked_in.name}",
                    lineterm="",
                )
            )
            failures.append(f"{example.name}: generated_types.mbt is stale:\n{diff}")
    finally:
        if generated is not None:
            generated.unlink(missing_ok=True)


def validate_generator_fail_fast(failures: list[str]) -> None:
    with tempfile.TemporaryDirectory(prefix="mbor-generator-fail-fast-") as tmp:
        tmp_path = Path(tmp)
        usage_result = run_native_generator_binary_without_args()
        if usage_result.returncode == 0:
            failures.append("generator CLI invalid usage exited successfully")
        if "generate_example_types: invalid arguments" not in usage_result.stdout:
            failures.append("generator CLI invalid usage did not print a fail-fast diagnostic")

        cases = [
            (
                "missing package views",
                ROOT / "examples/missing_blog",
                ROOT / "examples/demo_blog/frontend.mbt",
                tmp_path / "missing_package.mbt",
            ),
            (
                "missing frontend source",
                ROOT / "examples/demo_blog",
                ROOT / "examples/demo_blog/missing_frontend.mbt",
                tmp_path / "missing_frontend.mbt",
            ),
            (
                "missing output directory",
                ROOT / "examples/demo_blog",
                ROOT / "examples/demo_blog/frontend.mbt",
                tmp_path / "missing" / "generated_types.mbt",
            ),
        ]
        for label, package_dir, frontend_path, output_path in cases:
            result = run_generator(package_dir, frontend_path, output_path)
            diagnosed = "generate_example_types:" in result.stdout
            wrote_output = output_path.exists() and output_path.stat().st_size > 0
            if not diagnosed:
                failures.append(f"generator CLI did not fail fast for {label}")
            if wrote_output:
                failures.append(f"generator CLI wrote output after {label}")

        for target in ("js", "wasm-gc"):
            output_path = tmp_path / f"unsupported_{target}.mbt"
            result = run_generator(
                ROOT / "examples/demo_blog",
                ROOT / "examples/demo_blog/frontend.mbt",
                output_path,
                target=target,
            )
            diagnosed = "generate_example_types: unsupported target" in result.stdout
            wrote_output = output_path.exists() and output_path.stat().st_size > 0
            if not diagnosed:
                failures.append(f"generator CLI did not reject unsupported target {target}")
            if wrote_output:
                failures.append(f"generator CLI wrote output for unsupported target {target}")


def main() -> int:
    failures: list[str] = []
    for example in EXAMPLE_DIRS:
        generated = generated_paths(example / "generated_types.mbt")
        actual = {
            path.relative_to(ROOT).as_posix()
            for path in (example / "views").rglob("*.mbtv")
        }

        for missing in sorted(generated.difference(actual)):
            failures.append(f"{example.name}: generated path missing on disk: {missing}")
        for unlisted in sorted(actual.difference(generated)):
            failures.append(f"{example.name}: template missing generated helper: {unlisted}")

        for relative in sorted(actual):
            path = ROOT / relative
            source = path.read_text()
            imports = component_imports(source)
            usages = component_usages(source)
            for usage in sorted(usages.difference(imports)):
                failures.append(f"{relative}: missing component import for <{usage}>")
            for imported in sorted(imports.difference(usages)):
                failures.append(f"{relative}: unused component import {imported}")

        validate_generated_types(example, failures)

    validate_generator_fail_fast(failures)

    if failures:
        print("Template asset validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("Template assets and generated helpers OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
