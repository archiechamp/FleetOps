"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'ref.jurisdictions', 'pk': 'id', 'columns': [{'name': 'id', 'type': 'SMALLINT', 'nullable': False, 'default': None, 'identity': True}, {'name': 'country_id', 'type': 'SMALLINT', 'nullable': False, 'default': None, 'identity': False}, {'name': 'code', 'type': 'VARCHAR(10)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'name', 'type': 'NVARCHAR(100)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}], 'foreign_keys': [{'columns': ['country_id'], 'target': 'ref.countries', 'target_columns': ['id'], 'nullable': False}], 'unique_keys': [['country_id', 'code']], 'checks': [], 'indexes': []}
table = create_table(SPEC)
