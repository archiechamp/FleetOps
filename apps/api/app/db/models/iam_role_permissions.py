"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'iam.role_permissions',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False}, {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False}, {'name': 'role_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False}, {'name': 'permission_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}, {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False}, {'name': 'created_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}, {'name': 'updated_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'role_id'], 'target': 'iam.roles', 'target_columns': ['tenant_id', 'id'], 'nullable': False}, {'columns': ['permission_id'], 'target': 'iam.permissions', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'created_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}, {'columns': ['tenant_id', 'updated_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id'], ['tenant_id', 'role_id', 'permission_id']],
 'checks': [],
 'indexes': [{'columns': ['tenant_id', 'permission_id'], 'unique': False, 'filter': None}]}
table = create_table(SPEC)
