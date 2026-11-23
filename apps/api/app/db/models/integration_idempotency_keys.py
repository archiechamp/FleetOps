"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'integration.idempotency_keys',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False},
             {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'operation_scope', 'type': 'VARCHAR(80)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'request_key', 'type': 'NVARCHAR(150)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'request_hash', 'type': 'BINARY(32)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'response_reference', 'type': 'NVARCHAR(150)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'expires_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'updated_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'created_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}, {'columns': ['tenant_id', 'updated_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id'], ['tenant_id', 'operation_scope', 'request_key']],
 'checks': [],
 'indexes': []}
table = create_table(SPEC)
