"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'core.terminals',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False},
             {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'code', 'type': 'VARCHAR(30)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'name', 'type': 'NVARCHAR(150)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'address', 'type': 'NVARCHAR(500)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'timezone', 'type': 'NVARCHAR(64)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'status', 'type': 'VARCHAR(20)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'updated_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'created_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}, {'columns': ['tenant_id', 'updated_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id'], ['tenant_id', 'code']],
 'checks': [],
 'indexes': []}
table = create_table(SPEC)
