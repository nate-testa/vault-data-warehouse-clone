SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-04-28
-- Description: This stored update info related to tcommercial_policy.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 28/04/2025            Alberto Almario			1. Created this procedure 
-- ===================================================================================================================== 
CREATE OR ALTER     PROCEDURE [edw_core].[sp_tcommercial_policy_update_cancels]

AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Create temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_update_cancels_temp1;
		SELECT
			tr.commercial_policy_sk, 
			MAX(tr.transaction_effective_dt_sk) transaction_effective_dt_sk,
			MAX(tr.update_ts) update_ts
		INTO edw_temp.tcommercial_policy_update_cancels_temp1
		FROM edw_commercial.tcommercial_policy_transaction tr
		INNER JOIN edw_core.tpolicy_transaction_type tt 
		ON tr.policy_transaction_type_sk = tt.policy_transaction_type_sk
		WHERE 1=1
		AND tr.update_ts > @last_source_extract_ts
		AND tr.transaction_seq_no = (select max(transaction_seq_no) from edw_commercial.tcommercial_policy_transaction tr1 where tr1.commercial_policy_sk = tr.commercial_policy_sk)
		AND tt.policy_transaction_type_nm = 'Cancellation'
		GROUP BY commercial_policy_sk
		;

		-- Update policy_status
		UPDATE pol
		SET 
			 pol.policy_status = 'CANCELLED'
			,pol.cancellation_effective_dt = tdate.actual_dt
			,pol.update_ts = GETDATE()
		FROM edw_commercial.tcommercial_policy pol
		INNER JOIN edw_temp.tcommercial_policy_update_cancels_temp1 cancels 
			ON pol.commercial_policy_sk = cancels.commercial_policy_sk
		INNER JOIN edw_core.tdate tdate
			ON tdate.date_sk = cancels.transaction_effective_dt_sk
		;

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(tmp.update_ts) FROM edw_temp.tcommercial_policy_update_cancels_temp1 tmp),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_update_cancels_temp1;
		
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
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

