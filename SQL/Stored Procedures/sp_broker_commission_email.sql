SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================================
-- Author:		Dinesh Bobbili
-- Description: This procedure inserts broker commission data into broker_commission_email_api
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 01/30/26             Dinesh Bobbili              1. Created this procedure
-- ================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_broker_commission_email]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 

        TRUNCATE TABLE edw_integration.broker_commission_email_api;

        INSERT INTO edw_integration.broker_commission_email_api
        (
            commission_statement_email,
            agency_code,
            agency_name,
            agency_city,
            agency_state,
            create_ts,
            update_ts,
            etl_audit_sk
        )
        SELECT
            s.value AS commission_statement_email,
            b.broker_id AS agency_code,
            COALESCE(b.dba_nm, b.broker_nm) AS agency_name,
            b.primary_address_city_nm AS agency_city,
            b.primary_address_state_cd AS agency_state,
            getdate(),
            getdate(),
            @etl_audit_sk
        FROM edw_core.tbroker b
        CROSS APPLY STRING_SPLIT(b.commission_statement_email, ';') AS s
        WHERE b.broker_status IN (
            'Suspended',
            'Approved',
            'Rejected',
            'Terminated'
        )
        AND EXISTS (
            SELECT 1
            FROM vault_edw.edw_core.tpolicy p
            WHERE p.broker_id = b.broker_id
            AND p.source_system_sk IN ('2', '4')
        );

		
		SET @rows_affected=@@ROWCOUNT;   
	
		--SET @new_last_source_extract_ts=COALESCE((SELECT MAX(create_ts) FROM edw_stage.stage_majesco_cash_activity),@last_source_extract_ts); 
		SET @new_last_source_extract_ts = '2017-01-01';
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;


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
GO