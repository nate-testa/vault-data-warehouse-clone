# Common Patterns in Vault Data Warehouse Stored Procedures

This document outlines the standard patterns and practices used in stored procedures within the Vault Data Warehouse. These patterns should be followed when creating or modifying stored procedures to maintain consistency and reliability.

## 1. Basic Procedure Structure

All stored procedures should follow this basic structure:

```sql
CREATE OR ALTER PROCEDURE [schema_name].[procedure_name]
(
    @param1 data_type,
    @param2 data_type
)
AS
BEGIN
    -- Variable declarations
    DECLARE @process_nm VARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @last_source_extract_ts DATETIME2(7)
    DECLARE @new_last_source_extract_ts DATETIME2(7)
    DECLARE @etl_audit_sk INT
    DECLARE @rows_affected INT
    DECLARE @parameter_desc VARCHAR(255)
    DECLARE @current_date DATETIME = GETDATE()
    
    BEGIN TRY
        -- Get last source extract date
        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm)
        
        -- Create audit entry
        EXEC edw_core.sp_ins_tetl_audit @process_nm, @current_date, @etl_audit_sk = @etl_audit_sk OUTPUT
        SET @parameter_desc = 'last_source_extract_ts > ' + CAST(@last_source_extract_ts AS VARCHAR(200))
        
        -- Main procedure logic
        -- ...
        
        -- Update control table with new extraction timestamp
        SET @new_last_source_extract_ts = COALESCE([high_watermark_calculation], @last_source_extract_ts)
        EXEC edw_core.sp_upd_tetl_control @process_nm, @new_last_source_extract_ts
        
        -- Update audit table
        SET @parameter_desc = @parameter_desc + ' AND last_source_extract_ts <= ' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
        EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk, @rows_affected, @parameter_desc
        
        -- Clean up temp tables
        DROP TABLE IF EXISTS
    END TRY
    BEGIN CATCH
        -- Error handling
            END CATCH
END
```

## 2. ETL Audit Tracking

Every procedure must create an audit entry at the start and update it at completion:

```sql
-- At the beginning
EXEC edw_core.sp_ins_tetl_audit @process_nm, @current_date, @etl_audit_sk = @etl_audit_sk OUTPUT
SET @parameter_desc = 'last_source_extract_ts > ' + CAST(@last_source_extract_ts AS VARCHAR(200))

-- At the end
SET @parameter_desc = @parameter_desc + ' AND last_source_extract_ts <= ' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk, @rows_affected, @parameter_desc
```

## 3. Incremental Loading Pattern

Use the `last_source_extract_ts` pattern for incremental loading:

```sql
-- Get the last processed timestamp
SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm)

-- Filter data based on this timestamp
SELECT ... 
INTO edw_temp.[temp_table_name]
FROM source_table
WHERE updated_date > @last_source_extract_ts

-- Calculate new high watermark
SET @new_last_source_extract_ts = COALESCE(
    (SELECT MAX(updated_date) FROM edw_temp.[temp_table_name]),
    @last_source_extract_ts
)

-- Update control table with new timestamp
EXEC edw_core.sp_upd_tetl_control @process_nm, @new_last_source_extract_ts
```

## 4. Temporary Tables Usage

Use temporary tables in the `edw_temp` schema with standardized naming:

```sql
-- Create temp table
DROP TABLE IF EXISTS edw_temp.[table_name]_temp1
SELECT ...
INTO edw_temp.[table_name]_temp1
FROM ...

-- For multi-stage transformations, use sequential numbers
SELECT ...
INTO edw_temp.[table_name]_temp2
FROM edw_temp.[table_name]_temp1
WHERE ...

-- Always clean up at the end
DROP TABLE IF EXISTS edw_temp.[table_name]_temp1
DROP TABLE IF EXISTS edw_temp.[table_name]_temp2
```

## 5. MERGE Statement Pattern

Use MERGE statements for upsert operations:

```sql
MERGE [target_schema].[target_table] AS Target
USING (
    SELECT column1, column2, ...
    FROM edw_temp.[table_name]_temp1
) AS Source
ON Source.key_column = Target.key_column
WHEN MATCHED THEN
    UPDATE SET
        Target.column1 = Source.column1,
        Target.column2 = Source.column2,
        Target.update_ts = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (column1, column2, ..., create_ts, update_ts)
    VALUES (Source.column1, Source.column2, ..., GETDATE(), GETDATE());

-- Capture the row count for audit
SET @rows_affected = @@ROWCOUNT
```

