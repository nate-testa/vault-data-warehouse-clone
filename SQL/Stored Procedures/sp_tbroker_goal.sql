-- ===============================================================================================================================
-- Author:		Hernando Gonzalez
-- Description: This procedure inserts broker goal data
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 01/20/26             Hernando Gonzalez                 1. Created this procedure
-- ================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_goal]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON
		BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME2(7)=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

        -- Full load
        TRUNCATE TABLE edw_core.tbroker_goal;

        INSERT INTO edw_core.tbroker_goal
        (
            broker_sk,
            broker_id,
            product_cd,
            goal_year,
            goal_effective_dt,
            goal_expiration_dt,
            goal_status,
            new_business_premium_amt,
            create_ts,
            update_ts,
            etl_audit_sk
        )
        SELECT 
            tb.broker_sk,
            s.broker_id,
            'HO',
            s.goal_year,
            DATEFROMPARTS(s.goal_year, 1, 1),
            DATEFROMPARTS(s.goal_year, 12, 31),
            'Active',
            s.ho_new_business_premium_amt,
            getdate(),
            getdate()
            ,@etl_audit_sk
        FROM edw_stage.stage_broker_goal s
        INNER JOIN edw_core.tbroker tb 
            ON s.broker_id = tb.broker_id
        WHERE s.update_ts > @last_source_extract_ts;


        SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(s1.update_ts) FROM edw_stage.stage_broker_goal s1),@last_source_extract_ts);

		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END