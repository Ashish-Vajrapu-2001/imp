-- Populate Source Systems
INSERT INTO control.source_systems (source_system_name, connection_string_secret)
VALUES
('ERP', '{{PLACEHOLDER_SECRET_ERP}}'),
('CRM', '{{PLACEHOLDER_SECRET_CRM}}'),
('MARKETING', '{{PLACEHOLDER_SECRET_MKT}}');

DECLARE @ERP_ID INT = (SELECT source_system_id FROM control.source_systems WHERE source_system_name = 'ERP');
DECLARE @CRM_ID INT = (SELECT source_system_id FROM control.source_systems WHERE source_system_name = 'CRM');
DECLARE @MKT_ID INT = (SELECT source_system_id FROM control.source_systems WHERE source_system_name = 'MARKETING');

-- Populate Table Metadata (Parsed from Metadata Doc)
-- CRM Tables
INSERT INTO control.table_metadata (source_system_id, schema_name, table_name, primary_key_columns, load_type) VALUES
(@CRM_ID, 'CRM', 'Customers', 'CUSTOMER_ID', 'CDC'),
(@CRM_ID, 'CRM', 'CustomerRegistrationSource', 'REGISTRATION_SOURCE_ID', 'CDC'),
(@CRM_ID, 'CRM', 'INCIDENTS', 'INCIDENT_ID', 'CDC'),
(@CRM_ID, 'CRM', 'INTERACTIONS', 'INTERACTION_ID', 'CDC'),
(@CRM_ID, 'CRM', 'SURVEYS', 'SURVEY_ID', 'CDC');

-- ERP Tables
INSERT INTO control.table_metadata (source_system_id, schema_name, table_name, primary_key_columns, load_type) VALUES
(@ERP_ID, 'ERP', 'OE_ORDER_HEADERS_ALL', 'ORDER_ID', 'CDC'),
(@ERP_ID, 'ERP', 'OE_ORDER_LINES_ALL', 'LINE_ID', 'CDC'),
(@ERP_ID, 'ERP', 'ADDRESSES', 'ADDRESS_ID', 'CDC'),
(@ERP_ID, 'ERP', 'CITY_TIER_MASTER', 'CITY,STATE', 'FULL'), -- Usually master data is full load or SCD
(@ERP_ID, 'ERP', 'MTL_SYSTEM_ITEMS_B', 'INVENTORY_ITEM_ID', 'CDC'),
(@ERP_ID, 'ERP', 'CATEGORIES', 'CATEGORY_ID', 'FULL'),
(@ERP_ID, 'ERP', 'BRANDS', 'BRAND_ID', 'FULL');

-- Marketing Tables
INSERT INTO control.table_metadata (source_system_id, schema_name, table_name, primary_key_columns, load_type) VALUES
(@MKT_ID, 'MARKETING', 'MARKETING_CAMPAIGNS', 'CAMPAIGN_ID', 'FULL');

-- Populate Dependencies (Based on FKs in Metadata)
-- Example: Orders depend on Customers
INSERT INTO control.load_dependencies (table_id, depends_on_table_id)
SELECT
    t1.table_id, t2.table_id
FROM control.table_metadata t1
CROSS JOIN control.table_metadata t2
WHERE t1.table_name = 'OE_ORDER_HEADERS_ALL' AND t2.table_name = 'Customers';

-- Example: Order Lines depend on Orders
INSERT INTO control.load_dependencies (table_id, depends_on_table_id)
SELECT
    t1.table_id, t2.table_id
FROM control.table_metadata t1
CROSS JOIN control.table_metadata t2
WHERE t1.table_name = 'OE_ORDER_LINES_ALL' AND t2.table_name = 'OE_ORDER_HEADERS_ALL';

-- Example: Incidents depend on Customers
INSERT INTO control.load_dependencies (table_id, depends_on_table_id)
SELECT
    t1.table_id, t2.table_id
FROM control.table_metadata t1
CROSS JOIN control.table_metadata t2
WHERE t1.table_name = 'INCIDENTS' AND t2.table_name = 'Customers';
GO
