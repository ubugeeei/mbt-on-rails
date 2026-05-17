#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
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

    if failures:
        print("Template asset validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("Template assets OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