## 6. Error Handling

Implement comprehensive error handling in every procedure:

```sql
BEGIN CATCH
    DECLARE @error_message NVARCHAR(4000)
    SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)), '') + 
                        ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)), '') + 
                        ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)), '') +
                        CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(), '') + 
                        ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)), '') +
                        CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(), '')
    
    EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk, @error_message
    THROW 99001, 'Error occurred: see tetl_audit table for more info', 1
END CATCH
```

## 7. Timestamping

Always include and update timestamp fields:

```sql
-- For inserts
INSERT INTO [schema].[table] 
(
    ...,
    create_ts,
    update_ts
)
VALUES
(
    ...,
    GETDATE(),
    GETDATE()
)

-- For updates
UPDATE [schema].[table]
SET 
    ...,
    update_ts = GETDATE()
WHERE ...
```

## 8. Resource Cleanup

Always clean up resources at the end of the procedure:

```sql
-- Temp tables
DROP TABLE IF EXISTS edw_temp.[table_name]_temp1

-- Cursors
IF CURSOR_STATUS('global', 'cursor_name') > -1
BEGIN
    CLOSE cursor_name
    DEALLOCATE cursor_name
END
```

## 9. Parameter Conventions

Use consistent parameter naming:

```sql
DECLARE @process_nm VARCHAR(255) = OBJECT_NAME(@@PROCID)
DECLARE @last_source_extract_ts DATETIME2(7)
DECLARE @new_last_source_extract_ts DATETIME2(7)
DECLARE @etl_audit_sk INT
DECLARE @rows_affected INT
DECLARE @parameter_desc VARCHAR(255)
DECLARE @current_date DATETIME = GETDATE()
```

## 10. Best Practices

- Set `@process_nm` to the current procedure name using `OBJECT_NAME(@@PROCID)`
- Track row counts with `@@ROWCOUNT` after operations
- Use `COALESCE` when setting the new watermark to handle empty result sets
- Use schema-qualified object names
- Include detailed comments for complex logic
- Always use `MERGE` statements for upsert operations
- Use consistent column ordering in SELECT statements
- Keep procedures modular and focused on a single business entity or function
- Use standard error code 99001 for consistent error handling across the system

## 11. WIP Procedures Pattern

For each quote-related stored procedure, there should be a companion procedure with the "_wip" suffix designed to handle quotes in "Work In Progress" state.

### Purpose of WIP Procedures

WIP (Work In Progress) procedures specifically handle quote data that is in a draft state or being actively modified, but hasn't been submitted for a transaction yet. The main differences between standard procedures and their WIP counterparts are:

```sql
-- Standard procedure (e.g., sp_tquote_auto_vehicle_coverage)
-- Handles data for quotes with transactions
CREATE PROCEDURE edw_core.sp_tquote_auto_vehicle_coverage
AS
BEGIN
    -- Process quotes that have a transaction
    -- ...
END

-- WIP procedure (e.g., sp_tquote_auto_vehicle_coverage_wip)
-- Handles data for quotes without transactions (in progress)
CREATE PROCEDURE edw_core.sp_tquote_auto_vehicle_coverage_wip
AS
BEGIN
    -- Process quotes that are in a "Work In Progress" state
    -- ...
END
```

### Key Characteristics of WIP Procedures

1. **Data Source**: WIP procedures typically source data from Metal's in-progress quote objects rather than transaction-based objects.

2. **Target Tables**: Regular and WIP procedures often target the same tables, but WIP records may be marked with a "wip_in" flag or similar indicator.

3. **Lifecycle Management**: WIP data may be overwritten or deleted when a quote transitions from WIP to a submitted state.

4. **Join Conditions**: WIP procedures often use different join conditions that account for the absence of transaction data.

5. **Consistency**: Both regular and WIP procedures should maintain consistent column mappings and business logic when targeting the same tables.

### Implementation Guidelines

