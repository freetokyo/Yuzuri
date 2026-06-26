#!/usr/bin/env python3
"""Preventive audit for String(format:) misuse in Yuzuri.

Background: a sibling app shipped an EXC_BAD_ACCESS crash from a `%@`
specifier fed an Int. Prefer Swift string interpolation. This is a regression
gate: if format strings are introduced, flag `%@` so the arg type is verified.

Exit 0 = clean. Exit 1 = `%@` format strings found (manual review needed).
Run from repo root: python3 scripts/audit_format_strings.py
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

SRC = Path("Yuzuri")
FORMAT_RE = re.compile(r'(String\(format:|localizedStringWithFormat|NSLocalizedString\([^)]*%)')
OBJ_SPEC_RE = re.compile(r'%(?:\d+\$)?@')


def main() -> int:
    if not SRC.is_dir():
        print(f"!! source dir not found: {SRC.resolve()}")
        return 2
    hits = []
    for swift in SRC.rglob("*.swift"):
        for i, line in enumerate(swift.read_text(encoding="utf-8").splitlines(), 1):
            if FORMAT_RE.search(line):
                hits.append((swift, i, line.strip(), bool(OBJ_SPEC_RE.search(line))))
    if not hits:
        print("OK: String(format:) は安全（%@×Int クラッシュ class なし）。")
        return 0
    risky = [h for h in hits if h[3]]
    print(f"format string usages: {len(hits)} (うち %@ 含み: {len(risky)})")
    for f, i, text, is_risky in hits:
        print(f"  {'WARN %@' if is_risky else '     '} {f}:{i}: {text}")
    if risky:
        print("\n%@ 指定子の引数型を確認（Int/Double を渡すと EXC_BAD_ACCESS）。")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
