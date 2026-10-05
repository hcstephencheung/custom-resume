"""Turn a master resume spec into the data a template renders.

Templates take a flat, presentation-shaped dict (see templates/*/mock.yaml):
name, headline, subheadline, contact, sidebar sections and main sections, plus
the summary, experience, skills, education, interests and disclaimer as
standalone fields for templates that place each piece themselves. This maps
every item in a master spec into that shape. Choosing which items to include
for a particular job is the tailoring step's job, not this module's.
"""

from __future__ import annotations

from typing import Any

from custom_resume.schema import Experience, MasterResume

MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def format_date(value: str) -> str:
    """'2025-04' or '2025-04-01' -> 'Apr 2025'; '2012' -> '2012'."""
    parts = value.split("-")
    return f"{MONTHS[int(parts[1]) - 1]} {parts[0]}" if len(parts) > 1 else parts[0]


def format_range(start: str | None, end: str | None, *, open_ended: bool) -> str | None:
    if start is None:
        return format_date(end) if end else None
    finish = format_date(end) if end else ("Present" if open_ended else None)
    return f"{format_date(start)} – {finish}" if finish else format_date(start)


def _display_url(url: str) -> str:
    return url.split("://", 1)[-1].removeprefix("www.").rstrip("/")


def _experience_entry(exp: Experience) -> dict[str, Any]:
    return {
        "heading": exp.company,
        "subheading": exp.title,
        "location": exp.location,
        "dates": format_range(exp.start, exp.end, open_ended=True),
        "bullets": [b.text for b in exp.bullets],
        "stack": exp.stack,
    }


def context_from_master(master: MasterResume) -> dict[str, Any]:
    basics = master.basics

    contact = []
    if basics.email:
        contact.append({"label": "Email", "value": basics.email, "href": f"mailto:{basics.email}"})
    if basics.phone:
        contact.append({"label": "Phone", "value": basics.phone})
    if basics.location:
        contact.append({"label": "Location", "value": basics.location})
    for link in basics.links:
        url = str(link.url)
        contact.append({"label": link.label, "value": _display_url(url), "href": url})

    skills = [{"name": g.name, "items": g.items} for g in master.skills]
    education = [
        {
            "heading": e.institution,
            "subheading": e.degree,
            "dates": format_range(e.start, e.end, open_ended=False),
        }
        for e in master.education
    ]

    sidebar: list[dict[str, Any]] = []
    if skills:
        sidebar.append({"title": "Skills", "groups": skills})
    if education:
        sidebar.append({"title": "Education", "entries": education})

    sections: list[dict[str, Any]] = []
    if master.summaries:
        sections.append({"title": "Profile", "text": master.summaries[0].text})
    if master.experience:
        sections.append(
            {
                "title": "Experience",
                "timeline": True,
                "entries": [_experience_entry(e) for e in master.experience],
            }
        )
    if master.interests:
        sections.append({"title": "Interests", "text": master.interests})
    if master.projects:
        entries = [
            {
                "heading": p.name,
                "subheading": str(p.url) if p.url else None,
                "bullets": [b.text for b in p.bullets],
            }
            for p in master.projects
        ]
        sections.append({"title": "Projects", "entries": entries})
    if master.disclaimer:
        sections.append({"title": "Disclaimer", "text": master.disclaimer})

    return {
        "name": basics.name,
        "headline": basics.headline,
        "subheadline": basics.subheadline,
        "contact": contact,
        "sidebar": sidebar,
        "sections": sections,
        # The same content as standalone fields, for templates that place each
        # piece themselves rather than rendering `sections` in order.
        "summary": master.summaries[0].text if master.summaries else None,
        "experience": [_experience_entry(e) for e in master.experience],
        "skills": skills,
        "education": education,
        "interests": master.interests,
        "disclaimer": master.disclaimer,
    }
