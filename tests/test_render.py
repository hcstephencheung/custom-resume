from pathlib import Path

from custom_resume.render import load_mock, render_template

TWO_COLUMN = Path(__file__).parent.parent / "templates" / "two-column"


def test_two_column_renders_mock():
    mock = load_mock(TWO_COLUMN)
    html = render_template(TWO_COLUMN, mock)
    assert mock["name"] in html
    for section in mock["sections"] + mock["sidebar"]:
        assert section["title"] in html


def test_header_precedes_sidebar_for_ats_reading_order():
    html = render_template(TWO_COLUMN, load_mock(TWO_COLUMN))
    assert html.index('class="header"') < html.index('class="sidebar"')


def test_content_is_escaped():
    mock = load_mock(TWO_COLUMN)
    mock["sections"] = [{"title": "Profile", "text": "<script>x</script>"}]
    html = render_template(TWO_COLUMN, mock)
    assert "<script>x</script>" not in html
