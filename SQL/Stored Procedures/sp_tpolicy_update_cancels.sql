-- ==========================================================================================================================================
-- Description: This procedures updates Tpolicy 
-----------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------
-- 10/05/23		Architha Gudimalla		    1. Created this procedure to update policy status and cancel eff dt
-- 03/13/24		Yunus Mohammed				2. Updated system conversion
-- 03/22/24		Yunus Mohammed				3. Added prior policy no check in system conversion
-- 03/25/24		Architha Gudimalla			4. Added policy term update for cancel rewrites
-- 04/15/24		Architha Gudimalla			5. Added filter on updated below to exlucde those pols when prior pol is same as prior term pol
-- 01/23/25		Architha Gudimalla			6. VI33968/AD7635 - Added uwco orig eff dt
-- ========================================================================================================================================== 

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
		
		--added since collete raised a ticket - https://vaultinsurance.atlassian.net/browse/VI-30813
		update edw_stage.dw2_oneshield_migrated
		set priorpolicynumber = 'EX100012147-02'
		where policynumber like 'EX100197392-02%';

		--added since collete raised a ticket - https://vaultinsurance.atlassian.net/browse/VI-30814
		update edw_stage.dw2_oneshield_migrated
		set priorpolicynumber = '9101081 170101A'
		where policynumber = 'HO100033099-01'

		update tp
		set
			oneshield_migrated_in = 'Yes',
			prior_policy_no = temp.priorpolicynumber
		from
		edw_core.tpolicy tp
		inner join (select * from [edw_stage].[dw2_oneshield_migrated] 
					---excluded these since they already are getting prior_term policy from other source and prior policy from dw2_oneshield_migrated starts with 91
					where policynumber not in ('AU100073742-01','HO100060214-02','EX100071547-03','HO100077801-03','HO100021387','HO100020071','HO100021482-01',
											   'AU100099586-02','AU100042642-01','AU100073742-01','AU100204456-03','EX100032539-02','AU100189563-02')
					) temp on tp.policy_no = temp.policynumber
		where
			temp.issystemconversion= 'yes'
			and prior_policy_no is null 
			--added below on 4/15
			and case when CHARINDEX('-',policynumber) = 0                     
					 then policynumber
                     else left(policynumber, CHARINDEX('-',policynumber) - 1)
         		end 
				<> 
				case when CHARINDEX('-',priorpolicynumber) = 0                     
					 then priorpolicynumber
                     else left(priorpolicynumber, CHARINDEX('-',priorpolicynumber) - 1)
         		end

		--added since collete raised a ticket - https://vaultinsurance.atlassian.net/browse/VI-30682, prior pol cannot be same number as pol no
		update a
		set  prior_policy_no =null,  oneshield_migrated_in=null
		from edw_core.tpolicy a 
		where oneshield_migrated_in = 'Yes'
		and prior_term_policy_no is null
		and LEFT(policy_no, CHARINDEX('-', policy_no + '-') - 1) = LEFT(prior_policy_no, CHARINDEX('-', prior_policy_no + '-') - 1)

		--prior_policy_no cannot be same as prior_term_policy_no
		update a
		set prior_policy_no = null, oneshield_migrated_in = null
		from edw_core.tpolicy a 
		where prior_policy_no = prior_term_policy_no
					and case when CHARINDEX('-',prior_term_policy_no) = 0                     
							 then prior_term_policy_no
							 else left(prior_term_policy_no, CHARINDEX('-',prior_term_policy_no) - 1)
         				end 
						= 
						case when CHARINDEX('-',policy_no) = 0                     
							 then policy_no
							 else left(policy_no, CHARINDEX('-',policy_no) - 1)
         				end

		update a
		set prior_policy_no = null, oneshield_migrated_in = null
		from edw_core.tpolicy a 
		where   case when CHARINDEX('-',prior_term_policy_no) = 0                     
							then prior_term_policy_no
							else left(prior_term_policy_no, CHARINDEX('-',prior_term_policy_no) - 1)
						end 
						= 
						case when CHARINDEX('-',prior_policy_no) = 0                     
							then prior_policy_no
							else left(prior_policy_no, CHARINDEX('-',prior_policy_no) - 1)
						end
					and case when CHARINDEX('-',prior_term_policy_no) = 0                     
							then prior_term_policy_no
							else left(prior_term_policy_no, CHARINDEX('-',prior_term_policy_no) - 1)
						end 
						= 
						case when CHARINDEX('-',policy_no) = 0                     
							then policy_no
							else left(policy_no, CHARINDEX('-',policy_no) - 1)
						end

		--added on 3/25
		--rewritten policies have policy term as new, update there as renewals since prior term is renewal
		update pol
		set pol.policy_term = pol1.policy_term 
		from edw_core.tpolicy pol
		inner join edw_core.tpolicy pol1 on pol1.policy_no = pol.prior_policy_no 
		where pol.policy_term = 'New' 
		--and pol.policy_no like '%-%' 
		and pol1.policy_term = 'Renewal';

		--added on 4/25 since collete raised a ticket - https://vaultinsurance.atlassian.net/issues/VI-30719, prior pol cannot be a diff prod type
		update edw_core.tpolicy 
		set prior_policy_no = null
		where policy_no = 'AU100148267-01' and prior_policy_no = 'HO100148227-01' 

		update edw_core.tpolicy 
		set prior_policy_no = null
		where policy_no = 'EX100202768-03' and prior_policy_no = 'CO81406038536-02'
		
		update edw_core.tpolicy 
		set prior_policy_no = null
		where policy_no = 'EX100266882-03' and prior_policy_no = 'AU100266880-03'		
  
		update edw_core.tpolicy 
		set prior_policy_no = null
		where policy_no = 'CO100243128-02' and prior_policy_no = 'AU100038397-01'

		--added on 1/23 for uw_company_original_policy_effective_dt
		update pol
		set pol.uw_company_original_policy_effective_dt = pol1.uw_company_original_policy_effective_dt
		from edw_core.tpolicy pol
		inner join (select  policy_sk, min(effective_dt) over (partition by original_policy_no) uw_company_original_policy_effective_dt
					from edw_core.tpolicy) pol1 on pol.policy_sk = pol1.policy_sk
		; 

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

