-- ==========================================================================================================================================
-- Description: This procedures updates tpolicy lifetime_claims
-----------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------
-- 11/14/23		Architha Gudimalla		    1. VI34680|AD7653 - Created this procedure 
-- ========================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_update_lifetime_claims]

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

		drop table if exists edw_temp.tpolicy_update_lifetime_claims_temp1;
		drop table if exists edw_temp.tpolicy_update_lifetime_claims_temp2;
		
		select pol.policy_no, pol.original_policy_no, pol.term_no, count(c.claim_sk) claim_ct,
				sum(c.loss_reserve_amt + c.expense_reserve_amt + c.adjusting_other_reserve_amt + c.subro_reserve_amt + c.salvage_reserve_amt + c.salvage_expense_reserve_amt + c.subro_expense_reserve_amt
					+ c.loss_paid_amt + c.expense_paid_amt + c.adjusting_other_paid_amt + c.subro_recovery_amt + c.salvage_recovery_amt + c.salvage_expense_paid_amt + c.subro_expense_paid_amt
					+ c.refund_indemnity_paid_amt + c.refund_expense_paid_amt ) AS li_amt
		into edw_temp.tpolicy_update_lifetime_claims_temp1
		from edw_core.tclaim c
		inner join edw_core.tpolicy pol on pol.policy_sk = c.policy_sk
		where exists ( select policy_sk from edw_core.tclaim c1
						where greatest(c1.create_ts, c1.update_ts) > @last_source_extract_ts
						and c1.policy_sk is not null
						and c1.policy_sk = c.policy_sk)
		group by pol.policy_no, pol.original_policy_no, pol.term_no
		order by 1

		select pol.policy_sk, pol.policy_no, pol.original_policy_no, pol.term_no
				, sum(isnull(claim_ct,0)) claim_ct, sum(isnull(li_amt,0)) li_amt
		into edw_temp.tpolicy_update_lifetime_claims_temp2
		from edw_core.tpolicy pol
		left join #edw_temp.tpolicy_update_lifetime_claims_temp1 a on pol.original_policy_no = a.original_policy_no and a.term_no <= pol.term_no
		group by pol.policy_sk, pol.policy_no, pol.original_policy_no, pol.term_no;

		update pol
		set lifetime_claim_ct = a.claim_ct,
			lifetime_incurred_amt = a.li_amt
		from tpolicy pol
		inner join edw_temp.tpolicy_update_lifetime_claims_temp2 a on a.policy_sk = pol.policy_sk;

		drop table if exists edw_temp.tpolicy_update_lifetime_claims_temp1;
		drop table if exists edw_temp.tpolicy_update_lifetime_claims_temp2;
		
		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((select greatest(create_ts, update_ts) from edw_core.tclaim),@last_source_extract_ts); 
		
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

