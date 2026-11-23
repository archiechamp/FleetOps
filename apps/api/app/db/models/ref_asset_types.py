"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'ref.asset_types', 'pk': 'id', 'columns': [{'name': 'id', 'type': 'SMALLINT', 'nullable': False, 'default': None, 'identity': True}, {'name': 'code', 'type': 'VARCHAR(30)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'name', 'type': 'NVARCHAR(100)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}], 'foreign_keys': [], 'unique_keys': [['code']], 'checks': [], 'indexes': []}
table = create_table(SPEC)
