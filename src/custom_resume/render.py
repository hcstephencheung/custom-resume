"""Render resume templates to HTML.

A template is a directory under `templates/` containing `resume.html.j2` and,
optionally, `mock.yaml` with sample content for previewing it.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml
from jinja2 import Environment, FileSystemLoader


def render_template(template_dir: Path, context: dict[str, Any]) -> str:
    env = Environment(
        loader=FileSystemLoader(template_dir),
        autoescape=True,
        trim_blocks=True,
        lstrip_blocks=True,
    )
    return env.get_template("resume.html.j2").render(**context)


def load_mock(template_dir: Path) -> dict[str, Any]:
    with (template_dir / "mock.yaml").open() as f:
        return yaml.safe_load(f)
