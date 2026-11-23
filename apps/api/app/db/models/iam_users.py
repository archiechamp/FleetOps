"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'iam.users',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False}, {'name': 'auth_provider', 'type': 'VARCHAR(30)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'external_subject', 'type': 'NVARCHAR(200)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'email', 'type': 'NVARCHAR(254)', 'nullable': True, 'default': None, 'identity': False}, {'name': 'display_name', 'type': 'NVARCHAR(150)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'status', 'type': 'VARCHAR(20)', 'nullable': False, 'default': "'ACTIVE'", 'identity': False}, {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False}],
 'foreign_keys': [],
 'unique_keys': [['auth_provider', 'external_subject']],
 'checks': ["status IN ('ACTIVE','DISABLED','INVITED')"],
 'indexes': []}
table = create_table(SPEC)
