"""Schema for the master resume spec.

The master spec is the single source of truth: it holds *everything* you might
want on a resume. A tailored resume is a selection (and light rewording) of
items from it, chosen per job description. Every selectable item carries an
`id` and `tags` so the tailoring step can reference and rank it.
"""

from __future__ import annotations

from datetime import date
from pathlib import Path
from typing import Annotated

import yaml
from pydantic import (
    BaseModel,
    BeforeValidator,
    ConfigDict,
    Field,
    HttpUrl,
    StringConstraints,
    model_validator,
)

# "2012", "2025-04" or "2025-04-01": resumes usually give a month or just a year,
# and padding those out to full dates would invent precision.
PartialDate = Annotated[
    str,
    BeforeValidator(lambda v: v.isoformat() if isinstance(v, date) else str(v)),
    StringConstraints(pattern=r"^\d{4}(-\d{2}(-\d{2})?)?$"),
]


class _Model(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Link(_Model):
    label: str
    url: HttpUrl


class Basics(_Model):
    name: str
    headline: str | None = None
    # Secondary line under the headline, e.g. a specialism or core stack.
    subheadline: str | None = None
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
    start: PartialDate
    end: PartialDate | None = None  # None = present
    location: str | None = None
    tags: list[str] = Field(default_factory=list)
    bullets: list[Bullet]
    # Technologies used in the role, shown as a "Stack:" line.
    stack: list[str] = Field(default_factory=list)


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
    start: PartialDate | None = None
    end: PartialDate | None = None
    notes: list[str] = Field(default_factory=list)


class MasterResume(_Model):
    basics: Basics
    summaries: list[Summary] = Field(default_factory=list)
    experience: list[Experience] = Field(default_factory=list)
    projects: list[Project] = Field(default_factory=list)
    skills: list[SkillGroup] = Field(default_factory=list)
    education: list[Education] = Field(default_factory=list)
    interests: str | None = None
    # Written for a specific application, e.g. why this company or role: a
    # paragraph, or a list of short points rendered as bullets.
    personalized: str | list[str] | None = None
    # A short note shown at the very end of the resume, e.g. how it was made.
    disclaimer: str | None = None

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
