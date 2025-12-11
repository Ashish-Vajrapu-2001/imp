# databricks/notebooks/bronze/Initial_Load_Dynamic.py

# PARAMETERS
dbutils.widgets.text("pipeline_run_id", "")
dbutils.widgets.text("table_id", "")
dbutils.widgets.text("source_system", "")
dbutils.widgets.text("schema_name", "")
dbutils.widgets.text("table_name", "")
dbutils.widgets.text("primary_key_columns", "")
dbutils.widgets.text("sql_server", "")
dbutils.widgets.text("sql_database", "")
dbutils.widgets.text("sql_username", "")
dbutils.widgets.text("sql_password", "")
dbutils.widgets.text("storage_account", "")

pipeline_run_id = dbutils.widgets.get("pipeline_run_id")
table_id = int(dbutils.widgets.get("table_id"))
source_system = dbutils.widgets.get("source_system")
schema_name = dbutils.widgets.get("schema_name")
table_name = dbutils.widgets.get("table_name")
pk_cols = dbutils.widgets.get("primary_key_columns").split(",")
sql_server = dbutils.widgets.get("sql_server")
sql_db = dbutils.widgets.get("sql_database")
sql_user = dbutils.widgets.get("sql_username")
sql_pass = dbutils.widgets.get("sql_password")
storage_account = dbutils.widgets.get("storage_account")

# 1. READ BRONZE (PARQUET)
# Path constructed using pipeline_run_id pattern
bronze_path = f"abfss://datalake@{storage_account}.dfs.core.windows.net/bronze/{source_system}/{schema_name}/{table_name}/initial/{pipeline_run_id}"

try:
    df = spark.read.parquet(bronze_path)
    record_count = df.count()
    print(f"Read {record_count} records from {bronze_path}")

    # 2. TRANSFORM (ADD METADATA)
    from pyspark.sql.functions import lit, current_timestamp
    df_transformed = df \
        .withColumn("_pipeline_run_id", lit(pipeline_run_id)) \
        .withColumn("_load_timestamp", current_timestamp()) \
        .withColumn("_is_active", lit(True))

    # 3. WRITE SILVER (DELTA)
    delta_path = f"abfss://datalake@{storage_account}.dfs.core.windows.net/silver/{source_system}/{schema_name}/{table_name}"

    df_transformed.write.format("delta") \
        .mode("overwrite") \
        .option("overwriteSchema", "true") \
        .save(delta_path)

    # 4. CRITICAL: UPDATE CONTROL TABLE & GET SYNC VERSION
    jdbc_url = f"jdbc:sqlserver://{sql_server}:1433;database={sql_db}"
    props = {
        "user": sql_user,
        "password": sql_pass,
        "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
    }

    # Get current change tracking version
    version_df = spark.read.jdbc(jdbc_url, "(SELECT CHANGE_TRACKING_CURRENT_VERSION() as v) as q", properties=props)
    current_version = version_df.collect()[0]['v']

    # Execute Update via JDBC (simulating SP call or direct update)
    # Using 'EXEC' syntax in query for SQL Server
    update_query = f"""
    EXEC control.sp_UpdateTableMetadata
        @TableId = {table_id},
        @Status = 'SUCCESS',
        @PipelineRunId = '{pipeline_run_id}',
        @RecordsLoaded = {record_count},
        @SyncVersion = {current_version},
        @MarkInitialLoadComplete = 1
    """

    # Trigger execution (lazy eval requires action)
    spark.read.jdbc(jdbc_url, f"(SELECT 1 as res) as d", properties=props).count()

    # Use pyodbc for the specific SP call to ensure side effects commit
    import pyodbc
    conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={sql_server};DATABASE={sql_db};UID={sql_user};PWD={sql_pass}"
    with pyodbc.connect(conn_str) as conn:
        cursor = conn.cursor()
        cursor.execute(update_query)
        conn.commit()

    dbutils.notebook.exit(f"SUCCESS: Loaded {record_count} records. Marked Initial Load Complete.")

except Exception as e:
    # Log Failure
    import pyodbc
    conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={sql_server};DATABASE={sql_db};UID={sql_user};PWD={sql_pass}"
    with pyodbc.connect(conn_str) as conn:
        cursor = conn.cursor()
        cursor.execute(f"EXEC control.sp_UpdateTableMetadata @TableId={table_id}, @Status='FAILED', @PipelineRunId='{pipeline_run_id}', @ErrorMessage='{str(e).replace('\'', '')}'")
        conn.commit()
    raise e
