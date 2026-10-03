# custom-resume

A spec-driven resume builder. You maintain **one master resume spec** with all of
your experience, and generate a **tailored resume per job description**.

## How it works

```
resume/master.yaml  ─┐
                     ├─▶  tailor  ─▶  selection  ─▶  render  ─▶  output/<job>.{md,html,pdf}
jobs/<job>.md       ─┘
```

1. **Master spec** (`resume/master.yaml`): the superset of everything you could
   put on a resume: multiple summary variants, more bullets per role than will
   fit, projects, and skills. Each item has a unique `id` and `tags`.
2. **Job description** (`jobs/<job>.md`): paste the posting as plain text.
3. **Tailor**: picks the summary, bullets, and skills that best match the job,
   and orders them. Output is a selection of ids from the master spec, so the
   result stays traceable to your own words.
4. **Render**: fills a template in `templates/` with the selection to produce
   the final resume.

## Layout

| Path | Purpose |
| --- | --- |
| `resume/master.example.yaml` | Example master spec; copy to `resume/master.yaml` |
| `jobs/` | Job descriptions, one file per posting |
| `templates/` | Output templates (Jinja2) |
| `src/custom_resume/schema.py` | Pydantic schema for the master spec |
| `src/custom_resume/cli.py` | `resume` CLI entry point |
| `output/` | Generated resumes (gitignored) |

## Setup

```sh
uv venv && source .venv/bin/activate
uv pip install -e '.[dev]'
cp resume/master.example.yaml resume/master.yaml
```

## Usage

```sh
resume validate resume/master.yaml   # check the spec against the schema
pytest                               # run tests
```

## Roadmap

- [x] Master spec schema + validation
- [ ] `resume tailor jobs/<job>.md`: select and order items per job description
- [ ] `resume render`: Markdown/HTML output from templates
- [ ] PDF export
