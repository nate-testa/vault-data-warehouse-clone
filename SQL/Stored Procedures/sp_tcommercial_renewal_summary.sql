-- =======================================================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the renewals data for commercial for each month
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author										|	Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 05/09/23		Architha Gudimalla				1. Created this procedure 
-- 05/15/23		Architha Gudimalla				2. Updated after initial run errors
-- 05/15/23		Architha Gudimalla				3. Added filter on tower type
-- 05/26/25		Architha Gudimalla				4. Updated tower join
-- 09/12/25		Architha Gudimalla				5. Updated renewal join logic
-- 09/22/25		Yunus Mohammed				 6. Updated tower_deleted_in where clause and modified temp table names
-- ======================================================================================================================================================================= 

CREATE or ALTER     PROCEDURE [edw_core].[sp_tcommercial_renewal_summary] 
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

				delete from edw_commercial.tcommercial_renewal_summary
				where month_sk = @month_end_dt_sk;
				
				DROP TABLE IF EXISTS edw_temp.tcommercial_ren_summ_quotes;
				
				with q as
				(
					select  q.commercial_quote_sk, q.quote_no, q.effective_dt,  
							q.quote_Status, q.first_quoted_commercial_quote_history_sk,  
							case when q.prior_term_policy_no is null  
								 then q.quote_no 
								 else q.prior_term_policy_no  
							end prior_policy_no  
							, br.primary_address_state_cd
					from edw_commercial.tcommercial_quote q
						 , edw_core.tbroker br 
					where	effective_dt between @begin_dt and @end_dt 
					and br.broker_id = q.broker_id
					--and quote_Status <> 'Issued'
				),
				n as
				(
					select q1.quote_no, nt.note_desc, rank() over (partition by q1.quote_no order by note_created_ts desc, note_sk desc) rnk, note_created_ts
					from edw_core.tnote nt, edw_commercial.tcommercial_quote q1
					where q1.quote_no = nt.policy_no
					and object_type = 'Account' 
					and effective_dt between @begin_dt and @end_dt  
				)
				select    q.* 
						, n.note_desc				
				into edw_temp.tcommercial_ren_summ_quotes 
				from q
				left join n on q.quote_no = n.quote_no and n.rnk = 1;

				DROP TABLE IF EXISTS edw_temp.tcommercial_ren_summ;

				with exp_pols as
				--pols expiration in current month
				(
				 SELECT commercial_policy_sk, policy_no, effective_dt, expiration_dt 
						--non_renewal_in, pending_non_renewal_in
				 FROM	edw_commercial.tcommercial_policy
				 where	expiration_dt between @begin_dt and @end_dt 
				), 
				--pols renewing all in current month
				ren_pols_all as
				(
				 SELECT commercial_policy_sk, policy_no, effective_dt, expiration_dt,  
						 case when prior_term_policy_no is null 
								then policy_no 
								else prior_term_policy_no  
						end prior_policy_no,
						rank() over (partition by case when prior_term_policy_no is null 
								then policy_no 
								else prior_term_policy_no  
						end order by commercial_policy_sk) rnk
				 FROM	edw_commercial.tcommercial_policy
				 where	effective_dt between @begin_dt and @end_dt 
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
					FROM
					(
						SELECT *--, 
								--added replace x, to remove dupes
								--rank() over (partition by replace(prior_policy_no,'x','') order by pol_no_changed_in, commercial_quote_sk) rnk  
						from edw_temp.tcommercial_ren_summ_quotes
					) A
				 	--where rnk = 1

				),
				/*ren_pols as
				--pols renewing in current month
				(
				 SELECT commercial_policy_sk, policy_no, effective_dt, expiration_dt,  
						 case when CHARINDEX('-',prior_policy_no) = 0 then prior_policy_no else left(prior_policy_no, CHARINDEX('-',prior_policy_no) - 1) end prior_policy_no
				 FROM	edw_commercial.tcommercial_policy
				 where	effective_dt between @begin_dt and @end_dt 
				), */
				prm as
				(
				 SELECT tr.commercial_policy_sk, 
				 		--tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk, 
				 		max(tr.transaction_seq_no) transaction_seq_no,
		 				sum(tr.premium_amt - tr.commission_amt) premium_amt,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('New','Renewal') --'Renewal','New Business' 
								then (tr.premium_amt - tr.commission_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as initial_written_prem,
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk and transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk  < 61 
								then (tr.premium_amt - tr.commission_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as effective_date_60_day_prem,
						sum(CASE WHEN tr.transaction_seq_no = max_pol_tr.transaction_seq_no
								  and transaction_effective_dt_sk <> expiration_dt_sk and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation', 'Reinstatement')
								  and  (transaction_effective_dt_sk - effective_dt_sk  > 60 or transaction_dt_sk - effective_dt_sk  > 60)
								then (tr.premium_amt - tr.commission_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as mid_term_cancel_amount, 
						sum(CASE WHEN transaction_effective_dt_sk <> expiration_dt_sk  
								then (tr.premium_amt - tr.commission_amt) * round(((expiration_dt_sk - effective_dt_sk)*1.0/(expiration_dt_sk - transaction_effective_dt_sk)),5) 
								else 0 
								end) as expiring_premium_amount,
						sum(distinct CASE WHEN tr.commercial_policy_transaction_sk = max_pol_tr.commercial_policy_transaction_sk
								  and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'')
								  and  (transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61)
								then 1
								else 0
								end) as cancel_sixty_days_ind, 
						sum( CASE WHEN tr.commercial_policy_transaction_sk = max_pol_tr.commercial_policy_transaction_sk
								  and tt.policy_transaction_type_nm in ('Cancellation') --('Cancellation'') 
								then 1
								else 0
								end) cancel_ind, --expiring_ind, --all_cancelled_policy_num, 
						sum(distinct CASE WHEN tr.transaction_seq_no = max_pol_tr.transaction_seq_no
								  then cast(cpt.aggregate_policy_limit_amt as bigint) 
								else 0 
								end) as expiring_limit,
						sum(distinct CASE WHEN tr.transaction_seq_no = max_pol_tr.transaction_seq_no
								  then cast(cpt.aggregate_attachment_amt as bigint) 
								else 0 
								end) as expiring_attach,  
						--max(pol.non_renewal_in) non_renewal_in,
						--max(pol.pending_non_renewal_in) pending_non_renewal_in,
						max(pol.policy_term) policy_term,
						max(pol.product_cd) product_cd ,
						sum(distinct CASE WHEN tr.transaction_seq_no = max_pol_tr.min_transaction_seq_no
								  then cast(cpt.aggregate_policy_limit_amt as bigint)   
								else 0 
								end) as day_0_limit,
						sum(distinct CASE WHEN tr.transaction_seq_no = max_pol_tr.min_transaction_seq_no
								  then cast(cpt.aggregate_attachment_amt  as bigint)  
								else 0 
								end) as day_0_attach 
				 FROM	edw_commercial.tcommercial_policy_transaction tr
				 inner join edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_sk = tr.policy_transaction_type_sk
				 inner join edw_commercial.tcommercial_policy pol on tr.commercial_policy_sk = pol.commercial_policy_sk
				 --getting max transaction record
				 inner join (
								 SELECT commercial_policy_sk, max(commercial_policy_transaction_sk) over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) commercial_policy_transaction_sk, 
												min(commercial_policy_transaction_sk) over (partition by commercial_policy_sk 
																		order by transaction_seq_no, commercial_policy_transaction_sk) min_commercial_policy_transaction_sk, 
												max(transaction_seq_no) over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) transaction_seq_no, 
												min(transaction_seq_no) over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) min_transaction_seq_no, 
												   rank() over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) rnk
								 FROM	edw_commercial.tcommercial_policy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 --and	transaction_effective_dt_sk <= @end_dt_sk 
							) max_pol_tr on tr.commercial_policy_sk = max_pol_tr.commercial_policy_sk
				 --getting 60 day transaction record
				 left join (
								 SELECT commercial_policy_sk, max(commercial_policy_transaction_sk) over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) commercial_policy_transaction_sk, 
												   rank() over (partition by commercial_policy_sk 
																		order by transaction_seq_no desc, commercial_policy_transaction_sk desc) rnk
								 FROM	edw_commercial.tcommercial_policy_transaction
								 where	effective_dt_sk <= @end_dt_sk
								 --and	transaction_effective_dt_sk <= @end_dt_sk
								 and 	(transaction_effective_dt_sk - effective_dt_sk  < 61 and transaction_dt_sk - effective_dt_sk < 61) 
							) sixty_day_pol_tr on tr.commercial_policy_sk = sixty_day_pol_tr.commercial_policy_sk
				 left join edw_commercial.tcommercial_policy_tower cpt on pol.policy_no = cpt.policy_no and pol.effective_dt = cpt.effective_dt and tr.transaction_seq_no = cpt.transaction_seq_no and cpt.company_nm = 'Vault E&S Insurance Company' and cpt.tower_deleted_in = 'No'
				 where	max_pol_tr.rnk = 1
				 and (sixty_day_pol_tr.rnk = 1 or sixty_day_pol_tr.rnk is null)
				 and effective_dt_sk <= @end_dt_sk
				 --and	transaction_dt_sk <= @end_dt_sk
				 --and	transaction_effective_dt_sk <= @end_dt_sk
				 and transaction_dt_sk - expiration_dt_sk <= 60
				 and   (pol.expiration_dt between @begin_dt and @end_dt or
						pol.effective_dt between @begin_dt and @end_dt)
				 group by tr.commercial_policy_sk--, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk
				),
				max_tr as
				(
					select commercial_policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
					from edw_commercial.tcommercial_policy_transaction 
					where effective_dt_sk <= @end_dt_sk
					--and   transaction_effective_dt_sk <= @end_dt_sk
					--and   transaction_dt_sk <= @end_dt_sk 
					group by commercial_policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
				)
				select 	exp_pols_prm.commercial_policy_sk, 
						max_tr.customer_sk, max_tr.broker_sk, max_tr.product_sk, max_tr.sourcE_system_sk,  
						exp_pols_prm.initial_written_prem, 
						exp_pols_prm.effective_date_60_day_prem,
						exp_pols_prm.mid_term_cancel_amount, 
						case when exp_pols_prm.cancel_ind = 0 then exp_pols_prm.expiring_premium_amount else 0 end 
						expiring_premium_amount, 
						exp_pols_prm.expiring_premium_amount * (case when ren_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end) as expiringpremiumrenewalaccepted,
						null as non_renewal_expiring_premium_amount,
						null as pending_non_renewal_expiring_premium_amount,
						--exp_pols_prm.expiring_premium_amount * (case when exp_pols_prm.non_renewal_in = 'Yes' then -1 else 0 end) as non_renewal_expiring_premium_amount,
						--exp_pols_prm.expiring_premium_amount * (case when exp_pols.pending_non_renewal_in = 'Yes' then -1 else 0 end) as pending_non_renewal_expiring_premium_amount, 
						exp_pols_prm.expiring_limit,  
						exp_pols_prm.expiring_attach, 
						--1 as policy_ct,
						case when exp_pols_prm.cancel_sixty_days_ind <> 0 then 1 else 0 end flatcancel_ind, 
						case when exp_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end non_flatcancel_ind, 
						case when exp_pols_prm.cancel_ind <> 0 and exp_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end midterm_cancel_ind,  
						case when exp_pols_prm.cancel_ind = 0 then 1 else 0 end expiring_ind,   
						0 as nonrenewal_ind, 
						0 as pending_nonrenewal_ind, 
						--case when exp_pols_prm.non_renewal_in = 'Yes' then 1 else 0 end as nonrenewal_ind, 
						--case when exp_pols_prm.pending_non_renewal_in = 'Yes' then 1 else 0 end as pending_nonrenewal_ind, 
						case when ren_pols.commercial_policy_sk is not null then ren_pols.commercial_policy_sk else null end renewal_sk,
						case when ren_pols.commercial_policy_sk is not null then 1 else 0 end renewalcount,
						case when ren_pols_prm.cancel_sixty_days_ind = 0 then 1 else 0 end non_flatcancel_renewal_ind 
						,case when ren_pols.commercial_policy_sk is not null then 0 
						 	 -- when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when ren_quotes.quote_no is not null then 1 
						 	  else 0 
						 end wip_renewal_quote_ct
						,case when ren_pols.commercial_policy_sk is not null then 0 
						 	  --when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when ren_quotes.quote_no is not null 
							   and (ren_quotes.quote_Status in ('Offered','Not Taken by Insured')
							   		or
									ren_quotes.first_quoted_commercial_quote_history_sk is not null
							       ) then 1 
						 	  else 0 
						 end offered_or_not_taken_quote_ct
						,/* commented on olivia's request
						 case when ren_pols.commercial_policy_sk is not null then 0 
						 	  when exp_pols_prm.non_renewal_in = 'Yes' then 0 
						 	  when exp_pols_prm.cancel_ind <> 0 then 0 
						 	  when ren_quotes.quote_no is not null then ren_quotes.commercial_quote_sk 
						 	  else 0 
						 end*/ 
						 ren_quotes.commercial_quote_sk renewal_commercial_quote_sk
						,ren_quotes.note_desc renewal_quote_note_desc
						,ren_quotes.primary_address_state_cd renewal_quote_agency_primary_location_state_cd  
						,case when ren_pols.commercial_policy_sk is not null then ren_pols_prm.day_0_limit else null end renewal_limit_amt,
						 case when ren_pols.commercial_policy_sk is not null then ren_pols_prm.day_0_attach else null end renewal_attachment_amt 
				into edw_temp.tcommercial_ren_summ
				from exp_pols
				-- join to get prms for expiring policies
				inner join prm exp_pols_prm on exp_pols_prm.commercial_policy_sk = exp_pols.commercial_policy_sk 
				-- join to get renewals for expiring policies
				left join ren_pols on replace(ren_pols.prior_policy_no,'x','') = exp_pols.policy_no and ren_pols.effective_dt = exp_pols.expiration_dt 
				-- join to get renewals quotes for expiring policies
				left join ren_quotes on replace(ren_quotes.prior_policy_no,'x','') = exp_pols.policy_no and ren_quotes.effective_dt = exp_pols.expiration_dt 
				-- join to get prm for renewals 
				left join prm ren_pols_prm on ren_pols_prm.commercial_policy_sk = ren_pols.commercial_policy_sk 
				inner join max_tr on exp_pols_prm.commercial_policy_sk = max_tr.commercial_policy_sk and exp_pols_prm.transaction_seq_no = max_tr.transaction_seq_no  
				 
				
				INSERT INTO --select * from  
				edw_commercial.tcommercial_renewal_summary
					( 
						month_sk, commercial_policy_sk, customer_sk, broker_sk, product_sk, source_system_sk,  
						expiring_mid_term_cancelled_premium_amt,
						expiring_written_premium_amt, 
						expiring_non_renewal_written_premium_amt,
						expiring_pending_non_renewal_written_premium_amt ,  
						expiring_limit_amt,  
						expiring_attachment_amt ,
						flat_cancelled_ct,
						non_flat_cancelled_ct,
						mid_term_cancelled_ct,
						expiring_ct,
						non_renewal_ct,
						pending_non_renewal_ct,
						renewal_commercial_policy_sk,
						renewal_ct,
						renewal_non_flat_cancelled_ct,  
						update_ts,
						etl_audit_sk 
						,wip_renewal_quote_ct
						,offered_or_not_taken_quote_ct
						,renewal_commercial_quote_sk  
						,renewal_limit_amt
						,renewal_attachment_amt 
						,expiring_mid_term_endorsement_premium_amt  
						,renewal_quote_written_premium_amt
						,renewal_quote_limit_amt  
						,renewal_quote_attachment_amt 
					)
				select distinct @month_end_dt_sk, 
						a.commercial_policy_sk,   
						a.customer_sk, 
						a.broker_sk, 
						a.product_sk, 
						a.sourcE_system_sk,   
						a.mid_term_cancel_amount, 
						a.expiring_premium_amount,  
						a.non_renewal_expiring_premium_amount,
						a.pending_non_renewal_expiring_premium_amount,  
						a.expiring_limit,  
						a.expiring_attach, 
						a.flatcancel_ind, 
						a.non_flatcancel_ind, 
						a.midterm_cancel_ind,  
						a.expiring_ind,   
						a.nonrenewal_ind,
						a.pending_nonrenewal_ind, 
						a.renewal_sk,
						a.renewalcount,
						a.non_flatcancel_renewal_ind, 
						getdate() 
						,@etl_audit_sk  
						,a.wip_renewal_quote_ct
						,a.offered_or_not_taken_quote_ct
						,a.renewal_commercial_quote_sk 
						,a.renewal_limit_amt
						,a.renewal_attachment_amt   
						,(a.effective_date_60_day_prem - a.initial_written_prem - a.mid_term_cancel_amount) AS expiring_mid_term_endorsement_premium_amt  
						,(qh.premium_amt-qh.commission_amt)as renewal_quote_written_premium_amt
						,qpt.aggregate_policy_limit_amt 	renewal_quote_limit_amt 
						,qpt.aggregate_attachment_amt 		renewal_quote_attachment_amt  
				from edw_temp.tcommercial_ren_summ a
				left join ( select distinct cancellation_reason_desc, commercial_policy_sk, effective_dt 
							FROM edw_commercial.tcommercial_policy_history ph
							Where transaction_type  = 'Cancellation'
							and latest_transaction_in ='Y'
						  ) b on a.commercial_policy_sk = b.commercial_policy_sk
				left join edw_commercial.tcommercial_quote_history qh on qh.commercial_quote_sk = a.renewal_commercial_quote_sk and qh.latest_transaction_in = 'Y'
				left join edw_commercial.tcommercial_quote_tower qpt on qpt.quote_no = qh.quote_no and qpt.effective_dt = qh.effective_dt  and qpt.transaction_seq_no = qh.transaction_seq_no  and qpt.company_nm = 'Vault E&S Insurance Company'  
				left join edw_core.tproduct pr on a.product_sk = pr.product_sk;

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
				 
				DROP TABLE IF EXISTS edw_temp.tcommercial_ren_summ;
				DROP TABLE IF EXISTS edw_temp.tcommercial_ren_summ_quotes;
				 
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
