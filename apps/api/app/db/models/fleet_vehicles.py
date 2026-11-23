"""Approved Feature 001 SQL Server table contract."""
from app.db.models.definition import create_table

SPEC = {'table': 'fleet.vehicles',
 'pk': 'id',
 'columns': [{'name': 'id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': 'NEWSEQUENTIALID()', 'identity': False},
             {'name': 'tenant_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'asset_id', 'type': 'UNIQUEIDENTIFIER', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'plate_number', 'type': 'NVARCHAR(30)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'plate_jurisdiction_id', 'type': 'SMALLINT', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'fuel_type_id', 'type': 'SMALLINT', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'fuel_capacity', 'type': 'DECIMAL(14,3)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'gross_vehicle_weight', 'type': 'DECIMAL(14,3)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'engine_serial', 'type': 'NVARCHAR(100)', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'created_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'updated_at', 'type': 'DATETIME2(3)', 'nullable': False, 'default': 'SYSUTCDATETIME()', 'identity': False},
             {'name': 'row_version', 'type': 'ROWVERSION', 'nullable': False, 'default': None, 'identity': False},
             {'name': 'created_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False},
             {'name': 'updated_by', 'type': 'UNIQUEIDENTIFIER', 'nullable': True, 'default': None, 'identity': False}],
 'foreign_keys': [{'columns': ['tenant_id'], 'target': 'core.tenants', 'target_columns': ['id'], 'nullable': False}, {'columns': ['tenant_id', 'asset_id'], 'target': 'fleet.assets', 'target_columns': ['tenant_id', 'id'], 'nullable': False}, {'columns': ['plate_jurisdiction_id'], 'target': 'ref.jurisdictions', 'target_columns': ['id'], 'nullable': True}, {'columns': ['fuel_type_id'], 'target': 'ref.fuel_types', 'target_columns': ['id'], 'nullable': True}, {'columns': ['tenant_id', 'created_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}, {'columns': ['tenant_id', 'updated_by'], 'target': 'iam.memberships', 'target_columns': ['tenant_id', 'id'], 'nullable': True}],
 'unique_keys': [['tenant_id', 'id'], ['tenant_id', 'asset_id']],
 'checks': ['fuel_capacity >= 0', 'gross_vehicle_weight >= 0'],
 'indexes': [{'columns': ['tenant_id', 'plate_jurisdiction_id'], 'unique': False, 'filter': None}, {'columns': ['tenant_id', 'fuel_type_id'], 'unique': False, 'filter': None}]}
table = create_table(SPEC)
