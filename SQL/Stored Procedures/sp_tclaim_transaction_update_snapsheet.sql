-- =================================================================================================
-- Description: This procedures feature_status_sk in tclaim_transaction table
-----------------------------------------------------------------------------------------------------------
-- Change date          |Author						            |	Change Description
-----------------------------------------------------------------------------------------------------------
-- 02/07/25		           Yunus Mohammed			1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_transaction_update_snapsheet]
AS
BEGIN
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

        drop table if exists edw_temp.tclaim_transaction_update_snapsheet_temp1
		select ct.claim_transaction_sk, [source].feature_status_sk
        into edw_temp.tclaim_transaction_update_snapsheet_temp1
        from
        edw_core.tclaim_transaction ct
        inner join
        (
            select claim_transaction_sk,claim_feature_sk, case when reserve_running_total<>0 THEN 1 ELSE 2 END as feature_status_sk
            from
            (
            select claim_transaction_sk,claim_feature_sk,
            sum(loss_reserve_amt+expense_reserve_amt+defense_reserve_amt) over (order by transaction_ts) as reserve_running_total
            from edw_core.tclaim_transaction-- where claim_feature_sk=198
            ) as temp
        ) as [source] on ct.claim_transaction_sk = [source].claim_transaction_sk 
        where ct.source_system_sk = 5

        update [target]
        set [target].feature_status_sk = [source].feature_status_sk
        from
            edw_core.tclaim_transaction [target]
            inner join edw_temp. tclaim_transaction_update_snapsheet_temp1 [source] on [target].claim_transaction_sk = [source].claim_transaction_sk        

		DROP TABLE IF EXISTS edw_temp. tclaim_transaction_update_snapsheet_temp1;

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')

		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
GO