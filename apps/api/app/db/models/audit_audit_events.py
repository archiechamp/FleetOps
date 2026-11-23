"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'audit.audit_events',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'BIGINT', 'nullable': False, 'default': None, 'identity': True},
             {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'actor_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'actor_type', 'type': 'VARCHAR(20)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'action', 'type': 'VARCHAR(50)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'entity_type', 'type': 'VARCHAR(100)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'entity_id', 'type': 'NVARCHAR(100)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'old_values', 'type': 'NVARCHAR(MAX)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'new_values', 'type': 'NVARCHAR(MAX)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'correlation_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'occurred_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['actor_id'], 'target': 'iam.users', 'target_columns': ['id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id']],
 'checks': ['ISJSON(old_values) = 1', 'ISJSON(new_values) = 1'],
 'indexes': [{'columns': ['tenant_id', 'actor_id'], 'unique': False, 'filter': None}, {'columns': ['tenant_id', 'entity_type', 'entity_id', 'occurred_at'], 'unique': False, 'filter': None}]}
table = create_table(SPEC)
