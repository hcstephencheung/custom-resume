from pathlib import Path

import pytest
from pydantic import ValidationError

from custom_resume.schema import MasterResume, load_master

EXAMPLE = Path(__file__).parent.parent / "resume" / "master.example.yaml"


def test_example_spec_is_valid():
    master = load_master(EXAMPLE)
    assert master.basics.name
    assert master.experience


def test_duplicate_ids_rejected():
    with pytest.raises(ValidationError, match="duplicate id"):
        MasterResume.model_validate(
            {
                "basics": {"name": "X"},
                "summaries": [
                    {"id": "dup", "text": "a"},
                    {"id": "dup", "text": "b"},
                ],
            }
        )


def test_unknown_fields_rejected():
    with pytest.raises(ValidationError):
        MasterResume.model_validate({"basics": {"name": "X", "nickname": "Y"}})
