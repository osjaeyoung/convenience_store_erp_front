#!/usr/bin/env python3
"""Remove const from patterns that use ScreenUtil extensions (.w .h .r .sp)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"


def fix_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text

    # static const TextStyle name = TextStyle(  -> static TextStyle get name => TextStyle(
    text = re.sub(
        r"static const TextStyle (\w+) = TextStyle\(",
        r"static TextStyle get \1 => TextStyle(",
        text,
    )

    # static const EdgeInsets ... = EdgeInsets.*(... .[whr] ...
    text = re.sub(
        r"static const EdgeInsets (\w+) =\s*\n?\s*EdgeInsets\.",
        r"static EdgeInsets get \1 => EdgeInsets.",
        text,
    )
    text = re.sub(
        r"static const EdgeInsets (\w+) = EdgeInsets\.",
        r"static EdgeInsets get \1 => EdgeInsets.",
        text,
    )

    # Lines like: const TextStyle( ... .sp
    text = re.sub(
        r"const TextStyle\(",
        r"TextStyle(",
        text,
    )

    # const Icon( with .r in next 3 lines — simple line-based: const Icon -> Icon if .r appears before );
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if "const Icon(" in line:
            chunk = "".join(lines[i : min(i + 6, len(lines))])
            if ".r" in chunk or ".w" in chunk or ".h" in chunk:
                line = line.replace("const Icon(", "Icon(")
        if "const Padding(" in line:
            chunk = "".join(lines[i : min(i + 12, len(lines))])
            if ".w" in chunk or ".h" in chunk or ".r" in chunk or ".sp" in chunk or "AppSpacing." in chunk:
                line = line.replace("const Padding(", "Padding(")
        out.append(line)
        i += 1
    text = "".join(out)

    # const SizedBox( height: AppSpacing or .h
    text = re.sub(
        r"const SizedBox\(\s*height:\s*AppSpacing\.",
        r"SizedBox(height: AppSpacing.",
        text,
    )

    # const EdgeInsets.... AppSpacing
    text = re.sub(
        r"const EdgeInsets\.symmetric\(\s*horizontal:\s*AppSpacing\.",
        r"EdgeInsets.symmetric(horizontal: AppSpacing.",
        text,
    )
    text = re.sub(
        r"const EdgeInsets\.fromLTRB\(\s*\n?\s*AppSpacing\.",
        r"EdgeInsets.fromLTRB(\n  AppSpacing.",
        text,
    )

    # const BoxDecoration with BorderRadius .r
    if ".borderRadius: BorderRadius.circular" in text or "BorderRadius.circular(" in text:
        text = re.sub(
            r"const BoxDecoration\(",
            r"BoxDecoration(",
            text,
        )

    # minimumSize: const Size.fromHeight(56) when 56.h used elsewhere - generic
    text = re.sub(
        r"minimumSize:\s*const\s+Size\.fromHeight\(([0-9]+)(?![.\w])\)",
        r"minimumSize: Size.fromHeight(\1.h)",
        text,
    )

    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    for path in sorted(LIB.rglob("*.dart")):
        if fix_file(path):
            print("fixed", path.relative_to(ROOT).as_posix())


if __name__ == "__main__":
    main()
