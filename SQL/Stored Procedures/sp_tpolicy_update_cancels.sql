-- ===============================================================================================================
-- Description: This procedures updates Tpolicy 
-----------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------
-- 10/05/23		Architha Gudimalla		    1. Created this procedure to update policy status and cancel eff dt
-- 03/13/24		Yunus Mohammed				2. Updated system conversion
-- 03/22/24		Yunus Mohammed				3. Added prior policy no check in system conversion
-- =============================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_update_cancels]

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

		update edw_core.tpolicy  
		set policy_status = 'Active',
			cancellation_effective_dt = null
		from edw_core.tpolicy
		where policy_status = 'Cancelled';

		with cancels as
		(
			select  policy_sk, max(transaction_effective_dt_sk) transaction_effective_dt_sk
			from edw_core.tpolicy_transaction tr, edw_core.tpolicy_transaction_type tt 
			where 	tr.transaction_seq_no = (select max(transaction_seq_no) from edw_core.tpolicy_transaction tr1 where tr1.policy_sk = tr.policy_sk)
			and 	tr.policy_transaction_type_sk = tt.policy_transaction_type_sk
			and  	tt.policy_transaction_type_nm = 'Cancellation'
			group by policy_sk
		)
		update edw_core.tpolicy  
		set policy_status = 'Cancelled',
			cancellation_effective_dt = (select actual_dt from edw_core.tdate where date_sk = cancels.transaction_effective_dt_sk)
		from edw_core.tpolicy pol, cancels 
		where pol.policy_sk = cancels.policy_sk;

		update tp
		set
			oneshield_migrated_in = 'Yes',
			prior_policy_no = temp.priorpolicynumber
		from
		edw_core.tpolicy tp
		inner join [edw_stage].[dw2_oneshield_migrated] temp on tp.policy_no = temp.policynumber
		where
			temp.issystemconversion= 'yes'
			and prior_policy_no is null


		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((select actual_dt from edw_core.tdate 
												  where date_sk = (SELECT MAX(transaction_Dt_sk) 
												  					FROM edw_core.tpolicy_transaction
																  )
												 ),@last_source_extract_ts); 
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts; 

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

