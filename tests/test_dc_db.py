from .example.db import meta

from openapi.db.container import Database
from openapi.data.db import dataclass_from_table
from openapi.data.fields import VALIDATOR, UUIDValidator
from openapi.data.validate import validate

db = Database()
meta(db.metadata)


def test_convert_task():
    Tasks = dataclass_from_table('Tasks', db.tasks, exclude=('random',))
    assert Tasks
    fields = Tasks.__dataclass_fields__
    assert 'random' not in fields
    props = {}
    fields['title'].metadata[VALIDATOR].openapi(props)
    assert props['maxLength'] == 64
    assert props['minLength'] == 3


def test_convert_random():
    Tasks = dataclass_from_table('Randoms', db.randoms)
    assert Tasks
    fields = Tasks.__dataclass_fields__
    assert isinstance(fields['id'].metadata[VALIDATOR], UUIDValidator)


def test_validate():
    Tasks = dataclass_from_table('Tasks', db.tasks, exclude=('id',))
    d = validate(Tasks, dict(title='test'))
    assert not d.errors
    d = validate(Tasks, dict(title='te'))
    assert d.errors['title'] == 'Too short'
    d = validate(Tasks, dict(title='t'*100))
    assert d.errors['title'] == 'Too long'
