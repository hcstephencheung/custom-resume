"""Schema for the master resume spec.

The master spec is the single source of truth: it holds *everything* you might
want on a resume. A tailored resume is a selection (and light rewording) of
items from it, chosen per job description. Every selectable item carries an
`id` and `tags` so the tailoring step can reference and rank it.
"""

from __future__ import annotations

from datetime import date
from pathlib import Path

import yaml
from pydantic import BaseModel, ConfigDict, Field, HttpUrl, model_validator


class _Model(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Link(_Model):
    label: str
    url: HttpUrl


class Basics(_Model):
    name: str
    headline: str | None = None
    email: str | None = None
    phone: str | None = None
    location: str | None = None
    links: list[Link] = Field(default_factory=list)


class Summary(_Model):
    """One of several summary variants; the tailoring step picks the best fit."""

    id: str
    text: str
    tags: list[str] = Field(default_factory=list)


class Bullet(_Model):
    id: str
    text: str
    tags: list[str] = Field(default_factory=list)
    # Higher = more likely to be kept when space is tight.
    priority: int = Field(default=0, ge=0, le=10)


class Experience(_Model):
    id: str
    company: str
    title: str
    start: date
    end: date | None = None  # None = present
    location: str | None = None
    tags: list[str] = Field(default_factory=list)
    bullets: list[Bullet]


class Project(_Model):
    id: str
    name: str
    url: HttpUrl | None = None
    tags: list[str] = Field(default_factory=list)
    bullets: list[Bullet] = Field(default_factory=list)


class SkillGroup(_Model):
    id: str
    name: str
    items: list[str]


class Education(_Model):
    id: str
    institution: str
    degree: str
    start: date | None = None
    end: date | None = None
    notes: list[str] = Field(default_factory=list)


class MasterResume(_Model):
    basics: Basics
    summaries: list[Summary] = Field(default_factory=list)
    experience: list[Experience] = Field(default_factory=list)
    projects: list[Project] = Field(default_factory=list)
    skills: list[SkillGroup] = Field(default_factory=list)
    education: list[Education] = Field(default_factory=list)

    @model_validator(mode="after")
    def _ids_are_unique(self) -> MasterResume:
        seen: set[str] = set()
        for item_id in self.all_ids():
            if item_id in seen:
                raise ValueError(f"duplicate id: {item_id!r}")
            seen.add(item_id)
        return self

    def all_ids(self) -> list[str]:
        ids = [s.id for s in self.summaries]
        for exp in self.experience:
            ids.append(exp.id)
            ids.extend(b.id for b in exp.bullets)
        for proj in self.projects:
            ids.append(proj.id)
            ids.extend(b.id for b in proj.bullets)
        ids.extend(g.id for g in self.skills)
        ids.extend(e.id for e in self.education)
        return ids


def load_master(path: Path) -> MasterResume:
    with path.open() as f:
        return MasterResume.model_validate(yaml.safe_load(f))
