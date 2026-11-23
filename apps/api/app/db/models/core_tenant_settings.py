"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'core.tenant_settings',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False}, {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False}, {'name': 'setting_key', 'type': 'VARCHAR(100)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'setting_value', 'type': 'NVARCHAR(MAX)', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}, {'name': 'updated_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'created_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}, {'columns': ['tenant_id', 'updated_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id'], ['tenant_id', 'setting_key']],
 'checks': ['ISJSON(setting_value) = 1'],
 'indexes': []}
table = create_table(SPEC)