- Always create a WIP counterpart procedure for each quote-related procedure
- Maintain consistent naming by appending "_wip" to the base procedure name
- Ensure business logic remains consistent between regular and WIP procedures
- Consider using conditional logic to handle both WIP and non-WIP data within the same target tables
- Use standard documentation to clarify the relationship between WIP and non-WIP procedures

```sql
-- Example of WIP procedure pattern
CREATE OR ALTER PROCEDURE edw_core.sp_tquote_home_coverage_wip
AS
BEGIN
    -- Variable declarations follow standard pattern
    DECLARE @process_nm VARCHAR(255) = OBJECT_NAME(@@PROCID)
    -- ...other declarations...
    
    BEGIN TRY
        -- Get last source extract date
        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm)
        
        -- Create temp table with WIP data
        DROP TABLE IF EXISTS edw_temp.[tquote_home_coverage_wip_temp1]
        SELECT -- columns...
        INTO edw_temp.[tquote_home_coverage_wip_temp1]
        FROM edw_stage.AccountTransactionVersionObject atvo
        -- Join to WIP quote tables rather than transaction tables
        WHERE GREATEST(atvo.CreatedDate, atvo.UpdatedDate) > @last_source_extract_ts
        -- And other WIP-specific conditions
        
        -- Update target table with MERGE pattern
        MERGE edw_core.tquote_home_coverage AS Target
        USING edw_temp.[tquote_home_coverage_wip_temp1] AS Source
        ON Source.key_column = Target.key_column
        -- Rest follows standard MERGE pattern
        
        -- Standard cleanup and error handling
    END TRY
    BEGIN CATCH
        -- Standard error handling
    END CATCH
END
```

## 12. Cursor Usage Pattern

While set-based operations are preferred, cursors are sometimes necessary for row-by-row processing. Follow these guidelines for cursor usage:

```sql
-- Declare cursor variables
DECLARE @cursor_variable1 TYPE
DECLARE @cursor_variable2 TYPE

-- Declare and define the cursor
DECLARE cursor_name CURSOR FOR
SELECT column1, column2
FROM source_table
WHERE conditions

-- Open the cursor
OPEN cursor_name

-- Fetch the first row
FETCH NEXT FROM cursor_name INTO @cursor_variable1, @cursor_variable2

-- Process rows in a loop
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Process the current row
    -- ...
    
    -- Fetch the next row
    FETCH NEXT FROM cursor_name INTO @cursor_variable1, @cursor_variable2
END

-- Clean up
CLOSE cursor_name
DEALLOCATE cursor_name
```

### Cursor Best Practices

1. **Only use cursors when necessary** - Prefer set-based operations when possible
2. **Always close and deallocate** - Prevent memory leaks by cleaning up properly
3. **Limit result set size** - Add appropriate WHERE clauses to minimize the cursor's scope
4. **Consider performance impact** - Be aware that cursors are slower than set-based operations
5. **Use FAST_FORWARD option** for read-only, forward-only cursors to improve performance:

```sql
DECLARE cursor_name CURSOR FAST_FORWARD FOR
SELECT ...
```

## 13. Dynamic SQL Pattern

For situations requiring dynamic SQL, use this pattern to ensure security and maintainability:

```sql
-- Declare variables
DECLARE @sql NVARCHAR(MAX)
DECLARE @params NVARCHAR(1000)

-- Build the SQL statement
SET @sql = N'
SELECT column1, column2
FROM schema_name.table_name
WHERE column_name = @parameter_value
'

-- Define parameters
SET @params = N'@parameter_value TYPE'

-- Execute the dynamic SQL with parameters
EXEC sp_executesql @sql, @params, @parameter_value = @local_variable

-- For INSERT/UPDATE/DELETE, capture the row count
DECLARE @dynamic_rows INT
EXEC @dynamic_rows = sp_executesql @sql, @params, @parameter_value = @local_variable
SET @rows_affected = @dynamic_rows
```

### Dynamic SQL Guidelines

1. **Always parameterize queries** to prevent SQL injection
2. **Avoid building SQL with direct string concatenation** of user inputs
3. **Use sp_executesql** instead of EXEC() for parameterization
4. **Document complex dynamic SQL** with comments explaining the purpose and structure
5. **Log the final SQL statement** in case of errors for easier debugging