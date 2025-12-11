CREATE OR ALTER PROCEDURE control.sp_GetTableLoadOrder
AS
BEGIN
    -- Simple logic: Returns active tables.
    -- Dependency ordering is handled by orchestration logic or simple priority here.
    SELECT *
    FROM control.table_metadata
    WHERE is_active = 1
    ORDER BY load_priority ASC, table_id ASC;
END
GO
