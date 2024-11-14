-- ==================================================================================================================================
-- Description: This procedures updates Thome_coverage
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 10/05/23		Architha Gudimalla		    1. Created this procedure to update TIV
-- 11/09/23		Architha Gudimalla		    2. Added logic for loss_of_use_derived_pc
-- 03/26/24		Architha Gudimalla		    3. Added to  loss_of_use_derived_pc - Reasonable and Necessary Expenses- 12 months
-- 04/19/24		Architha Gudimalla		    4. Updated the @new_last_source_extract_ts and also added the update to check for nulls
-- 06/14/24		Yunus Mohammed 				5. Removed error for rate_on_line 
-- ================================================================================================================================== 


CREATE OR ALTER  PROCEDURE [edw_core].[sp_thome_coverage_update]

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
		
		update [edw_core].[thome_coverage]
			set loss_of_use_derived_pc = 	round(
											CASE
												WHEN (loss_of_use_pc is null or
													loss_of_use_pc = '' or
													loss_of_use_pc = '0' or
													loss_of_use_pc = '0%'
													)
												and (loss_of_use_option is null or
													loss_of_use_option = '' or
													loss_of_use_option = '0'
													)
												and (loss_of_use_limit_amt is null or
													loss_of_use_limit_amt = '' or
													loss_of_use_limit_amt = '0' or
													isnumeric(trim(loss_of_use_limit_amt)) = 0
													)
												and isnull(iif(trim(loss_of_use_option)='','0',trim(loss_of_use_option)),'0')   = '0' 
												and isnull(iif(trim(loss_of_use_limit_amt)='','0',trim(loss_of_use_limit_amt)),'0')  = '0' 
													THEN  0
												WHEN loss_of_use_option in ('Reasonable and Necessary Expenses','reasonableAndNecessaryExpenses12months','Reasonable and Necessary Expenses- 12 months') 
													THEN 0.2
												WHEN loss_of_use_option like '%.%' 
													THEN  cast(loss_of_use_option as float) 
												--	THEN  cast(loss_of_use_pc as float)
												WHEN isnumeric(trim(loss_of_use_limit_amt)) = 0 
												and case when loss_of_use_pc = '' then '0' else loss_of_use_pc end = '0'
													then 0
												WHEN isnumeric(trim(loss_of_use_limit_amt)) = 1 
												and loss_of_use_limit_amt > 100 
												and dwelling_limit_amt > 0 
													then cast(loss_of_use_limit_amt as float)/dwelling_limit_amt
												WHEN isnumeric(trim(loss_of_use_limit_amt)) = 1 
												and loss_of_use_limit_amt > 100 
												and contents_limit_amt > 0 
													then cast(loss_of_use_limit_amt as float)/contents_limit_amt 
												WHEN loss_of_use_pc like '%.%' 
													THEN  cast(loss_of_use_pc as float) 
												else loss_of_use_pc
											END ,4) 
		where transaction_dt > @last_source_extract_ts
		or loss_of_use_derived_pc is null;
		
		update [edw_core].[thome_coverage]
			set total_insured_value_amt = 	isnull(dwelling_limit_amt,0) + isnull(other_structures_limit_amt,0) + isnull(contents_limit_amt,0) +
											round(cast(loss_of_use_derived_pc as float) * cast(iif(residence_type = 'Homeowners', dwelling_limit_amt, contents_limit_amt) as int),0)
											/*
											case when isnumeric(trim(loss_of_use_limit_amt)) = 1 and cast(loss_of_use_limit_amt as float) > 0.0 
											    then loss_of_use_limit_amt
												when isnumeric(loss_of_use_derived_pc) = 1 
											    then round(cast(loss_of_use_derived_pc as float) * cast(iif(residence_type = 'Homeowners', dwelling_limit_amt, contents_limit_amt) as int),0)
											else 0
											end*/
		where transaction_dt > @last_source_extract_ts
		or total_insured_value_amt is null; 
		
		DROP TABLE IF exists edw_temp.thome_cov_upd_rate_on_line; 

		with hc as
		(
			SELECT  policy_no, effective_Dt, transaction_seq_no, total_insured_value_amt, source_system_Sk
			FROM    edw_core.thome_coverage 
			where rate_on_line is null
			or transaction_dt >= @last_source_extract_ts
		), tr as
		(
			select pol.policy_no, pol.effective_Dt, tr.transaction_seq_no, tr.policy_sk, sum(annual_premium_amt) annual_premium_amt  
			from  edw_core.tpolicy pol, edw_core.tpolicy_transaction tr, edw_core.tinternal_coverage ic
			where tr.policy_sk = pol.policy_sk 
			and ic.internal_coverage_sk = tr.internal_coverage_sk and ic.primary_coverage_cd in ('Hurricane','Wildfire','AOP','Wind/Hail','Lux')
			and exists (select 'x' from hc where hc.policy_no = pol.policy_no) 
			group by pol.policy_no, pol.effective_Dt, tr.transaction_seq_no, tr.policy_sk
		), tr_run_total as
		(
			select policy_no, effective_Dt, transaction_seq_no, policy_sk, annual_premium_amt
				, SUM(annual_premium_amt ) OVER (partition by tr.policy_sk ORDER BY tr.transaction_seq_no ASC) prm_run_total
			from  tr
		)
		select hc.*,  annual_premium_amt, prm_run_total, round(prm_run_total*100/total_insured_value_amt,2) rate_on_line
		into edw_temp.thome_cov_upd_rate_on_line
		from hc, tr_run_total a
		where hc.policy_no = a.policy_no and hc.transaction_seq_no = a.transaction_seq_no;

		update hc 
			set hc.rate_on_line = a.rate_on_line
		from [edw_core].[thome_coverage] hc
		inner join edw_temp.thome_cov_upd_rate_on_line a on hc.policy_no = a.policy_no and hc.transaction_seq_no = a.transaction_seq_no
		where transaction_dt > @last_source_extract_ts
		or hc.rate_on_line is null; 
		
		DROP TABLE IF exists edw_temp.thome_cov_upd_rate_on_line;   

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT dateadd(d,-1,MAX(transaction_Dt)) FROM edw_core.thome_coverage t2),@last_source_extract_ts); 
		
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

