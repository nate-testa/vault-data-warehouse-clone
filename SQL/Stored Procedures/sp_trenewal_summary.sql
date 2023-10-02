-- ================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the renewals data for each month
-------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------
-- 08/14/23		Architha Gudimalla				1. Created this procedure 
-- 09/12/23		Architha Gudimalla				2. Added additional columns after discussing with Olivia 
-- 10/02/23		Architha Gudimalla				3. Corrected code afrer testing
-- ================================================================================================================ 

CREATE OR ALTER PROCEDURE [edw_core].[sp_trenewal_summary]
@in_yearmonth int
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
		DECLARE @current_date DATETIME=GETDATE()   

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm); 
	
		DECLARE @month_begin_dt_sk INT
		DECLARE @month_end_dt_sk INT
		DECLARE @begin_dt_sk INT
		DECLARE @end_dt_sk INT
		DECLARE @prev_month_end_dt_sk INT
		DECLARE @month_begin_dt DATETIME
		DECLARE @month_end_dt DATETIME 
		DECLARE @begin_dt DATETIME
		DECLARE @end_dt DATETIME 
		DECLARE @year INT 
		DECLARE @yearmonth INT 
		DECLARE @year_begin_sk INT 
		DECLARE @proc_run_month_end_dt date
		DECLARE @proc_run_month INT 
		
		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth = @in_yearmonth 
		group by yearmonth
		/*union 
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth >  case when @in_yearmonth is not null then @in_yearmonth else @last_source_extract_ts end
		  and   yearmonth <= case when @in_yearmonth is not null then @in_yearmonth else concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) ) end
		group by yearmonth*/
		order by 1;    

		DECLARE @parameter_desc VARCHAR(255) 

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

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

				delete from edw_core.trenewal_summary
				where month_sk = @month_end_dt_sk;

				with exp_pols as
				--pols expiration in current month
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt
				 FROM	edw_core.tpolicy
				 where	expiration_dt between @begin_dt and @end_dt
				 --where	concat(datepart(yyyy,expiration_dt),iif(datepart(mm,expiration_dt) < 10,'0','') ,datepart(mm,expiration_dt) ) = @yearmonth
				), 
				ren_pols as
				--pols renewing in current month
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt
				 FROM	edw_core.tpolicy
				 where	effective_dt between @begin_dt and @end_dt
				 --where	concat(datepart(yyyy,effective_dt),iif(datepart(mm,effective_dt) < 10,'0','') ,datepart(mm,effective_dt) ) = @yearmonth
				), 
				prm as
				(
				 SELECT tr.policy_sk, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk, 
		 				sum(tr.premium_amt) premium_amt,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and policy_transaction_type_sk in (1,3) --'Renewal','New Business' 
								then tr.premium_amt * round((365.0*1/(expiration_dt_sk - effective_dt_sk)),5) 
								else 0 
								end) as initial_written_prem,
						sum(CASE WHEN transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then tr.premium_amt * round((365.0*1/(expiration_dt_sk - effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_prem,
						sum(CASE WHEN transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then tr.commission_amt  * round((365.0*1/(expiration_dt_sk - effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_comm,  
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and transaction_effective_dt_sk <> expiration_dt_sk and policy_transaction_type_sk in (4,5) --('Cancellation', 'Reinstatement')
								  and  (transaction_effective_dt_sk - effective_dt_sk  > 60 or transaction_dt_sk - effective_dt_sk  > 60)
								then tr.premium_amt * round((365.0*1/(expiration_dt_sk - effective_dt_sk)),5) 
								else 0 
								end) as mid_term_cancel_amount, 
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk  
								then tr.premium_amt * round((365.0*1/(expiration_dt_sk - effective_dt_sk)),5) 
								else 0 
								end) as expiring_premium_amount,
						count(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and policy_transaction_type_sk in (4) --('Cancellation'')
								  and  (transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61)
								then pol.policy_sk  
								end) as cancel_sixty_days_ind, 
						count(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and policy_transaction_type_sk in (4) --('Cancellation'')
								  and  (transaction_dt_sk - expiration_dt_sk < 61)
								then NULL 
								else pol.policy_sk  
								end) cancel_ind, --expiring_ind, --all_cancelled_policy_num,
						sum(CASE WHEN tr.policy_transaction_sk = sixty_day_pol_tr.policy_transaction_sk
								  then hoc.total_insured_value_amt  
								else 0 
								end) as sixty_day_TIV,
						sum(CASE WHEN tr.policy_transaction_sk = sixty_day_pol_tr.policy_transaction_sk
								  then hoc.dwelling_limit_amt  
								else 0 
								end) as sixty_day_COVA,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.total_insured_value_amt  
								else 0 
								end) as expiring_TIV,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.dwelling_limit_amt  
								else 0 
								end) as expiring_COVA,
						sum(CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  then hoc.total_finished_square_feet  
								else 0 
								end) as totalsquarefeet,
						max(CASE when tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk 
								 then residence_type
								 else null
							end) as max_tr_residencetype,
						max(pol.non_renewal_in) non_renewal_in,
						max(pol.policy_term) policy_term,
						max(pol.product_cd) product_cd 
				 FROM	edw_core.tpolicy_transaction tr
				 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
				 inner join (
								 SELECT policy_sk, max(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) policy_transaction_sk, 
												   rank() over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) rnk
								 FROM	edw_core.tpolicy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 and	transaction_effective_dt_sk <= @end_dt_sk 
							) max_pol_tr on tr.policy_sk = max_pol_tr.policy_sk
				 inner join (
								 SELECT policy_sk, max(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) policy_transaction_sk, 
												   rank() over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) rnk
								 FROM	edw_core.tpolicy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 and	transaction_effective_dt_sk <= @end_dt_sk
								 and 	(transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61) 
							) sixty_day_pol_tr on tr.policy_sk = sixty_day_pol_tr.policy_sk
				 left join edw_core.thome_coverage hoc on hoc.home_coverage_sk = tr.coverage_sk
				 where	max_pol_tr.rnk = 1
				 and sixty_day_pol_tr.rnk = 1
				 and effective_dt_sk <= @end_dt_sk
				 and	transaction_effective_dt_sk <= @end_dt_sk
				 and   (concat(datepart(yyyy,pol.expiration_dt),iif(datepart(mm,pol.expiration_dt) < 10,'0','') ,datepart(mm,pol.expiration_dt) ) = @yearmonth or
						concat(datepart(yyyy,pol.effective_dt),iif(datepart(mm,pol.effective_dt) < 10,'0','') ,datepart(mm,pol.effective_dt) ) = @yearmonth)
				 group by tr.policy_sk, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk
				)
				INSERT INTO --select * from  
				edw_core.trenewal_summary
					( 
						month_sk, policy_sk, customer_sk, broker_sk, product_sk, source_system_sk, 
						expiring_initial_written_premium_amt,
						expiring_sixty_day_written_premium_amt,
						expiring_sixty_day_commission_amt,
						expiring_mid_term_cancelled_premium_amt,
						expiring_written_premium_amt,
						expiring_premium_renewal_accepted_amt,
						expiring_non_renewal_written_premium_amt,
						expiring_total_finished_square_feet ,
						expiring_residence_type,
						expiring_sixty_day_tiv_amt,
						expiring_sixty_day_cova_amt,
						expiring_tiv_amt, 
						expiring_tiv_post_nr_amt,
						expiring_cova_amt,
						flat_cancelled_ct,
						non_flat_cancelled_ct,
						mid_term_cancelled_ct,
						expiring_ct,
						non_renewal_ct,
						renewal_ct,
						renewal_non_flat_cancelled_ct, 
						renewal_initial_written_premium_amt,
						renewal_sixty_day_written_premium_amt,
						renewal_sixty_day_commission_amt,
						renewal_sixty_day_tiv_amt,
						renewal_sixty_day_cova_amt,
						renewal_accepted_price_sqft, 
						update_ts,
						etl_audit_sk
					)
				select 	@month_end_dt_sk, 
						exp_pols_prm.policy_sk, exp_pols_prm.customer_sk, exp_pols_prm.broker_sk, exp_pols_prm.product_sk, exp_pols_prm.sourcE_system_sk, 
						exp_pols_prm.initial_written_prem, exp_pols_prm.effective_date_60_day_prem, exp_pols_prm.effective_date_60_day_comm, 
						exp_pols_prm.mid_term_cancel_amount, 
						case when exp_pols_prm.cancel_ind is null then exp_pols_prm.expiring_premium_amount else 0 end expiring_premium_amount, 
						exp_pols_prm.expiring_premium_amount * (case when ren_pols_prm.cancel_sixty_days_ind is null then 1 else 0 end) as expiringpremiumrenewalaccepted,
						exp_pols_prm.expiring_premium_amount * (case when exp_pols_prm.non_renewal_in = 'Yes' then -1 else 0 end) as non_renewal_expiring_premium_amount,
						exp_pols_prm.totalsquarefeet,  
						(CASE when exp_pols_prm.product_cd = 'HO'  and exp_pols_prm.max_tr_residencetype =  'Homeowners' then 'Homeowners'
								 when exp_pols_prm.product_cd = 'HO'  and exp_pols_prm.max_tr_residencetype <> 'Homeowners' then 'Condo/Tenant' 
						else 'Non-Home Product'
						end) as residencetype,
						exp_pols_prm.sixty_day_TIV, exp_pols_prm.sixty_day_COVA, 
						exp_pols_prm.expiring_TIV, 
						exp_pols_prm.expiring_TIV * (case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end) as expiring_TIV_post_NR,
						exp_pols_prm.expiring_COVA,
						--1 as policy_ct,
						case when exp_pols_prm.cancel_sixty_days_ind is not null then 1 else 0 end flatcancel_ind, 
						case when exp_pols_prm.cancel_sixty_days_ind is null then 1 else 0 end non_flatcancel_ind, 
						case when exp_pols_prm.cancel_ind is not null and exp_pols_prm.cancel_sixty_days_ind is null then 1 else 0 end midterm_cancel_ind,  
						case when exp_pols_prm.cancel_ind is null then 1 else 0 end expiring_ind,   
						case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end as nonrenewal_ind,
						--case when exp_pols_prm.policy_term	 = 'New' then 1 else 0 end as newbusiness_ind,
						--case when exp_pols_prm.policy_term	 = 'Renewal' then 1 else 0 end as renewal_ind,
						case when ren_pols.policy_sk is not null then 1 else 0 end renewalcount,
						case when ren_pols_prm.cancel_sixty_days_ind is null then 1 else 0 end non_flatcancel_renewal_ind,
						case when ren_pols.policy_sk is not null then ren_pols_prm.initial_written_prem else null end initial_written_renewal_prem,
						case when ren_pols.policy_sk is not null then ren_pols_prm.effective_date_60_day_prem else null end effective_date_60_day_renewal_prem, 
						case when ren_pols.policy_sk is not null then ren_pols_prm.effective_date_60_day_comm else null end effective_date_60_day_renewal_comm,
						case when ren_pols.policy_sk is not null then ren_pols_prm.sixty_day_TIV else null end sixty_day_renewal_TIV,
						case when ren_pols.policy_sk is not null then ren_pols_prm.sixty_day_COVA else null end sixty_day_renewal_COVA,  
						case when ren_pols.policy_sk is not null and exp_pols_prm.totalsquarefeet > 0 
							 then ren_pols_prm.sixty_day_COVA/exp_pols_prm.totalsquarefeet 
							 else null 
						end renewal_accepted_price_sqft, 
						getdate(), @etl_audit_sk 
				from exp_pols
				-- join to get prms for expiring policies
				inner join prm exp_pols_prm on exp_pols_prm.policy_sk = exp_pols.policy_sk 
				-- join to get renewals for expiring policies
				left join ren_pols on ren_pols.policy_no = exp_pols.policy_no and ren_pols.effective_dt = exp_pols.effective_dt 
				-- join to get prm for renewals 
				left join prm ren_pols_prm on ren_pols_prm.policy_sk = ren_pols.policy_sk 
				 
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 
				 
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
