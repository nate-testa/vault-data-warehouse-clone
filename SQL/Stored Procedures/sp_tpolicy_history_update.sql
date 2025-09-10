-- =======================================================================================================================================================
-- Description: This procedures updates transaction_status for tpolicy_history
-------------------------------------------------------------------------------------------
-- Change date      |Author						             |	Change Description
-------------------------------------------------------------------------------------------
-- 09/10/25		     Yunus Mohammed			    1. Created this procedure  
-- ========================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_history_update]
AS 
BEGIN
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpolicy_history_update_temp1
        
        SELECT 
            acct.PolicyNumber as policy_no,
            acct.EffectiveDate as effective_dt,
            acct.PolicyChangeNumber as transaction_seq_no,
            CASE
            WHEN acct.IsReversed = 1 THEN 'Reversed'
            WHEN acct.IsReversal = 1 THEN 'Reversal'
            ELSE 'Issued'
            END AS transaction_status,
            UpdatedDate
        INTO edw_temp.tpolicy_history_update_temp1
        FROM
            edw_stage.AccountTransaction acct
        WHERE 
            acct.[State] = 'Issued'
            and	acct.PolicyNumber is not null
            and acct.UpdatedDate > @last_source_extract_ts

        UPDATE [target]
        SET
            [target].transaction_status = source.transaction_status,
            [target].update_ts = getdate(),
            [target].etl_audit_sk = @etl_audit_sk
        FROM
            edw_core.tpolicy_history [target]
            INNER JOIN edw_temp.tpolicy_history_update_temp1 as [source] ON  [target].policy_no = [source] .policy_no AND
                [target].policy_no = [source] .policy_no AND [target].transaction_seq_no = [source] .transaction_seq_no
      
		SET @rows_affected=@@ROWCOUNT; 
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.UpdatedDate) FROM edw_temp.tpolicy_history_update_temp1 t1),@last_source_extract_ts);		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;	

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

        -- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpolicy_history_update_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

GO
