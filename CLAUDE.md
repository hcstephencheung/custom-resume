# custom-resume

Spec-driven resume builder: a master resume spec (`resume/master.yaml`) plus a
job description produces a tailored resume. See README.md for the pipeline and
layout.

## Commands

```sh
uv pip install -e '.[dev]'           # install
pytest                               # tests
ruff check . && ruff format --check . # lint
resume preview templates/two-column  # render a template with its mock data
```

## Git and PR conventions

- `master` is the default branch. Branch from it and open PRs against it;
  rebase onto `master` rather than merging it in.
- Split work into small, logical commits. Each commit should pass tests and lint.
- Commit messages describe the work: a short imperative subject, and a body
  explaining what changed and why.
- Open PRs with a title only. Leave the PR description empty, because the
  commit messages are the record.

## Templates

Templates must stay ATS-parseable when printed to PDF (see the Templates section
of README.md). After changing one, print it to PDF, extract the text, and check
the reading order and that headings don't come out letter-spaced.
