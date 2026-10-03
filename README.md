# custom-resume

A spec-driven resume builder. You maintain **one master resume spec** with all of
your experience, and generate a **tailored resume per job description**.

## How it works

```
resume/master.yaml  ─┐
                     ├─▶  tailor  ─▶  selection  ─▶  render  ─▶  output/<job>.pdf
jobs/<job>.md       ─┘
```

1. **Master spec** (`resume/master.yaml`): the superset of everything you could
   put on a resume: multiple summary variants, more bullets per role than will
   fit, projects, and skills. Each item has a unique `id` and `tags`.
2. **Job description** (`jobs/<job>.md`): paste the posting as plain text.
3. **Tailor**: picks the summary, bullets, and skills that best match the job,
   and orders them. Output is a selection of ids from the master spec, so the
   result stays traceable to your own words.
4. **Render**: compiles a [Typst](https://typst.app/docs) template in
   `templates/` with the selection to produce the final PDF.

## Layout

| Path | Purpose |
| --- | --- |
| `resume/master.example.yaml` | Example master spec; copy to `resume/master.yaml` |
| `jobs/` | Job descriptions, one file per posting |
| `templates/<name>/` | Typst templates: `resume.typ` plus `mock.yaml` sample content |
| `fonts/` | Vendored fonts (SIL OFL) used by the templates |
| `src/custom_resume/schema.py` | Pydantic schema for the master spec |
| `src/custom_resume/render.py` | Compiles a template to PDF with Typst |
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
resume preview templates/two-column  # render a template with its mock data -> output/two-column.pdf
```

## Templates

Templates are written in Typst and compiled to PDF through the `typst` Python
package, which bundles the compiler, so nothing else needs installing. A
template gets its data as JSON in `sys.inputs.data`. Compiled on its own, it
falls back to its `mock.yaml`, which is handy while editing the design. This
needs the [Typst CLI](https://github.com/typst/typst):

```sh
typst watch templates/two-column/resume.typ --font-path fonts --ignore-system-fonts
```

- **two-column**: dark 25% sidebar (contact, keyword groups, education) and a
  main column with any number of sections. Built to stay ATS-parseable: name
  first in reading order, plain-text contact labels, no icons, skill bars or
  images, letter-spacing kept tight and ligatures off.

## Roadmap

- [x] Master spec schema + validation
- [ ] `resume tailor jobs/<job>.md`: select and order items per job description
- [x] Two-column Typst template + `resume preview` (PDF)
- [ ] `resume render`: fill a template from a tailored selection
