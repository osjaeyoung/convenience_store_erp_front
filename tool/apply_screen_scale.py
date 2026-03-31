#!/usr/bin/env python3
"""Append flutter_screenutil units to common layout literals under lib/."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

IMPORT_LINE = "import 'package:flutter_screenutil/flutter_screenutil.dart';\n"

EXCLUDE_REL = {
    "lib/theme/app_typography.dart",
    "lib/theme/app_spacing.dart",
    "lib/theme/app_theme.dart",
    "lib/core/screen/app_design.dart",
}


def rel_posix(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def ensure_import(text: str) -> str:
    if "flutter_screenutil/flutter_screenutil.dart" in text:
        return text
    lines = text.splitlines(keepends=True)
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, IMPORT_LINE)
    return "".join(lines)


def _scale_edge_insets_only(match: re.Match[str]) -> str:
    body = match.group(2)

    def repl(arg_match: re.Match[str]) -> str:
        key = arg_match.group(1)
        value = arg_match.group(2)
        unit = "h" if key in {"top", "bottom"} else "w"
        return f"{key}: {value}.{unit}"

    scaled_body = re.sub(
        r"\b(left|right|top|bottom):\s*([0-9]+(?:\.[0-9]+)?)(?!\.(?:w|h|r|sp)\b)\b",
        repl,
        body,
    )
    return f"EdgeInsets.only({scaled_body})"


def apply_transforms(text: str) -> str:
    orig = text

    text = text.replace("NoneEdgeInsets.only", "EdgeInsets.only")
    text = text.replace("pw.NoneEdgeInsets.only", "pw.EdgeInsets.only")

    text = re.sub(
        r"const\s+SizedBox\(\s*height:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"SizedBox(height: \1.h)",
        text,
    )
    text = re.sub(
        r"const\s+SizedBox\(\s*width:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"SizedBox(width: \1.w)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])SizedBox\(\s*height:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"SizedBox(height: \1.h)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])SizedBox\(\s*width:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"SizedBox(width: \1.w)",
        text,
    )

    text = re.sub(
        r"const\s+SizedBox\.square\(\s*dimension:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"SizedBox.square(dimension: \1.r)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])SizedBox\.square\(\s*dimension:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"SizedBox.square(dimension: \1.r)",
        text,
    )

    text = re.sub(
        r"const\s+EdgeInsets\.all\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.all(\1.r)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])EdgeInsets\.all\(\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"EdgeInsets.all(\1.r)",
        text,
    )

    text = re.sub(
        r"const\s+EdgeInsets\.symmetric\(\s*horizontal:\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*vertical:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.symmetric(horizontal: \1.w, vertical: \2.h)",
        text,
    )
    text = re.sub(
        r"const\s+EdgeInsets\.symmetric\(\s*vertical:\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*horizontal:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.symmetric(vertical: \1.h, horizontal: \2.w)",
        text,
    )
    text = re.sub(
        r"const\s+EdgeInsets\.symmetric\(\s*horizontal:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.symmetric(horizontal: \1.w)",
        text,
    )
    text = re.sub(
        r"const\s+EdgeInsets\.symmetric\(\s*vertical:\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.symmetric(vertical: \1.h)",
        text,
    )

    text = re.sub(
        r"(?<![.\w])EdgeInsets\.symmetric\(\s*horizontal:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*,\s*vertical:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"EdgeInsets.symmetric(horizontal: \1.w, vertical: \2.h)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])EdgeInsets\.symmetric\(\s*vertical:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*,\s*horizontal:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"EdgeInsets.symmetric(vertical: \1.h, horizontal: \2.w)",
        text,
    )

    text = re.sub(
        r"const\s+EdgeInsets\.fromLTRB\(\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*\)",
        r"EdgeInsets.fromLTRB(\1.w, \2.h, \3.w, \4.h)",
        text,
    )
    text = re.sub(
        r"(?<![.\w])EdgeInsets\.fromLTRB\(\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*,\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*,\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*,\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"EdgeInsets.fromLTRB(\1.w, \2.h, \3.w, \4.h)",
        text,
    )

    text = re.sub(
        r"(const\s+)?EdgeInsets\.only\(([^)]*)\)",
        _scale_edge_insets_only,
        text,
    )

    text = re.sub(
        r"BorderRadius\.circular\(\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*\)",
        r"BorderRadius.circular(\1.r)",
        text,
    )

    text = re.sub(
        r"fontSize:\s*([0-9]+(?:\.[0-9]+)?)(?![.\w])\s*([,\)])",
        r"fontSize: \1.sp\2",
        text,
    )

    text = re.sub(r"\.(w|h|r|sp)\.\1\b", r".\1", text)

    if text != orig:
        text = ensure_import(text)
    return text


def main() -> None:
    for path in sorted(LIB.rglob("*.dart")):
        rel = rel_posix(path)
        if rel in EXCLUDE_REL:
            continue
        src = path.read_text(encoding="utf-8")
        new = apply_transforms(src)
        if new != src:
            path.write_text(new, encoding="utf-8")
            print("updated", rel)


if __name__ == "__main__":
    main()
