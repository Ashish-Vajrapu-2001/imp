-- Create Control Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'control')
BEGIN
    EXEC('CREATE SCHEMA control')
END
GO

-- 1. Source Systems
CREATE TABLE control.source_systems (
    source_system_id INT IDENTITY(1,1) PRIMARY KEY,
    source_system_name NVARCHAR(100) NOT NULL,
    source_system_type NVARCHAR(50) DEFAULT 'AzureSQL',
    connection_string_secret NVARCHAR(200),
    is_active BIT DEFAULT 1,
    created_date DATETIME2 DEFAULT GETUTCDATE()
);

-- 2. Table Metadata
CREATE TABLE control.table_metadata (
    table_id INT IDENTITY(1,1) PRIMARY KEY,
    source_system_id INT FOREIGN KEY REFERENCES control.source_systems(source_system_id),
    schema_name NVARCHAR(128) NOT NULL,
    table_name NVARCHAR(128) NOT NULL,
    primary_key_columns NVARCHAR(500) NOT NULL,
    load_type NVARCHAR(20) DEFAULT 'CDC', -- 'FULL' or 'CDC'
    is_active BIT DEFAULT 1,
    initial_load_completed BIT DEFAULT 0, -- CRITICAL FLAG
    last_sync_version BIGINT DEFAULT 0,
    last_load_status NVARCHAR(20),
    last_load_timestamp DATETIME2,
    last_pipeline_run_id NVARCHAR(50),
    records_loaded BIGINT DEFAULT 0,
    bronze_path NVARCHAR(500),
    silver_path NVARCHAR(500),
    load_priority INT DEFAULT 100,
    created_date DATETIME2 DEFAULT GETUTCDATE(),
    modified_date DATETIME2 DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_Schema_Table UNIQUE (schema_name, table_name)
);

-- 3. Load Dependencies
CREATE TABLE control.load_dependencies (
    dependency_id INT IDENTITY(1,1) PRIMARY KEY,
    table_id INT FOREIGN KEY REFERENCES control.table_metadata(table_id),
    depends_on_table_id INT FOREIGN KEY REFERENCES control.table_metadata(table_id),
    dependency_type NVARCHAR(20) DEFAULT 'HARD'
);

-- 4. Pipeline Execution Log
CREATE TABLE control.pipeline_execution_log (
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    pipeline_run_id NVARCHAR(50) NOT NULL,
    table_id INT,
    execution_status NVARCHAR(20),
    records_processed BIGINT,
    start_time DATETIME2,
    end_time DATETIME2,
    error_message NVARCHAR(MAX),
    created_date DATETIME2 DEFAULT GETUTCDATE()
);

-- 5. Data Quality Rules
CREATE TABLE control.data_quality_rules (
    rule_id INT IDENTITY(1,1) PRIMARY KEY,
    table_id INT FOREIGN KEY REFERENCES control.table_metadata(table_id),
    rule_name NVARCHAR(100),
    rule_type NVARCHAR(50),
    rule_expression NVARCHAR(MAX),
    is_active BIT DEFAULT 1
);
GO
