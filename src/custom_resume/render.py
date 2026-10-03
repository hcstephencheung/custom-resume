"""Render resume templates to PDF with Typst.

A template is a directory under `templates/` containing `resume.typ` and,
optionally, `mock.yaml` with sample content for previewing it. The template
receives its data as a JSON string in `sys.inputs.data`.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import typst
import yaml

# Fonts are vendored so output is identical on every machine.
FONTS_DIR = Path(__file__).resolve().parents[2] / "fonts"


def render_pdf(template_dir: Path, context: dict[str, Any]) -> bytes:
    return typst.compile(
        str(template_dir / "resume.typ"),
        font_paths=[str(FONTS_DIR)],
        ignore_system_fonts=True,
        sys_inputs={"data": json.dumps(context, default=str)},
    )


def load_mock(template_dir: Path) -> dict[str, Any]:
    with (template_dir / "mock.yaml").open() as f:
        return yaml.safe_load(f)
