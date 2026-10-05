# custom-resume

Spec-driven resume builder: a master resume spec (`resume/master.yaml`) plus a
job description produces a tailored resume. See README.md for the pipeline and
layout.

## Commands

```sh
uv pip install -e '.[dev]'           # install
ruff check . && ruff format --check . # lint
resume preview templates/two-column  # render a template with its mock data
resume preview --data <spec>.yaml    # render a master spec with a template
```

## Git and PR conventions

- `master` is the default branch. Branch from it and open PRs against it;
  rebase onto `master` rather than merging it in.
- Split work into small, logical commits. Each commit should pass lint.
- This is a personal project: don't add tests.
- Commit messages describe the work: a short imperative subject, and a body
  explaining what changed and why.
- Open PRs with a title only. Leave the PR description empty, because the
  commit messages are the record.

## Templates

Templates are Typst files (`templates/<name>/resume.typ`) compiled to PDF by
`render.py`. They must stay ATS-parseable (see the Templates section of
README.md). After changing one, run `resume preview`, extract the PDF text
(e.g. with pypdf), and check the reading order (name first, then the columns
left to right) and that headings don't come out letter-spaced.
