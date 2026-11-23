"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'core.tenants',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False},
             {'name': 'name', 'type': 'NVARCHAR(200)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'legal_name', 'type': 'NVARCHAR(200)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'slug', 'type': 'VARCHAR(100)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'status', 'type': 'VARCHAR(20)', 'nullable': False, 'default': "'ACTIVE'", 'identity': False},
             {'name': 'dot_number', 'type': 'VARCHAR(20)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'mc_number', 'type': 'VARCHAR(20)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'timezone', 'type': 'NVARCHAR(64)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'currency_code', 'type': 'CHAR(3)', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['currency_code'], 'target': 'ref.currencies', 'target_columns': ['code'], 'nullable': False}],
 'unique_keys': [['slug']],
 'checks': ["status IN ('ACTIVE','SUSPENDED','INACTIVE')"],
 'indexes': [{'columns': ['currency_code'], 'unique': False, 'filter': None}]}
table = create_table(SPEC)
