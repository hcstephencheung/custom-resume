from pathlib import Path
from typing import Annotated

import typer
from pydantic import ValidationError

from custom_resume.render import load_mock, render_pdf
from custom_resume.schema import load_master

app = typer.Typer(help="Spec-driven resume builder.", no_args_is_help=True)


@app.callback()
def main() -> None:
    pass


@app.command()
def validate(
    spec: Annotated[Path, typer.Argument(exists=True)] = Path("resume/master.yaml"),
) -> None:
    """Check that a master resume spec is well-formed."""
    try:
        master = load_master(spec)
    except ValidationError as e:
        typer.secho(f"{spec}: invalid\n{e}", fg=typer.colors.RED, err=True)
        raise typer.Exit(1) from e
    n_bullets = sum(len(x.bullets) for x in master.experience)
    typer.secho(
        f"{spec}: ok ({len(master.experience)} roles, {n_bullets} bullets)",
        fg=typer.colors.GREEN,
    )


@app.command()
def preview(
    template: Annotated[Path, typer.Argument(exists=True, file_okay=False)] = Path(
        "templates/two-column"
    ),
    out: Annotated[Path | None, typer.Option(help="Output PDF path.")] = None,
) -> None:
    """Render a template with its bundled mock data."""
    out = out or Path("output") / f"{template.name}.pdf"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(render_pdf(template, load_mock(template)))
    typer.secho(f"wrote {out}", fg=typer.colors.GREEN)
