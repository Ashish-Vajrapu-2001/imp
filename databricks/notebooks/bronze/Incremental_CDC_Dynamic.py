# databricks/notebooks/bronze/Incremental_CDC_Dynamic.py
# (Abbreviated structure similar to Initial, but with MERGE logic)
# ... Setup params ...

bronze_path = f"abfss://datalake@{storage_account}.dfs.core.windows.net/bronze/{source_system}/{schema_name}/{table_name}/incremental/{pipeline_run_id}"
delta_path = f"abfss://datalake@{storage_account}.dfs.core.windows.net/silver/{source_system}/{schema_name}/{table_name}"

df_cdc = spark.read.parquet(bronze_path)
if df_cdc.count() > 0:
    from delta.tables import DeltaTable
    delta_table = DeltaTable.forPath(spark, delta_path)

    # MERGE LOGIC
    # Construct merge condition based on PKs
    merge_condition = " AND ".join([f"target.{col} = source.{col}" for col in pk_cols])

    delta_table.alias("target").merge(
        df_cdc.alias("source"),
        merge_condition
    ).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()

# Update Control Table (Update Sync Version)
# ... similar pyodbc execution calling sp_UpdateTableMetadata ...
