CREATE OR ALTER PROCEDURE control.sp_UpdateTableMetadata
    @TableId INT,
    @Status NVARCHAR(20),
    @PipelineRunId NVARCHAR(50),
    @RecordsLoaded BIGINT = 0,
    @SyncVersion BIGINT = NULL,
    @MarkInitialLoadComplete BIT = 0,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE control.table_metadata
    SET
        last_load_status = @Status,
        last_load_timestamp = GETUTCDATE(),
        last_pipeline_run_id = @PipelineRunId,
        records_loaded = @RecordsLoaded,
        last_sync_version = ISNULL(@SyncVersion, last_sync_version),
        initial_load_completed = CASE
            WHEN @MarkInitialLoadComplete = 1 AND @Status = 'SUCCESS' THEN 1
            ELSE initial_load_completed
        END,
        modified_date = GETUTCDATE()
    WHERE table_id = @TableId;

    INSERT INTO control.pipeline_execution_log (
        pipeline_run_id, table_id, execution_status, records_processed, error_message, start_time
    )
    VALUES (
        @PipelineRunId, @TableId, @Status, @RecordsLoaded, @ErrorMessage, GETUTCDATE()
    );
END
GO
