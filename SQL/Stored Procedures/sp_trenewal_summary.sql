/****** Object:  StoredProcedure [edw_core].[sp_trenewal_summary]    Script Date: 11/16/2023 10:55:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the renewals data for each month
------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------------------
-- 08/14/23		Architha Gudimalla				1. Created this procedure 
-- 09/12/23		Architha Gudimalla				2. Added additional columns after discussing with Olivia 
-- 10/02/23		Architha Gudimalla				3. Corrected code afrer testing table
-- 10/18/23		Architha Gudimalla				4. Used source_system_sk from tpolicy instead of tpolicy_transaction in prm subquery 
-- 11/14/23		Architha Gudimalla				5. Added transaction dt filter to prm qubquery
--												   Updated premiums to use net prm
-- 11/15/23		Architha Gudimalla				6. Added logic for cancel rewrites
-- 11/15/23		Architha Gudimalla				7. Added uw_company_cd
-- 11/17/23		Architha Gudimalla				8. Fixed divide by 0 error
-- ==================================================================================================================================== 

ALTER     PROCEDURE [edw_core].[sp_trenewal_summary]
@in_yearmonth int = null
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
		
		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth between  (case when @in_yearmonth is not null and right(@in_yearmonth,2) in ('01','02') 
										 then @in_yearmonth - 90 
										 when @in_yearmonth is not null and right(@in_yearmonth,2) not in ('01','02') 
										 then @in_yearmonth - 2
									end) 
						  and @in_yearmonth
		group by yearmonth
		union 
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth between  (case when @in_yearmonth is null and right(@last_source_yearmonth,2) in ('01','02') 
										 then @last_source_yearmonth - 90 
										 when @in_yearmonth is null and right(@last_source_yearmonth,2) not in ('01','02') 
										 then @last_source_yearmonth - 2
									end) 
						  and @last_source_yearmonth
		union 
		select	yearmonth
		from	edw_core.tdate
		where	yearmonth >  case when @in_yearmonth is null then @last_source_yearmonth end
		  and   yearmonth <= case when @in_yearmonth is null then concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) ) end
		group by yearmonth
		order by 1; 

		print 'aa'   

		DECLARE @parameter_desc VARCHAR(255) 

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

			print @yearmonth

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
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no,
						replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd
				 FROM	edw_core.tpolicy
				 where	expiration_dt between @begin_dt and @end_dt 
				),
				--pols renewing all in current month
				ren_pols_all as
				(
				 SELECT policy_sk, policy_no, effective_dt, expiration_dt, original_policy_no,
						replace(replace(uw_company_nm,'Vault E & S Insurance Company', 'VES'),'Vault Reciprocal Exchange', 'VRE') uw_company_Cd, 
						 case when prior_policy_no is null  then original_policy_no
								  when CHARINDEX('-',prior_policy_no) = 0 then prior_policy_no 
								  else left(prior_policy_no, CHARINDEX('-',prior_policy_no) - 1) 
						end prior_policy_no,
						rank() over (partition by case when prior_policy_no is null  then original_policy_no
												 	   when CHARINDEX('-',prior_policy_no) = 0 then prior_policy_no 
								  					   else left(prior_policy_no, CHARINDEX('-',prior_policy_no) - 1) 
												  end order by policy_sk) rnk
				 FROM	edw_core.tpolicy
				 where	effective_dt between @begin_dt and @end_dt 
				),
				--pols renewing distinct in current month
				ren_pols as
				(
				 SELECT *
				 FROM	ren_pols_all
				 where rnk = 1
				),
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
				 SELECT tr.policy_sk, 
				 		--tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk, 
				 		max(tr.transaction_seq_no) transaction_seq_no,
		 				sum(tr.premium_amt - tr.tax_fee_surcharge_amt) premium_amt,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('New','Renewal') --'Renewal','New Business' 
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round((365.0*1/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as initial_written_prem,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round((365.0*1/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_prem,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then tr.commission_amt  * round((365.0*1/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_comm,  
						sum(CASE WHEN tr.transaction_seq_no = max_pol_tr.transaction_seq_no
								  and transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation', 'Reinstatement')
								  and  (transaction_effective_dt_sk - effective_dt_sk  > 60 or transaction_dt_sk - effective_dt_sk  > 60)
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round((365.0*1/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as mid_term_cancel_amount, 
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk  
								then (tr.premium_amt - tr.tax_fee_surcharge_amt) * round((365.0*1/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as expiring_premium_amount,
						sum(distinct CASE WHEN tr.policy_transaction_sk = max_pol_tr.policy_transaction_sk
								  and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
								  and  (transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61)
								then 1
								else 0
								end) as cancel_sixty_days_ind, 
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
				 inner join edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_sk = tr.policy_transaction_type_sk
				 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
				 inner join (
								 SELECT policy_sk, max(policy_transaction_sk) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) policy_transaction_sk, 
												max(transaction_seq_no) over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) transaction_seq_no, 
												   rank() over (partition by policy_sk 
																		order by transaction_seq_no desc, policy_transaction_sk desc) rnk
								 FROM	edw_core.tpolicy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 --and	transaction_effective_dt_sk <= @end_dt_sk 
							) max_pol_tr on tr.policy_sk = max_pol_tr.policy_sk
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
				 left join edw_core.thome_coverage hoc on hoc.home_coverage_sk = tr.coverage_sk
				 where	max_pol_tr.rnk = 1
				 and (sixty_day_pol_tr.rnk = 1 or sixty_day_pol_tr.rnk is null)
				 and effective_dt_sk <= @end_dt_sk
				 --and	transaction_dt_sk <= @end_dt_sk
				 --and	transaction_effective_dt_sk <= @end_dt_sk
				 and transaction_dt_sk - expiration_dt_sk <= 60
				 and   (pol.expiration_dt between @begin_dt and @end_dt or
						pol.effective_dt between @begin_dt and @end_dt)
				 group by tr.policy_sk--, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk
				),
				max_tr as
				(
					select policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
					from edw_core.tpolicy_transaction 
					where effective_dt_sk <= @end_dt_sk
					--and   transaction_effective_dt_sk <= @end_dt_sk
					--and   transaction_dt_sk <= @end_dt_sk 
					group by policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
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
						renewal_policy_sk,
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
						,uw_company_cd
					)
				select 	@month_end_dt_sk, 
						exp_pols_prm.policy_sk, 
						max_tr.customer_sk, max_tr.broker_sk, max_tr.product_sk, max_tr.sourcE_system_sk, 
						exp_pols_prm.initial_written_prem, 
						exp_pols_prm.effective_date_60_day_prem, 
						exp_pols_prm.effective_date_60_day_comm, 
						exp_pols_prm.mid_term_cancel_amount, 
						case when exp_pols_prm.cancel_ind = 0 then exp_pols_prm.expiring_premium_amount else 0 end 
						expiring_premium_amount, 
						exp_pols_prm.expiring_premium_amount * (case when ren_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end) as expiringpremiumrenewalaccepted,
						exp_pols_prm.expiring_premium_amount * (case when exp_pols_prm.non_renewal_in = 'Yes' then -1 else 0 end) as non_renewal_expiring_premium_amount,
						exp_pols_prm.totalsquarefeet,  
						(CASE when exp_pols_prm.product_cd = 'HO'  and exp_pols_prm.max_tr_residencetype =  'Homeowners' then 'Homeowners'
								 when exp_pols_prm.product_cd = 'HO'  and exp_pols_prm.max_tr_residencetype <> 'Homeowners' then 'Condo/Tenant' 
						else 'Non-Home Product'
						end) as residencetype,
						exp_pols_prm.sixty_day_TIV, 
						exp_pols_prm.sixty_day_COVA, 
						exp_pols_prm.expiring_TIV, 
						exp_pols_prm.expiring_TIV * (case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end)  as expiring_TIV_post_NR,
						exp_pols_prm.expiring_COVA,
						--1 as policy_ct,
						case when exp_pols_prm.cancel_sixty_days_ind <> 0 then 1 else 0 end flatcancel_ind, 
						case when exp_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end non_flatcancel_ind, 
						case when exp_pols_prm.cancel_ind <> 0 and exp_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end midterm_cancel_ind,  
						case when exp_pols_prm.cancel_ind = 0 then 1 else 0 end expiring_ind,   
						case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end as nonrenewal_ind, 
						case when ren_pols.policy_sk is not null then ren_pols.policy_sk else null end renewal_sk,
						case when ren_pols.policy_sk is not null then 1 else 0 end renewalcount,
						case when ren_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end non_flatcancel_renewal_ind,
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
						,case when ren_pols.uw_company_cd is null then exp_pols.uw_company_cd
							 when exp_pols.uw_company_cd = ren_pols.uw_company_cd then ren_pols.uw_company_cd
								else exp_pols.uw_company_cd + ' to ' + ren_pols.uw_company_cd 
						end
				from exp_pols
				-- join to get prms for expiring policies
				inner join prm exp_pols_prm on exp_pols_prm.policy_sk = exp_pols.policy_sk 
				-- join to get renewals for expiring policies
				left join ren_pols on ren_pols.prior_policy_no = exp_pols.original_policy_no and ren_pols.effective_dt = exp_pols.expiration_dt 
				-- join to get prm for renewals 
				left join prm ren_pols_prm on ren_pols_prm.policy_sk = ren_pols.policy_sk 
				inner join max_tr on exp_pols_prm.policy_sk = max_tr.policy_sk and exp_pols_prm.transaction_seq_no = max_tr.transaction_seq_no
				 
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);	
				if @in_yearmonth is not null
				begin
					set @new_last_source_extract_ts= @last_source_extract_ts
				end 	
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				if @in_yearmonth is not null
				begin
					set @parameter_desc= 'last_source_extract_ts = ' + CAST(@yearmonth AS VARCHAR(200))
				end 
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
