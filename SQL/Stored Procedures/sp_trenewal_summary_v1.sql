/****** Object:  StoredProcedure [edw_core].[sp_trenewal_summary_v1]    Script Date: 2/3/2026 6:48:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the renewals data for each month
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 08/14/23		Architha Gudimalla				1. Created this procedure 
-- 09/12/23		Architha Gudimalla				2. Added additional columns after discussing with Olivia 
-- 10/02/23		Architha Gudimalla				3. Corrected code afrer testing table
-- 10/18/23		Architha Gudimalla				4. Used source_system_sk from tpolicy instead of tpolicy_transaction in prm subquery 
-- 11/14/23		Architha Gudimalla				5. Added transaction dt filter to prm qubquery
--												   Updated premiums to use net prm
-- 11/15/23		Architha Gudimalla				6. Added logic for cancel rewrites
-- 11/15/23		Architha Gudimalla				7. Added uw_company_cd
-- 11/17/23		Architha Gudimalla				8. Fixed divide by 0 error
-- 11/27/23		Architha Gudimalla				9. Corrected the logic for residence type and TIV
-- 01/30/24		Architha Gudimalla				10. Added replace on policy_no to match the policy numbers that skipped 'x' in it
-- 02/01/24		Architha Gudimalla				11. Added logic for wip_renewal_quote_ct, offered_or_not_taken_quote_ct, renewal_quote_sk 
-- 02/07/24		Architha Gudimalla				12. Added logic for pending non renewal prm
-- 02/07/24		Architha Gudimalla				13. customer other inf count
-- 02/09/24		Architha Gudimalla				14. customer other inf count default to 0 if null
-- 02/13/24		Architha Gudimalla				15. Removed the default month from customer other inf
-- 02/23/24		Architha Gudimalla				16. Added columns - Renewal Offered TIV, Renewal Offered cov a, Renewal Offered renewal sq feet
-- 03/22/24		Architha Gudimalla				17. Updated renewal columns for pols that were renewed after 60 day of expiry
-- 04/26/24		Architha Gudimalla				18. Added temp table for the last insert
-- 04/30/24		Alberto Almario					19. Added expiring_mid_term_endorsement_premium_amt, expiring_price_sqft, issued_price_sqft, renewal_offered_price_sqft
-- 04/26/24		Architha Gudimalla				18. Added cancellation_reason_desc
-- 05/15/24		Architha Gudimalla				19. Updated 365 to use exp_dt-eff_dt - VI-31715 
-- 05/15/24		Architha Gudimalla				20. Added new cols - VI-31715
-- 06/04/24		Architha Gudimalla				21. Added CTE for quotes, soeme policies up for renewal have renewal quotes with same pol no and also as a cancel rewrite
--												    Olivia wants to prioritize the same pol no quote instead of cancel rewrite
-- 07/18/24		Architha Gudimalla				22. Updated logic for @last_source_extract_ts
-- 08/14/24		Architha Gudimalla				23. Added ROL columns
--														expiring_sixty_day_rate_on_line
--														renewal_sixty_day_rate_on_line
--														renewal_quote_rate_on_line
--														expiring_rate_on_line
-- 08/14/24		Architha Gudimalla				24. Added new columns
--														product_nm
--														renewal_quote_note_desc
--														pending_non_renewal_ct
--														agency_primary_location_state_cd 
-- 08/14/24		Architha Gudimalla				25. updated uw_company_cd logic
-- 08/14/24		Architha Gudimalla				26. updated offered_or_not_taken_quote_ct logic
-- 08/15/24		Architha Gudimalla				27. Fixed errors for the code changes done in 23-26
-- 02/06/25		Architha Gudimalla				28. AD8428 - Prod error due to dupes in quotes
-- 06/13/25		Architha Gudimalla				29. AD9823 - Exclude forcast quotes
-- 10/15/25		Dinesh Bobbili					30. AD11286 - simplified the date logic
-- 11/10/25		Dinesh Bobbili					31. AD11642 - Added source_system_sk filter for NFP process
-- 12/05/25		Architha Gudimalla				32. AD9858 - Updated logic to use prior_term_policy_no instead of prior_policy_no
-- 01/07/26		Dinesh Bobbili					33. AD12083 - Added logic for pending_process_ct and risk address 
-- 01/08/26		Dinesh Bobbili					34. AD12083 - Updated logic for nonrenewal_ind, not_accepted_renewal_ct 
-- 01/15/26		Alberto Almario					35. AD12274 - Added new columns and included them in the update statement
-- 														in_progress_premium_amt
-- 														closed_with_no_offer_premium_amt
-- 														accepted_premium_amt
-- 														not_accepted_premium_amt
-- 														outstanding_premium_amt
-- 														need_attention_premium_amt
-- 01/22/26		Dinesh Bobbili					36. AD12328 - Added address logic based policy_sk
-- 01/30/26     Architha Gudimalla              37. AD12428 - updated to take out the 60 day calc for flat and midterm cancels
-- ======================================================================================================================================================================= 

CREATE OR ALTER       PROCEDURE [edw_core].[sp_trenewal_summary_v1]
@in_yearmonth int = null,
@in_source_system VARCHAR(10) = null
AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements. 
	SET ANSI_WARNINGS OFF 
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @last_source_yearmonth int
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()   

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm); 
		set @last_source_yearmonth = concat(datepart(yyyy,cast(@last_source_extract_ts as date)),iif(datepart(mm,cast(@last_source_extract_ts as date)) < 10,'0','') ,datepart(mm,cast(@last_source_extract_ts as date)) ); 
	
		DECLARE @month_begin_dt_sk INT
		DECLARE @month_end_dt_sk INT
		DECLARE @begin_dt_sk INT
		DECLARE @end_dt_sk INT
		--DECLARE @prev_month_end_dt_sk INT
		DECLARE @month_begin_dt DATETIME
		DECLARE @month_end_dt DATETIME 
		DECLARE @begin_dt DATETIME
		DECLARE @end_dt DATETIME 
		--DECLARE @year INT 
		DECLARE @yearmonth INT 
		--DECLARE @year_begin_sk INT 
		DECLARE @proc_run_month_end_dt date
		DECLARE @proc_run_month INT  
		
		DECLARE @param_ssk VARCHAR(50)
		select @param_ssk=source_system_sk from edw_core.tsource_system where source_system_nm = @in_source_system;
		
		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth between  (case when @in_yearmonth is not null
										  then FORMAT(DATEADD(MONTH, -2, DATEFROMPARTS(LEFT(@in_yearmonth, 4), RIGHT(@in_yearmonth, 2), 1)), 'yyyyMM')
									end) 
						  and @in_yearmonth
		group by yearmonth
		union 
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth between  (case when @in_yearmonth is  null
										  then FORMAT(DATEADD(MONTH, -2, DATEFROMPARTS(LEFT(@last_source_yearmonth, 4), RIGHT(@last_source_yearmonth, 2), 1)), 'yyyyMM')
									end) 
						  and @last_source_yearmonth
		union 
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth >  case when @in_yearmonth is null then @last_source_yearmonth end
		  and   yearmonth <= case when @in_yearmonth is null then FORMAT(GETDATE(), 'yyyyMM') end
		group by yearmonth
		order by 1;  

		DECLARE @parameter_desc VARCHAR(255) 

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

			--print @yearmonth

				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				select 	@month_begin_dt_sk = min(datE_sk), 
						@month_end_dt_sk = max(datE_sk),
						@month_begin_dt = min(actual_dt), 
						@month_end_dt = max(actual_dt),
						@begin_dt_sk = min(datE_sk), 
						@end_dt_sk = max(datE_sk),
						@begin_dt = min(actual_dt), 
						@end_dt = max(actual_dt)
				from edw_core.tdate
				where yearmonth = @yearmonth;

				IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
				BEGIN  
						select 	@begin_dt_sk = min(datE_sk), 
								@end_dt_sk = max(datE_sk),
								@begin_dt = min(actual_dt), 
								@end_dt = max(actual_dt) 
						from edw_core.tdate
						where yearmonth = @yearmonth and actual_dt < cast(getdate() as date); 
				END  

				delete from [edw_stage].[trenewal_summary_v1]
				where month_sk = @month_end_dt_sk
				and source_system_sk = isnull(@param_ssk, source_system_sk);
				
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_0_oth_cust_inf;
				
				select customer_id, td.actual_dt inforce_dt, 
						case when pol.prior_policy_no is null and pol.original_policy_no is null then pol.policy_no
							 when pol.prior_policy_no is null  							  		 then pol.original_policy_no
							 when CHARINDEX('-',pol.prior_policy_no) = 0 					  	 then pol.prior_policy_no 
							 else left(pol.prior_policy_no, CHARINDEX('-',pol.prior_policy_no) - 1) 
						end original_policy_no, 
						pol.policy_no, pol.effective_dt
				into edw_temp.trenewal_summary_v1_temp_0_oth_cust_inf
				from edw_core.tdaily_inforce_policy inf, edw_core.tdate td, edw_core.tpolicy pol
				where inf.inforce_dt_sk = td.date_sk	
				and inf.policy_sk  = pol.policy_sk 
				and td.actual_dt between @begin_dt and @end_dt
				and customer_sk is not null
				and inf.source_system_sk = isnull(@param_ssk, inf.source_system_sk); 
				
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_1_quotes;
				
				with q as
				(
					select  q.quote_sk, q.quote_no, q.effective_dt, q.original_policy_no, q.quote_Status, q.first_offered_quote_history_sk,  
							q.prior_policy_no 
						    , replace(replace(q.uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd
							, br.primary_address_state_cd
							, isnull(q.prior_term_policy_no,q.prior_policy_no) prior_term_policy_no
							, rank() over (partition by isnull(q.prior_term_policy_no,q.prior_policy_no)
										   order by replace(replace(replace(quote_status,'In Progress','3_In_Progress'),'Offered','2_Offered'),'Issued','1_Issued'), 
										   			q.quote_sk desc
										  ) rnk
					from edw_core.tquote q
						 , edw_core.tbroker br 
					where	effective_dt between @begin_dt and @end_dt 
					and br.broker_id = q.broker_id
					and q.forecast_quote_in = 'No'
					and q.source_system_sk = isnull(@param_ssk, q.source_system_sk)
					--and quote_Status <> 'Issued'
				),
				n as
				(
					select q1.quote_no, nt.note_desc, rank() over (partition by q1.quote_no order by note_created_ts desc, note_sk desc) rnk, note_created_ts
					from edw_core.tnote nt, edw_core.tquote q1
					where q1.quote_no = nt.policy_no
					and object_type = 'Account' 
					and effective_dt between @begin_dt and @end_dt
					and nt.source_system_sk = isnull(@param_ssk, nt.source_system_sk)
				)
				select    q.*
						, case when original_policy_no= prior_policy_no then 0 else 1 end pol_no_changed_in	
						, n.note_desc				
				into edw_temp.trenewal_summary_v1_temp_1_quotes 
				from q
				left join n on q.quote_no = n.quote_no and n.rnk = 1; 
				
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_2_prm;

				SELECT tr.policy_sk, 
				 		--tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk, 
				 		max(tr.transaction_seq_no) transaction_seq_no,
		 				sum(tr.premium_amt - tr.tax_fee_surcharge_amt) premium_amt,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('New','Renewal') --'Renewal','New Business' 
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as initial_written_prem,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_prem,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('New','Renewal') --'Renewal','New Business' 
								then tr.commission_amt * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as initial_written_comm,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then tr.commission_amt  * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_comm,  
						sum(CASE WHEN tr.transaction_seq_no = max_pol_tr.transaction_seq_no
								  and transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation', 'Reinstatement')
								  and  (transaction_effective_dt_sk <> effective_dt_sk)
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as mid_term_cancel_amount, 
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk  
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as expiring_premium_amount,
						sum(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
								  and  (transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61)
								then 1
								else 0
								end) as cancel_sixty_days_ind, 
                        sum(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
										--expiring pol paid, cancel eff to the pol eff dt
										and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
										and pol.billing_PAID_IN = 'Yes' and (transaction_effective_dt_sk = effective_dt_sk)
									then 1
									WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
										--expiring pol is not paid, cancel eff to the pol eff dt
										and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
										and pol.billing_PAID_IN is null
									then 1
									else 0
									end) as flat_cancel_ind,
                        sum(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
										--expiring pol paid, cancel eff not same as pol eff dt
										and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
										and pol.billing_PAID_IN = 'Yes' and (transaction_effective_dt_sk <> effective_dt_sk)
									then 1 
									else 0
									end) as mid_term_cancel_ind, 
						sum( CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'') 
								then 1
								else 0
								end) cancel_ind, --expiring_ind, --all_cancelled_policy_num,
						sum(CASE WHEN tr.policy_transaction_sk = sixty_day_pol_tr.policy_transaction_sk
								  then hoc.total_insured_value_amt  
								else 0 
								end) as sixty_day_TIV,
						sum(CASE WHEN tr.policy_transaction_sk = sixty_day_pol_tr.policy_transaction_sk
								  then hoc.dwelling_limit_amt  
								else 0 
								end) as sixty_day_COVA,
						sum(CASE WHEN tr.policy_transaction_sk = sixty_day_pol_tr.policy_transaction_sk
								  then hoc.rate_on_line  
								else 0 
								end) as sixty_day_rate_on_line,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.total_insured_value_amt  
								else 0 
								end) as expiring_TIV,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.dwelling_limit_amt  
								else 0 
								end) as expiring_COVA,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.rate_on_line  
								else 0 
								end) as expiring_rate_on_line,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.total_finished_square_feet  
								else 0 
								end) as totalsquarefeet,
						max(CASE when tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk 
								 then residence_type
								 else null
							end) as max_tr_residencetype,
						max(pol.non_renewal_in) non_renewal_in,
						max(pol.pending_non_renewal_in) pending_non_renewal_in,
						max(pol.policy_term) policy_term,
						max(pol.product_cd) product_cd ,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.min_policy_transaction_sk
								  then hoc.total_insured_value_amt  
								else 0 
								end) as day_0_TIV,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.min_policy_transaction_sk
								  then hoc.dwelling_limit_amt  
								else 0 
								end) as day_0_COVA,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.min_policy_transaction_sk
								  then hoc.total_finished_square_feet  
								else 0 
								end) as day_0_totalsquarefeet,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.min_policy_transaction_sk
								  then hoc.rate_on_line  
								else 0 
								end) as day_0_rate_on_line
				 into edw_temp.trenewal_summary_v1_temp_2_prm
				 FROM	edw_core.tpolicy_transaction tr
				 inner join edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_sk = tr.policy_transaction_type_sk
				 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
				 --getting max transaction record
				 inner join (
								 SELECT policy_sk, max(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) policy_transaction_sk, 
												min(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no, policy_transaction_sk) min_policy_transaction_sk, 
												max(transaction_seq_no) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) transaction_seq_no, 
												   rank() over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) rnk
								 FROM	edw_core.tpolicy_transaction
								 where	effective_dt_sk <= @end_dt_sk
				 				--and transaction_dt_sk - expiration_dt_sk <= 60
								 --and	transaction_effective_dt_sk <= @end_dt_sk 
							) max_pol_tr on tr.policy_sk = max_pol_tr.policy_sk
				 --getting 60 day transaction record
				 left join (
								 SELECT policy_sk, max(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) policy_transaction_sk, 
												   rank() over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) rnk
								 FROM	edw_core.tpolicy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 --and	transaction_effective_dt_sk <= @end_dt_sk
								 and 	(transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61)
							) sixty_day_pol_tr on tr.policy_sk = sixty_day_pol_tr.policy_sk
				 left join edw_core.thome_coverage hoc on hoc.home_coverage_sk = tr.coverage_sk and tr.product_sk in (1,5)
				 where	max_pol_tr.rnk = 1
				 and (sixty_day_pol_tr.rnk = 1 or sixty_day_pol_tr.rnk is null)
				 and effective_dt_sk <= @end_dt_sk
				 --and	transaction_dt_sk <= @end_dt_sk
				 --and	transaction_effective_dt_sk <= @end_dt_sk
				 --and transaction_dt_sk - expiration_dt_sk <= 60
				 and   (pol.expiration_dt between @begin_dt and @end_dt or
						pol.effective_dt between @begin_dt and @end_dt)
				and tr.source_system_sk = isnull(@param_ssk, tr.source_system_sk)
				 group by tr.policy_sk--, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk
				
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_3_max_tr;

				select policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
				into edw_temp.trenewal_summary_v1_temp_3_max_tr
				from edw_core.tpolicy_transaction 
				where effective_dt_sk <= @end_dt_sk
				--and   transaction_effective_dt_sk <= @end_dt_sk
				--and   transaction_dt_sk <= @end_dt_sk 
				--and transaction_dt_sk - expiration_dt_sk <= 60
				group by policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no;

				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_4_initial; 

				with exp_pols as
				--pols expiration in current month
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no,
						replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd
						, non_renewal_in, pending_non_renewal_in
				 FROM	edw_core.tpolicy
				 where	expiration_dt between @begin_dt and @end_dt 
				 and source_system_sk = isnull(@param_ssk, source_system_sk)
				),
				ren_pols_all as
				(
				 	SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no, prior_term_policy_no, prior_policy_no, policy_status, uw_company_Cd, 
							rank() over (partition by prior_term_policy_no
										order by replace(replace(replace(policy_status,'Expired','2_Expired'),'Cancelled','3_Cancelled'),'Active','1_Active'), policy_sk) rnk
					FROM	 
					(
							SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no, isnull(prior_term_policy_no, prior_policy_no) prior_term_policy_no, prior_policy_no, policy_status,
									replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd
							FROM	edw_core.tpolicy
							where	effective_dt between @begin_dt and @end_dt
							and source_system_sk = isnull(@param_ssk, source_system_sk)
					) aa 
				),
				--pols renewing distinct in current month
				ren_pols as
				(
				 SELECT *
				 FROM	ren_pols_all
				 where rnk = 1
				),
				--pols renewing all in current month
				ren_quotes as
				(
					select *
					from edw_temp.trenewal_summary_v1_temp_1_quotes 
				 	where rnk = 1 
				)
				select exp_pols.policy_sk, exp_pols.policy_no, exp_pols.uw_company_Cd exp_uw_company_Cd,
						ren_pols.policy_sk renewal_policy_sk, ren_pols.uw_company_Cd ren_pol_uw_company_Cd, 
						ren_quotes.quote_sk renewal_quote_sk, ren_quotes.uw_company_Cd ren_quote_uw_company_Cd, ren_quotes.note_desc, ren_quotes.primary_address_state_cd
				into edw_temp.trenewal_summary_v1_temp_4_initial
				from exp_pols 
				-- join to get renewals for expiring policies
				left join ren_pols on ren_pols.prior_term_policy_no = exp_pols.policy_no 
				--left join ren_pols on replace(ren_pols.prior_policy_no,'x','') = replace(exp_pols.original_policy_no,'x','') and ren_pols.effective_dt = exp_pols.expiration_dt 
				-- join to get renewals quotes for expiring policies
				left join ren_quotes on ren_quotes.prior_term_policy_no = exp_pols.policy_no;

				drop table if exists edw_temp.trenewal_summary_v1_temp_5_cancel_rewrites;

				with ho_address as
				(
					select policy_no, effective_dt, address_line_1 from edw_core.thome_location
				), 
				pel_address as
				(
					select loc.policy_no, loc.effective_dt, replace(loc.address_line_1,' court',' ct') address_line_1, primary_location_in 
					from edw_core.tpel_location loc, edw_core.tpolicy_history ph 
					where  ph.policy_no = loc.policy_no and ph.policy_history_sk = loc.policy_history_sk and ph.latest_transaction_in = 'Y'
				) , 
				au_address as
				(
					select pol.policy_no, pol.effective_dt, pol.mailing_address_line1 
					from edw_core.tpolicy pol 
					where  product_cd = 'AU'
				) 
				select exp_pol.*, ren_pol_ph.cancellation_reason_desc, pol.expiration_dt, 
							case when pol.product_cd='HO' then hol.address_line_1
								 when pol.product_cd='PEL' then pel.address_line_1 
								 when pol.product_cd='AU' then AU.mailing_address_line1 end as address_old, 
							case when pol.product_cd='HO' then hol_new.address_line_1
								 when pol.product_cd='PEL' then pel_new.address_line_1 
								 when pol.product_cd='AU' then au_new.mailing_address_line1 end as address_new, 
							case when pol.product_cd='HO' then hol_new.policy_no
								 when pol.product_cd='PEL' then pel_new.policy_no 
								 when pol.product_cd='PEL' then au_new.policy_no end as ren_pol_new , 
							ren_pol_new.policy_sk ren_pol_new_policy_sk, ren_pol_new.policy_status 
							, replace(replace(ren_pol_new.uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') ren_pol_new_uw_company_Cd
				into edw_temp.trenewal_summary_v1_temp_5_cancel_rewrites
				from edw_temp.trenewal_summary_v1_temp_4_initial exp_pol 
				inner join edw_core.tpolicy pol on exp_pol.policy_sk = pol.policy_sk 
				left join edw_core.tpolicy_history ph on exp_pol.policy_sk = ph.policy_sk and ph.latest_transaction_in = 'Y'
				left join edw_core.tpolicy ren_pol on ren_pol.policy_sk = exp_pol.renewal_policy_sk
				left join edw_core.tpolicy_history ren_pol_ph on ren_pol.policy_sk = ren_pol_ph.policy_sk and ren_pol_ph.latest_transaction_in = 'Y'
				left join ho_address hol on hol.policy_no = ph.policy_no
				left join ho_address hol_new on hol.address_line_1 = hol_new.address_line_1 and hol.policy_no <> hol_new.policy_no and pol.expiration_dt = hol_new.effective_dt --and hol.effective_dt
				left join pel_address pel on pel.policy_no = ph.policy_no  and pel.primary_location_in = 'Yes'
				left join pel_address pel_new on pel.address_line_1 = pel_new.address_line_1 and pel.policy_no <> pel_new.policy_no and pol.expiration_dt = pel_new.effective_dt
				left join au_address au on au.policy_no = ph.policy_no  
				left join au_address au_new on au.mailing_address_line1 = au_new.mailing_address_line1 and au.policy_no <> au_new.policy_no and pol.expiration_dt = au_new.effective_dt
				left join edw_core.tpolicy ren_pol_new on ren_pol_new.policy_no = case  when pol.product_cd='HO' then hol_new.policy_no
																						when pol.product_cd='PEL' then pel_new.policy_no
																						when pol.product_cd='AU' then au_new.policy_no end 
				where ren_pol.policy_status = 'Cancelled'
				and ren_pol_ph.cancellation_reason_desc in ('Rewritten with Vault','REWRITE WITH VAULT')
				and ren_pol_new.policy_sk <> exp_pol.renewal_policy_sk
				and ren_pol_new.policy_status  = 'Active'
				and ren_pol_new.policy_term  = 'Renewal'; 

				update a
				set a.renewal_policy_sk = b.ren_pol_new_policy_sk,
					a.ren_pol_uw_company_Cd = b.ren_pol_new_uw_company_Cd
				from edw_temp.trenewal_summary_v1_temp_4_initial a
				inner join edw_temp.trenewal_summary_v1_temp_5_cancel_rewrites b on a.policy_sk = b.policy_sk;

				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_6_final;

				
				with exp_pols as
				(
					select * from edw_temp.trenewal_summary_v1_temp_4_initial
				),
				/*
				--pols expiration in current month
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no,
						replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd
						, non_renewal_in, pending_non_renewal_in
				 FROM	edw_core.tpolicy
				 where	expiration_dt between @begin_dt and @end_dt 
				 and source_system_sk = isnull(@param_ssk, source_system_sk)
				),*/
				--customer other inf count
				cust_oth_inf as
				(
					SELECT pol.policy_sk, count(*) oth_inf_ct--pol.policy_no, pol.expiration_dt, pol.original_policy_no, ci.*
					FROM	edw_core.tpolicy pol
					inner join edw_temp.trenewal_summary_v1_temp_0_oth_cust_inf ci on pol.customer_id = ci.customer_id and pol.expiration_dt = ci.inforce_dt and pol.original_policy_no <> ci.original_policy_no
				 	where	expiration_dt between @begin_dt and @end_dt
					group by pol.policy_sk
				),
				/*--pols renewing all in current month
				ren_pols_all as
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no, prior_term_policy_no, prior_policy_no, policy_status,
						replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd, 
						rank() over (partition by prior_term_policy_no 
									order by replace(replace(replace(policy_status,'Expired','2_Expired'),'Cancelled','3_Cancelled'),'Active','1_Active'), policy_sk) rnk
				 FROM	edw_core.tpolicy
				 where	effective_dt between @begin_dt and @end_dt
				 and source_system_sk = isnull(@param_ssk, source_system_sk)
				),
				--pols renewing distinct in current month
				ren_pols as
				(
				 SELECT *
				 FROM	ren_pols_all
				 where rnk = 1
				),
				--pols renewing all in current month
				ren_quotes as
				(
					select *
					from edw_temp.trenewal_summary_v1_temp_1_quotes 
				 	where rnk = 1

				),
				*/
				/*ren_pols as
				--pols renewing in current month
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no, 
						 case when CHARINDEX('-',prior_policy_no) = 0 then prior_policy_no else left(prior_policy_no, CHARINDEX('-',prior_policy_no) - 1) end prior_policy_no
				 FROM	edw_core.tpolicy
				 where	effective_dt between @begin_dt and @end_dt 
				), */
				prm as
				(
					select * from edw_temp.trenewal_summary_v1_temp_2_prm
				),
				max_tr as
				(
					select * from edw_temp.trenewal_summary_v1_temp_3_max_tr
				)
				select 	exp_pols_prm.policy_sk, 
						max_tr.customer_sk, max_tr.broker_sk, max_tr.product_sk, max_tr.sourcE_system_sk, 
						exp_pols_prm.initial_written_prem, 
						exp_pols_prm.effective_date_60_day_prem, 
						exp_pols_prm.effective_date_60_day_comm, 
						exp_pols_prm.mid_term_cancel_amount, 
						case when exp_pols_prm.cancel_ind = 0 then exp_pols_prm.expiring_premium_amount else 0 end 
						expiring_premium_amount, 
						--**************************************redo after checking billing data
						ren_pols_prm.initial_written_prem * (case when ren_pols_prm.flat_cancel_ind = 0 then 1 else 0 end) as expiringpremiumrenewalaccepted,
						exp_pols_prm.expiring_premium_amount * (case when pol.non_renewal_in = 'Yes' then -1 else 0 end) as non_renewal_expiring_premium_amount,
						exp_pols_prm.expiring_premium_amount * (case when pol.pending_non_renewal_in = 'Yes' then -1 else 0 end) as pending_non_renewal_expiring_premium_amount,
						exp_pols_prm.totalsquarefeet,  
						(CASE when exp_pols_prm.product_cd  in ('HO','CO')  and exp_pols_prm.max_tr_residencetype =  'Homeowners' then 'Homeowners'
							  when exp_pols_prm.product_cd in ('HO','CO')  and exp_pols_prm.max_tr_residencetype <> 'Homeowners' then 'Condo/Tenant'
							  when exp_pols_prm.product_cd in ('HO','CO')  then 'Homeowners'
						else 'Non-Home Product'
						end) as residencetype,
						exp_pols_prm.sixty_day_TIV, 
						exp_pols_prm.sixty_day_COVA, 
						exp_pols_prm.sixty_day_rate_on_line, 
						exp_pols_prm.expiring_TIV, 
						exp_pols_prm.expiring_TIV * (case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end)  as expiring_TIV_post_NR,
						exp_pols_prm.expiring_COVA,
						exp_pols_prm.expiring_rate_on_line,
						--1 as policy_ct,
						case when exp_pols_prm.flat_cancel_ind 		<> 0 then 1 else 0 end flatcancel_ind, 
						case when exp_pols_prm.flat_cancel_ind  	 = 0 then 1 else 0 end non_flatcancel_ind, 
						case when exp_pols_prm.mid_term_cancel_ind  <> 0 then 1 else 0 end midterm_cancel_ind,  
						case when exp_pols_prm.cancel_ind = 0 then 1 else 0 end expiring_ind,   
						case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end as nonrenewal_ind, 
						case when exp_pols_prm.pending_non_renewal_in = 'Yes' then 1 else 0 end as pending_nonrenewal_ind, 
						case when exp_pols.renewal_policy_sk is not null then exp_pols.renewal_policy_sk else null end renewal_sk,
						case when exp_pols.renewal_policy_sk is not null then 1 else 0 end renewalcount,
						case when ren_pols_prm.flat_cancel_ind = 0 then 1 else 0 end non_flatcancel_renewal_ind,
						case when exp_pols.renewal_policy_sk is not null then ren_pols_prm.initial_written_prem else null end initial_written_renewal_prem,
						case when exp_pols.renewal_policy_sk is not null then iif(ren_pols_prm.effective_date_60_day_prem=0,ren_pols_prm.initial_written_prem,ren_pols_prm.effective_date_60_day_prem) else null end effective_date_60_day_renewal_prem, 
						case when exp_pols.renewal_policy_sk is not null then iif(ren_pols_prm.effective_date_60_day_comm=0,ren_pols_prm.initial_written_comm,ren_pols_prm.effective_date_60_day_comm) else null end effective_date_60_day_renewal_comm,
						case when exp_pols.renewal_policy_sk is not null then iif(ren_pols_prm.sixty_day_TIV=0,ren_pols_prm.day_0_TIV,ren_pols_prm.sixty_day_TIV) else null end sixty_day_renewal_TIV,
						case when exp_pols.renewal_policy_sk is not null then iif(ren_pols_prm.sixty_day_COVA=0,ren_pols_prm.day_0_COVA,ren_pols_prm.sixty_day_COVA) else null end sixty_day_renewal_COVA,  
						case when exp_pols.renewal_policy_sk is not null then iif(ren_pols_prm.sixty_day_rate_on_line=0,ren_pols_prm.day_0_rate_on_line,ren_pols_prm.sixty_day_rate_on_line) else null end sixty_day_renewal_rate_on_line,  
						case when exp_pols.renewal_policy_sk is not null and exp_pols_prm.totalsquarefeet > 0 
							 then iif(ren_pols_prm.sixty_day_COVA=0,ren_pols_prm.day_0_COVA,ren_pols_prm.sixty_day_COVA)/exp_pols_prm.totalsquarefeet 
							 else null 
						end renewal_accepted_price_sqft
						,case when coalesce(exp_pols.ren_pol_uw_company_cd, exp_pols.ren_quote_uw_company_cd) is null then exp_pols.ren_pol_uw_company_cd
							 when exp_pols.exp_uw_company_cd = coalesce(exp_pols.ren_pol_uw_company_cd, exp_pols.ren_quote_uw_company_cd) then coalesce(exp_pols.ren_pol_uw_company_cd, exp_pols.ren_quote_uw_company_cd)
								else exp_pols.ren_pol_uw_company_cd + ' to ' + coalesce(exp_pols.ren_pol_uw_company_cd,  exp_pols.ren_quote_uw_company_cd) 
						end uw_company_cd
						,case when exp_pols.renewal_policy_sk is not null then 0 
						 	  when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when q.quote_no is not null then 1 
						 	  else 0 
						 end wip_renewal_quote_ct
						,case when exp_pols.renewal_policy_sk is not null then 0 
						 	  when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when q.quote_no is not null 
							   and (q.quote_Status in ('Offered','Not Taken by Insured')
							   		or
									q.first_offered_quote_history_sk is not null
							       ) then 1 
						 	  else 0 
						 end offered_or_not_taken_quote_ct
						,/* commented on olivia's request
						 case when exp_pols.renewal_policy_sk is not null then 0 
						 	  when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when ren_quotes.quote_no is not null then ren_quotes.quote_sk 
						 	  else 0 
						 end*/ 
						 exp_pols.renewal_quote_sk renewal_quote_sk
						,exp_pols.note_desc renewal_quote_note_desc
						,exp_pols.primary_address_state_cd renewal_quote_agency_primary_location_state_cd 
						,isnull(ci.oth_inf_ct,0) expiring_customer_other_inforce_ct
						,case when exp_pols.renewal_policy_sk is not null then ren_pols_prm.day_0_TIV else null end renewal_tiv_amt,
						 case when exp_pols.renewal_policy_sk is not null then ren_pols_prm.day_0_COVA else null end renewal_cova_amt,  
						 case when exp_pols.renewal_policy_sk is not null then ren_pols_prm.day_0_rate_on_line else null end renewal_rate_on_line_amt,  
						 case when exp_pols.renewal_policy_sk is not null then ren_pols_prm.day_0_totalsquarefeet else null end renewal_total_finished_square_feet
				into edw_temp.trenewal_summary_v1_temp_6_final
				from exp_pols
				left join edw_core.tpolicy pol on exp_pols.policy_sk = pol.policy_sk
				left join edw_core.tquote q on q.quote_sk = exp_pols.renewal_quote_sk
				-- join to get prms for expiring policies
				inner join prm exp_pols_prm on exp_pols_prm.policy_sk = exp_pols.policy_sk 
				-- join to get renewals for expiring policies
				-->left join ren_pols on ren_pols.prior_term_policy_no = exp_pols.policy_no 
				--left join ren_pols on replace(ren_pols.prior_policy_no,'x','') = replace(exp_pols.original_policy_no,'x','') and ren_pols.effective_dt = exp_pols.expiration_dt 
				-- join to get renewals quotes for expiring policies
				-->left join ren_quotes on ren_quotes.prior_term_policy_no = exp_pols.policy_no
				--left join ren_quotes on replace(ren_quotes.prior_policy_no,'x','') = replace(exp_pols.original_policy_no,'x','') and ren_quotes.effective_dt = exp_pols.expiration_dt 
				-- join to get prm for renewals 
				left join prm ren_pols_prm on ren_pols_prm.policy_sk = exp_pols.renewal_policy_sk 
				inner join max_tr on exp_pols_prm.policy_sk = max_tr.policy_sk and exp_pols_prm.transaction_seq_no = max_tr.transaction_seq_no
				left join cust_oth_inf ci on ci.policy_sk = exp_pols.policy_sk 
				 
				
				INSERT INTO --select * from  
				[edw_stage].[trenewal_summary_v1]
					( 
						month_sk, policy_sk, customer_sk, broker_sk, product_sk, source_system_sk, 
						expiring_initial_written_premium_amt,
						expiring_sixty_day_written_premium_amt,
						expiring_sixty_day_commission_amt,
						expiring_mid_term_cancelled_premium_amt,
						expiring_written_premium_amt,
						expiring_premium_renewal_accepted_amt,
						expiring_non_renewal_written_premium_amt,
						expiring_pending_non_renewal_written_premium_amt ,
						expiring_total_finished_square_feet ,
						expiring_residence_type,
						expiring_sixty_day_tiv_amt,
						expiring_sixty_day_cova_amt,
						expiring_sixty_day_rate_on_line,
						expiring_tiv_amt, 
						expiring_tiv_post_nr_amt,
						expiring_cova_amt
						,expiring_rate_on_line
						,
						flat_cancelled_ct,
						non_flat_cancelled_ct,
						mid_term_cancelled_ct,
						expiring_ct,
						non_renewal_ct,
						pending_non_renewal_ct,
						renewal_policy_sk,
						renewal_ct,
						renewal_non_flat_cancelled_ct, 
						renewal_initial_written_premium_amt,
						renewal_sixty_day_written_premium_amt,
						renewal_sixty_day_commission_amt,
						renewal_sixty_day_tiv_amt,
						renewal_sixty_day_cova_amt,
						renewal_sixty_day_rate_on_line,
						renewal_accepted_price_sqft, 
						update_ts,
						etl_audit_sk
						,uw_company_cd
						,wip_renewal_quote_ct
						,offered_or_not_taken_quote_ct
						,renewal_quote_sk 
						,expiring_customer_other_inforce_ct
						,renewal_tiv_amt
						,renewal_cova_amt
						,renewal_rate_on_line_amt
						,renewal_total_finished_square_feet
						,expiring_mid_term_endorsement_premium_amt
						,expiring_price_sqft
						,issued_price_sqft
						,renewal_offered_price_sqft
						,cancellation_reason_desc
						,renewal_quote_written_premium_amt
						,renewal_quote_tiv_amt 
						,renewal_quote_rate_on_line
						,renewal_quote_dwelling_limit_amt
						,renewal_quote_other_structures_limit_amt
						,renewal_quote_contents_limit_amt
						,renewal_quote_loss_of_use_limit_amt
						,product_nm 
						,renewal_quote_note_desc
						,renewal_quote_agency_primary_location_state_cd
						,prior_issued_ct
						,prior_issued_premium_amt
						,accepted_renewal_ct 
						,not_accepted_renewal_ct
						,expired_with_no_submission_ct
						,outstanding_renewal_ct
						,in_progress_renewal_ct  
						,closed_with_no_offer_renewal_ct  
						,offered_quote_ct
						,offered_quote_premium_amt
						,risk_address_line_1
						,risk_address_line_2
						,risk_address_unit_no	
						,risk_address_city_nm	
						,risk_address_state_cd	
						,risk_address_zip_cd
					)
				select @month_end_dt_sk, 
						a.policy_sk,   
						a.customer_sk, 
						a.broker_sk, 
						a.product_sk, 
						a.sourcE_system_sk, 
						a.initial_written_prem, 
						a.effective_date_60_day_prem, 
						a.effective_date_60_day_comm, 
						a.expiring_premium_amount as mid_term_cancel_amount,
						a.expiring_premium_amount, 
						a.expiringpremiumrenewalaccepted,
						a.expiring_premium_amount as non_renewal_expiring_premium_amount,
						a.pending_non_renewal_expiring_premium_amount,
						a.totalsquarefeet,  
						a.residencetype,
						a.sixty_day_TIV, 
						a.sixty_day_COVA,
						a.sixty_day_rate_on_line, 
						a.expiring_TIV, 
						a.expiring_TIV_post_NR,
						a.expiring_COVA,
						a.expiring_rate_on_line,
						a.flatcancel_ind, 
						a.non_flatcancel_ind, 
						case when a.nonrenewal_ind = 1 then 0
							 when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
							 else a.midterm_cancel_ind
						end midterm_cancel_ind,  
						a.expiring_ind,   
						case when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
                        else a.nonrenewal_ind
                        end nonrenewal_ind,
						a.pending_nonrenewal_ind, 
						a.renewal_sk,
						a.renewalcount,
						a.non_flatcancel_renewal_ind,
						a.initial_written_renewal_prem,
						a.effective_date_60_day_renewal_prem, 
						a.effective_date_60_day_renewal_comm,
						a.sixty_day_renewal_TIV,
						a.sixty_day_renewal_COVA,
						a.sixty_day_renewal_rate_on_line,  
						a.renewal_accepted_price_sqft, 
						getdate(), 
						@etl_audit_sk 
						,a.uw_company_cd
						,a.wip_renewal_quote_ct
						,a.offered_or_not_taken_quote_ct
						,a.renewal_quote_sk
						,a.expiring_customer_other_inforce_ct
						,a.renewal_tiv_amt,
						 a.renewal_cova_amt,  
						 a.renewal_rate_on_line_amt,
						 a.renewal_total_finished_square_feet,
						 --??????????????????????????????????????????????????*****************************
						(a.effective_date_60_day_prem - a.initial_written_prem - a.mid_term_cancel_amount) AS expiring_mid_term_endorsement_premium_amt,
						case 
							when a.totalsquarefeet > 0
							then a.expiring_COVA/a.totalsquarefeet
							else 0 
						end AS expiring_price_sqft,
						
						case 
							when a.totalsquarefeet > 0
							then a.sixty_day_COVA/a.totalsquarefeet
							else 0 
						end AS issued_price_sqft,
						case 
							when a.renewal_total_finished_square_feet > 0 
							then a.renewal_cova_amt/a.renewal_total_finished_square_feet 
							else 0 
						end AS renewal_offered_price_sqft
						,b.cancellation_reason_desc
						,(qh.premium_amt-qh.tax_fee_surcharge_amt)as renewal_quote_written_premium_amt
						,qhc.total_insured_value_amt 	renewal_quote_tiv_amt
						,qhc.rate_on_line 				renewal_quote_rate_on_line
						,qhc.dwelling_limit_amt 		renewal_quote_dwelling_limit_amt
						,qhc.other_structures_limit_amt renewal_quote_other_structures_limit_amt
						,qhc.contents_limit_amt 		renewal_quote_contents_limit_amt
						,qhc.loss_of_use_limit_amt 		renewal_quote_loss_of_use_limit_amt
						,case when pr.product_nm = 'Condo' then 'Homeowners' else pr.product_nm end product_nm 
						,a.renewal_quote_note_desc
						,a.renewal_quote_agency_primary_location_state_cd 
						,case when a.non_flatcancel_ind = 1  
						 then 1 
						 else 0 
						 end prior_issued_ct 
						,case when a.non_flatcancel_ind = 1  
						 then a.expiring_premium_amount 
						 else 0 
						 end prior_issued_premium_amt
						,case when a.non_flatcancel_ind = 1 
							  and  a.renewalcount = 1 
							  and  case when a.nonrenewal_ind = 1 then 0
										when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
										else a.midterm_cancel_ind
									end = 0 
							  and  ren_pol.billing_PAID_IN = 'Yes' 
							  and  (ren_pol.cancellation_effective_dt is null or ren_pol.cancellation_effective_dt <> ren_pol.effective_dt)
						 then 1 
						 else 0 
						 end accepted_renewal_ct --renewal is issued and paid
						,case 
							  --if expiring is midterm cancel then not accepted will be 0
							  when a.non_flatcancel_ind = 1 
                              and  a.renewalcount = 1 
                              and a.nonrenewal_ind = 0
                              and  case when a.nonrenewal_ind = 1 then 0
                                        when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
                                        else a.midterm_cancel_ind
                                    end = 1  
                              then 0 
                              --if expiring is non renewal then not accepted will be 0
							  when a.non_flatcancel_ind = 1 
                              and  a.renewalcount = 1 
                              and a.nonrenewal_ind = 1
                              then 0 
                              --if expiring is not non renewal and not midterm cancel then check for renewal billing and status
							  when a.non_flatcancel_ind = 1 
                              and  a.renewalcount = 1 
                              and a.nonrenewal_ind = 0
                              and  case when a.nonrenewal_ind = 1 then 0
                                        when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
                                        else a.midterm_cancel_ind
                                    end = 0 
                              and   (       ren_pol.billing_PAID_IN is null 
                                        and  ren_ph.transaction_type like 'Cancel%'
                                        --took out below since I added logic to match on address above
                                        --and  ren_ph.cancellation_reason_desc not in ('Rewritten with Vault')
                                        --and  upper(ren_ph.cancellation_reason_desc) not in ('REWRITE WITH VAULT') 
                                    )
									or
                                    ( ren_pol.billing_PAID_IN = 'Yes' 
                                      and  (ren_pol.cancellation_effective_dt is not null and ren_pol.cancellation_effective_dt = ren_pol.effective_dt)
                                    )
                              then 1 
                              when a.non_flatcancel_ind = 1 
                              and  a.renewalcount = 0 
                              and a.nonrenewal_ind = 0
                              and  a.wip_renewal_quote_ct = 1 
                              and q.first_offered_quote_history_sk is not null 
                              and q.quote_source_status = 'Closed'   
                                then 1   
                                else 0 
                         end not_accepted_renewal_ct --renewals is issued, renewal status is cancelled and renewal is not paid 
						 							 --renewal is not issued but just in submission or quote status
													 --if no renewal quote (in case of NR or midterm cancels), then its counted in NR bucket
													 --if quote first offered date is not null and quote source status is closed
						,case 
							  when a.non_flatcancel_ind = 1 
							  and a.nonrenewal_ind = 0
							  and  a.renewalcount = 0 
							  and a.midterm_cancel_ind = 0
							  and  a.renewal_quote_sk is null  
								then 1 
								else 0 
						 end expired_with_no_submission_ct
						,case when a.non_flatcancel_ind = 1 
							  and  a.renewalcount = 1 
							  and  case when a.nonrenewal_ind = 1 then 0
										when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
										else a.midterm_cancel_ind
									end = 0 
							  and  ren_pol.billing_PAID_IN is null 
    						  and  ren_ph.transaction_type not like 'Cancel%'
						 then 1 
						 else 0 
						 end outstanding_renewal_ct --renewals that are issued and not paid and not cancelled 
						,case when a.non_flatcancel_ind = 1 
							  and  a.renewalcount = 0 
							  and  a.nonrenewal_ind = 0 
							  and  case when a.nonrenewal_ind = 1 then 0
										when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
										else a.midterm_cancel_ind
									end = 0 
							  and  q.quote_source_status in ('Bound','In Progress')
							  --and  q.first_offered_quote_history_sk is not null
						 then 1 
						 else 0 
						 end in_progress_renewal_ct  
						,case when a.non_flatcancel_ind = 1 
							  and  a.renewalcount = 0 
							  and  case when a.nonrenewal_ind = 1 then 0
										when ren_pol.policy_sk is not null and ren_pol.policy_status in ('Active','Expired') then 0
										else a.midterm_cancel_ind
									end = 0 
							  and  a.nonrenewal_ind = 0
							  and  q.quote_source_status = 'Closed'
							  and  q.first_offered_quote_history_sk is null
						 then 1 
						 else 0 
						 end closed_with_no_offer_renewal_ct  
						 ,case when a.non_flatcancel_ind = 1 and 
									( (q.first_offered_quote_history_sk IS NOT NULL and q.quote_status in ('In Progress')) 
									OR q.quote_status in ( 'Not taken', 'Offered') 
									OR a.renewalcount = 1 
									)
							  then 1 
						 	  else 0 
						 end offered_quote_ct   
						 ,case when a.non_flatcancel_ind = 1 and 
									( (q.first_offered_quote_history_sk IS NOT NULL and q.quote_status in ('In Progress')) 
									OR q.quote_status in ( 'Not taken', 'Offered') 
									OR a.renewalcount = 1 
									)
							  then qh.premium_amt 
						 	  else 0 
						 end offered_quote_premium_amt
						 ,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.address_line_1, hloc2.address_line_1)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.address_line_1, cloc2.address_line_1)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.address_line_1, ploc2.address_line_1)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.address_line_1, bloc2.address_line_1)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_line1,exp_pol.mailing_address_line1)
							else NULL
						end risk_address_line_1
						,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.address_line_2, hloc2.address_line_2)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.address_line_2, cloc2.address_line_2)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.address_line_2, ploc2.address_line_2)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.address_line_2, bloc2.address_line_2)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_line2,exp_pol.mailing_address_line2)
							else NULL
						end risk_address_line_2
						,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.unit_no, hloc2.unit_no)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.unit_no, cloc2.unit_no)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.unit_no, ploc2.unit_no)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.unit_no, bloc2.unit_no)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_unit_no,exp_pol.mailing_address_unit_no)
							else NULL
						end risk_address_unit_no
						,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.city_nm, hloc2.city_nm)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.city_nm, cloc2.city_nm)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.city_nm, ploc2.city_nm)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.city_nm, bloc2.city_nm)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_city_nm,exp_pol.mailing_address_city_nm)
							else NULL
						end risk_address_city_nm
						,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.state_cd, hloc2.state_cd)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.state_cd, cloc2.state_cd)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.state_cd, ploc2.state_cd)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.state_cd, bloc2.state_cd)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_state_cd,exp_pol.mailing_address_state_cd)
							else NULL
						end risk_address_state_cd
						,case
							when ren_pol.product_cd in ('HO','CO') then isnull(hloc.zip_cd, hloc2.zip_cd)
							when ren_pol.product_cd in ('LUX')     then isnull(cloc.zip_cd, cloc2.zip_cd)
							when ren_pol.product_cd in ('PEL')     then isnull(ploc.zip_cd, ploc2.zip_cd)
							when ren_pol.product_cd in ('BY')      then isnull(bloc.zip_cd, bloc2.zip_cd)
							when ren_pol.product_cd in ('AU')      then isnull(ren_pol.mailing_address_zip_cd,exp_pol.mailing_address_zip_cd)
							else NULL
						end risk_address_zip_cd
				from edw_temp.trenewal_summary_v1_temp_6_final a
				left join ( select distinct cancellation_reason_desc, policy_sk, effective_dt 
							FROM edw_core.tpolicy_history ph
							Where transaction_type  = 'Cancellation'
							and latest_transaction_in ='Y'
						  ) b on a.policy_sk = b.policy_sk
				left join edw_core.tquote q on q.quote_sk = a.renewal_quote_sk 
				left join edw_core.tquote_history qh on qh.quote_sk = q.quote_sk and qh.latest_transaction_in = 'Y'
				left join edw_core.tquote_home_coverage qhc on qhc.quote_no = qh.quote_no and qhc.effective_dt = qh.effective_dt 
																and qhc.transaction_seq_no = qh.transaction_seq_no
				left join edw_core.tproduct pr on a.product_sk = pr.product_sk
				left join edw_core.tpolicy ren_pol on ren_pol.policy_sk = a.renewal_sk
				left join edw_core.tpolicy_history ren_ph on a.renewal_sk = ren_ph.policy_sk and ren_ph.latest_transaction_in = 'Y'
				LEFT JOIN edw_core.tpel_location ploc ON ren_ph.policy_history_sk = ploc.policy_history_sk and ploc.primary_location_in = 'Yes'
				LEFT JOIN edw_core.tcollection_coverage ccov ON ren_ph.policy_history_sk = ccov.policy_history_sk
				LEFT JOIN edw_core.tcollection_location cloc ON ccov.collection_location_sk = cloc.collection_location_sk
				LEFT JOIN edw_core.thome_coverage hcov ON hcov.policy_history_sk = ren_ph.policy_history_sk
				LEFT JOIN edw_core.thome_location hloc ON hcov.home_location_sk = hloc.home_location_sk
				LEFT JOIN edw_core.tmarine_boat_yacht_coverage bcov ON bcov.policy_history_sk = ren_ph.policy_history_sk
				LEFT JOIN edw_core.tmarine_boat_yacht_location bloc ON bcov.marine_boat_yacht_location_sk = bloc.marine_boat_yacht_location_sk
				left join edw_core.tpolicy exp_pol on exp_pol.policy_sk = a.policy_sk
				left join edw_core.tpolicy_history exp_pol_ph on a.policy_sk = exp_pol_ph.policy_sk and exp_pol_ph.latest_transaction_in = 'Y'
				LEFT JOIN edw_core.tpel_location ploc2 ON exp_pol_ph.policy_history_sk = ploc2.policy_history_sk and ploc2.primary_location_in = 'Yes'
				LEFT JOIN edw_core.tcollection_coverage ccov2 ON exp_pol_ph.policy_history_sk = ccov2.policy_history_sk
				LEFT JOIN edw_core.tcollection_location cloc2 ON ccov2.collection_location_sk = cloc2.collection_location_sk
				LEFT JOIN edw_core.thome_coverage hcov2 ON hcov2.policy_history_sk = exp_pol_ph.policy_history_sk
				LEFT JOIN edw_core.thome_location hloc2 ON hcov2.home_location_sk = hloc2.home_location_sk
				LEFT JOIN edw_core.tmarine_boat_yacht_coverage bcov2 ON bcov2.policy_history_sk = exp_pol_ph.policy_history_sk
				LEFT JOIN edw_core.tmarine_boat_yacht_location bloc2 ON bcov2.marine_boat_yacht_location_sk = bloc2.marine_boat_yacht_location_sk;  

				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);	
				if @in_yearmonth is not null
				begin
					set @new_last_source_extract_ts= @last_source_extract_ts
				end 

				update edw_stage.trenewal_summary_v1
                set  non_renewal_ct = 0
                where month_sk = @month_end_dt_sk
                and non_renewal_ct = 1 and accepted_renewal_ct = 1; 

				update edw_stage.trenewal_summary_v1
				set pending_process_ct = prior_issued_ct - (isnull(expired_with_no_submission_ct,0) + mid_term_cancelled_ct
															+ non_renewal_ct + accepted_renewal_ct
															+ not_accepted_renewal_ct + outstanding_renewal_ct
															+ in_progress_renewal_ct + closed_with_no_offer_renewal_ct)
					,in_progress_premium_amt = offered_quote_premium_amt
					,closed_with_no_offer_premium_amt = expiring_written_premium_amt
					,accepted_premium_amt = renewal_initial_written_premium_amt
					,not_accepted_premium_amt = expiring_written_premium_amt
					,outstanding_premium_amt  = renewal_initial_written_premium_amt
					,need_attention_premium_amt = expiring_written_premium_amt
				where month_sk = @month_end_dt_sk; 

				update edw_stage.trenewal_summary_v1
				set  outstanding_in_progress_renewal_ct = outstanding_renewal_ct + in_progress_renewal_ct 
				where month_sk = @month_end_dt_sk

				update edw_stage.trenewal_summary_v1
				set  closed_with_no_offer_pending_process_renewal_ct = closed_with_no_offer_renewal_ct + pending_process_ct 
				where month_sk = @month_end_dt_sk

				update edw_stage.trenewal_summary_v1
				set  outstanding_in_progress_renewal_ct = outstanding_renewal_ct + in_progress_renewal_ct 
				where month_sk = @month_end_dt_sk

				update edw_stage.trenewal_summary_v1
				set  closed_with_no_offer_pending_process_renewal_ct = closed_with_no_offer_renewal_ct + pending_process_ct 
				where month_sk = @month_end_dt_sk

				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				if @in_yearmonth is not null
				begin
					set @parameter_desc= 'last_source_extract_ts = ' + CAST(@yearmonth AS VARCHAR(200))
				end 
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;   
				
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_0_oth_cust_inf;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_1_quotes;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_2_prm;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_3_max_tr;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_4_initial;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_5_cancel_rewrites;
				DROP TABLE IF EXISTS edw_temp.trenewal_summary_v1_temp_6_final;
				 
				FETCH NEXT FROM c1_rec INTO @yearmonth;
			END; 
		CLOSE c1_rec;
		DEALLOCATE c1_rec;  

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
