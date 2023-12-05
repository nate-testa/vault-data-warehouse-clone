SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the broker data for each month
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/20/23		Architha Gudimalla				1. Created this procedure 
-- 10/13/23		Architha Gudimalla				2. Added risk state
-- 10/20/23		Architha Gudimalla				3. Removed source_system_sk
-- 10/31/23		Architha Gudimalla				4. Added addtional columns
-- 11/21/23		Architha Gudimalla				5. Added quotes logic
-- 11/27/23		Architha Gudimalla				6. Added temp table
-- ================================================================================================= 

create OR ALTER PROCEDURE [edw_core].[sp_tbroker_summary] 
@in_end_dt date = null
AS 
BEGIN

    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements. 
	SET ANSI_WARNINGS OFF
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
	
		DECLARE @prior_year_month_end_dt DATETIME
		DECLARE @prior_year_month_end_dt_sk INT
		DECLARE @prior_year_three_month_end_dt_sk INT
		DECLARE @year_begin_dt_sk INT 
		DECLARE @year_begin_dt DATETIME 
		DECLARE @prior_year_begin_dt_sk INT 
		DECLARE @prior_year_begin_dt DATETIME 
		DECLARE @month_end_dt_sk INT  
		DECLARE @end_dt DATETIME  
		DECLARE @begin_end_dt DATETIME 
		DECLARE @year INT 
		DECLARE @prior_year INT 
		DECLARE @yearmonth INT  
	
		DECLARE @parameter_desc VARCHAR(255) 
		
		
		DECLARE c2_rec CURSOR
		FOR  
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt = @in_end_dt 
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt >  case when @in_end_dt is not null then @in_end_dt else @last_source_extract_ts end
		  and   actual_dt <= case when @in_end_dt is not null then @in_end_dt else getdate() end
		group by yearmonth
		order by 1;   
	
				

		print @last_source_extract_ts

		
		open c2_rec; 
		FETCH NEXT FROM c2_rec INTO @yearmonth, @year; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				select 	@month_end_dt_sk = max(datE_sk),  
						@end_dt = max(actual_dt),
						@begin_end_dt = min(actual_dt),
						@year = max(calendar_year)
				from edw_core.tdate
				where yearmonth = @yearmonth;

				select 	@prior_year_month_end_dt_sk = date_sk ,
						@prior_year_month_end_dt = actual_dt ,
						@prior_year = calendar_year
				from edw_core.tdate
				where actual_Dt = dateadd(year,-1,@end_dt);

				select 	@prior_year_three_month_end_dt_sk = date_sk 
				from edw_core.tdate
				where actual_Dt = dateadd(year,-3,@end_dt);

				select 	@year_begin_dt_sk = min(date_sk) , @year_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where yearmonth =  cast(cast(@year as varchar) + '01' as int); 

				select 	@prior_year_begin_dt_sk = min(date_sk) , @prior_year_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where yearmonth =  cast(cast(@prior_year as varchar) + '01' as int); 
				
				 IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
				BEGIN  
						select 	@end_dt = max(actual_dt) 
						from edw_core.tdate
						where yearmonth = @yearmonth and actual_dt < cast(getdate() as date); 
				END  

				DROP TABLE IF EXISTS edw_temp.tbroker_summ_quotes;
				select br.broker_sk, --cust.customer_sk, 
						--pr.product_sk, --st.state_sk, 
						sum(case when q.first_offered_quote_ts between @prior_year_begin_dt and @prior_year_month_end_dt then 1 else 0 end) prior_ytd_quote_ct, 
						sum(case when q.first_offered_quote_ts between @year_begin_dt       and @end_dt then 1 else 0 end) ytd_quote_ct, 
						max(q.first_offered_quote_ts) max_quoted_dt, 
						max(q.bind_dt) max_bind_dt
				into edw_temp.tbroker_summ_quotes
				from edw_core.tquote q, edw_core.tcustomer cust, edw_core.tbroker br, edw_core.tproduct pr, edw_core.tstate st
				where q.customer_id = cust.customer_id
				and q.broker_id = br.broker_id
				and q.product_cd = pr.product_cd 
				and q.risk_state_cd = st.state_cd
				and (q.first_offered_quote_ts is not null or q.bind_dt is not null)
				--and quote_create_ts <= @end_dt
				group by br.broker_sk--, cust.customer_sk
						--, pr.product_sk-- ,st.state_sk 
				
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols;
				SELECT summ.broker_sk, --policy_sk, 
							--summ.customer_sk,
							--summ.product_sk,  
							--st.state_sk, 
							--
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_ct else 0 end) inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_net_premium_amt else 0 end) inforce_net_premium_amt,
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk then summ.inforce_ct else 0 end) prior_inforce_ct,  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk then summ.inforce_net_premium_amt else 0 end) prior_inforce_net_premium_amt,
							--
							sum(case when summ.month_sk between @prior_year_begin_dt_sk and @prior_year_month_end_dt_sk then summ.mtd_net_premium_amt else 0 end) prior_ytd_net_premium_amt,   
							sum(case when summ.month_sk between @year_begin_dt_sk and @month_end_dt_sk then summ.mtd_net_premium_amt else 0 end) ytd_net_premium_amt,   
							--
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 3 then summ.inforce_ct else 0 end) au_inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 3 then summ.inforce_net_premium_amt else 0 end) au_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 5 then summ.inforce_ct else 0 end) co_inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 5 then summ.inforce_net_premium_amt else 0 end) co_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 1 then summ.inforce_ct else 0 end) ho_inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 1 then summ.inforce_net_premium_amt else 0 end) ho_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 2 then summ.inforce_ct else 0 end) lux_inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 2 then summ.inforce_net_premium_amt else 0 end) lux_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 4 then summ.inforce_ct else 0 end) pel_inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 4 then summ.inforce_net_premium_amt else 0 end) pel_inforce_net_premium_amt,
							
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.product_sk = 3 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.product_sk = 5 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.product_sk = 1 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.product_sk = 2 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.product_sk = 4 and summ.inforce_ct = 1 then 1 else 0 end) prior_line_ct,
							
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 3 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 5 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 1 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 2 and summ.inforce_ct = 1 then 1 else 0 end) +  
							sum(case when summ.month_sk = @month_end_dt_sk and summ.product_sk = 4 and summ.inforce_ct = 1 then 1 else 0 end) line_ct,   
							--
							count(distinct case when summ.month_sk = @month_end_dt_sk and summ.inforce_ct = 1 then summ.customer_sk end) customer_ct,  
							count(distinct case when summ.month_sk = @prior_year_month_end_dt_sk and summ.inforce_ct = 1 then summ.customer_sk end) prior_customer_ct,  
							--
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_ct else 0 end) ves_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_net_premium_amt else 0 end) ves_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_ct else 0 end) vre_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_net_premium_amt else 0 end) vre_inforce_net_premium_amt,
							--
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @year_begin_dt then pol.policy_sk end) ytd_new_business_ct ,
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @year_begin_dt then summ.mtd_net_premium_amt else 0 end) ytd_new_business_net_premium_amt ,   
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @prior_year_begin_dt then pol.policy_sk end) prior_ytd_new_business_ct ,
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @prior_year_begin_dt then summ.mtd_net_premium_amt else 0 end) prior_ytd_new_business_net_premium_amt ,   
							--
							sum(case when 						  summ.month_sk >= @prior_year_month_end_dt_sk 		then summ.earned_net_premium_amt else 0 end) one_year_earned_net_premium_amt,
							sum(case when 						  summ.month_sk >= @prior_year_three_month_end_dt_sk 	then summ.earned_net_premium_amt else 0 end) three_year_earned_net_premium_amt, 
							sum(case when 						  summ.month_sk >= @prior_year_month_end_dt_sk 		then summ.earned_exposure else 0 end) one_year_earned_exposure,
							sum(case when 						  summ.month_sk >= @prior_year_three_month_end_dt_sk 	then summ.earned_exposure else 0 end) three_year_earned_exposure,
					 		sum(case when summ.product_sk = 1 and summ.month_sk >= @prior_year_month_end_dt_sk 		then summ.earned_net_premium_amt else 0 end) ho_one_year_earned_net_premium_amt,
							sum(case when summ.product_sk = 1 and summ.month_sk >= @prior_year_three_month_end_dt_sk 	then summ.earned_net_premium_amt else 0 end) ho_three_year_earned_net_premium_amt, 
							sum(case when summ.product_sk = 1 and summ.month_sk >= @prior_year_month_end_dt_sk 		then summ.earned_exposure else 0 end) ho_one_year_earned_exposure,
							sum(case when summ.product_sk = 1 and summ.month_sk >= @prior_year_three_month_end_dt_sk 	then summ.earned_exposure else 0 end) ho_three_year_earned_exposure
					 
				 into edw_temp.tbroker_summ_pols
				 FROM	edw_core.tpolicy_summary summ, edw_core.tpolicy pol, edw_core.tstate st, 
				 		edw_core.tpolicy_history ph,
				 		(select policy_sk, min(transaction_seq_no) transaction_seq_no
							from edw_core.tpolicy_history
							group by policy_sk ) min_ph
					 where	summ.month_sk between  @prior_year_three_month_end_dt_sk and  @month_end_dt_sk
					 and 	summ.policy_sk = pol.policy_sk
					 and 	pol.risk_state_cd = st.state_cd
					 and 	summ.policy_sk = ph.policy_sk 
					 and 	ph.policy_sk = min_ph.policy_sk and ph.transaction_seq_no = min_ph.transaction_seq_no
					 group by summ.broker_sk--, --policy_sk, 
							--summ.customer_sk,
							--summ.product_sk
							--,st.state_sk 
				
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_claims;
				select  cs.broker_sk, --policy_sk, 
							--cs.customer_sk,
							cs.product_sk,  
							--st.state_sk, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 then 1 else 0 end) one_year_claim_ct, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 then [itd_total_incurred_amt] else 0 end) one_year_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 and c.catastrophe_sk is not null then 1 else 0 end) one_year_non_cat_claim_ct, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 and c.catastrophe_sk is not null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) one_year_non_cat_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 365 and c.catastrophe_sk is not null
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_non_cat_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 then 1 else 0 end) three_year_claim_ct, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 then [itd_total_incurred_amt] else 0 end) three_year_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 and c.catastrophe_sk is not null then 1 else 0 end) three_year_non_cat_claim_ct, 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 and c.catastrophe_sk is not null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) three_year_non_cat_loss_incurred_amt , 
							sum(case when datediff(d,c.loss_dt,@end_dt) between 0 and 1095 and c.catastrophe_sk is not null
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_non_cat_loss_incurred_capped_amt
					into edw_temp.tbroker_summ_claims
					from edw_core.tclaim_feature_summary cs, edw_core.tclaim c,  edw_core.tpolicy pol , edw_core.tstate st
					where	month_sk = @month_end_dt_sk
					and 	cs.claim_sk  = c.claim_sk
					and 	cs.policy_sk = pol.policy_sk
					 and pol.risk_state_cd = st.state_cd
					group by cs.broker_sk, --policy_sk, 
							--cs.customer_sk, 
							cs.product_sk
							--,st.state_sk 
				
				DROP TABLE IF EXISTS edw_temp.tbroker_summary_temp;
				with pol_summ as
				(
					select * 
					from  edw_temp.tbroker_summ_pols
					 
				), 
				clm_summ as
				( 
					select broker_sk,  
							sum(one_year_claim_ct) one_year_claim_ct, 
							sum(one_year_loss_incurred_amt) one_year_loss_incurred_amt, 
							sum(one_year_loss_incurred_capped_amt) one_year_loss_incurred_capped_amt, 
							sum(one_year_non_cat_claim_ct) one_year_non_cat_claim_ct,  
							sum(one_year_non_cat_loss_incurred_amt) one_year_non_cat_loss_incurred_amt, 
							sum(one_year_non_cat_loss_incurred_capped_amt) one_year_non_cat_loss_incurred_capped_amt,
							sum(three_year_claim_ct) three_year_claim_ct,
							sum(three_year_loss_incurred_amt) three_year_loss_incurred_amt, 
							sum(three_year_loss_incurred_capped_amt) three_year_loss_incurred_capped_amt, 
							sum(three_year_non_cat_claim_ct) three_year_non_cat_claim_ct,  
							sum(three_year_non_cat_loss_incurred_amt) three_year_non_cat_loss_incurred_amt ,
							sum(three_year_non_cat_loss_incurred_capped_amt) three_year_non_cat_loss_incurred_capped_amt,  
							sum(case when product_sk = 3 then one_year_claim_ct else 0 end) ho_one_year_claim_ct,
							sum(case when product_sk = 3 then three_year_claim_ct else 0 end) ho_three_year_claim_ct,
							sum(case when product_sk = 3 then one_year_non_cat_claim_ct else 0 end) ho_one_year_non_cat_claim_ct,
							sum(case when product_sk = 3 then three_year_non_cat_claim_ct else 0 end) ho_three_year_non_cat_claim_ct
					from edw_temp.tbroker_summ_claims 
					group by broker_sk
				) , 
				quotes as
				(   
					select *
					from edw_temp.tbroker_summ_quotes
				) 
				select 	@month_end_dt_sk month_sk, 
						--COALESCE(ps.customer_sk, cs.customer_sk, q.customer_sk) customer_sk,
						COALESCE(ps.broker_sk, cs.broker_sk, q.broker_sk) broker_sk,
						--COALESCE(ps.product_sk, cs.product_sk, q.product_sk) product_sk
						--,COALESCE(ps.state_sk, cs.state_sk, q.state_sk) state_sk, 
						sum(isnull(q.prior_ytd_quote_ct,0)) prior_ytd_quote_ct,
						sum(isnull(q.ytd_quote_ct,0)) ytd_quote_ct,
						--count(distinct isnull(ps.customer_sk, cs.customer_sk)) customer_ct,
						-- avg lines per account - can be calculated
						max(cast(case when q.max_quoted_dt is not null then q.max_quoted_dt end as date)) last_quote_dt,
						max(case when q.max_bind_dt is not null then q.max_bind_dt end) last_bound_dt,
						--
						sum(isnull(ps.prior_customer_ct,0)) prior_customer_ct, 
						sum(isnull(ps.customer_ct,0)) customer_ct, 
						sum(isnull(prior_line_ct,0)) prior_total_line_ct,
						sum(isnull(line_ct,0)) total_line_ct,
						--
						sum(isnull(ps.prior_ytd_new_business_ct,0)) prior_ytd_new_business_ct, 
						sum(isnull(ps.prior_ytd_new_business_net_premium_amt,0)) prior_ytd_new_business_net_premium_amt, 
						sum(isnull(ps.ytd_new_business_ct,0)) ytd_new_business_ct, 
						sum(isnull(ps.ytd_new_business_net_premium_amt,0)) ytd_new_business_net_premium_amt, 
						--
						sum(isnull(ps.prior_ytd_net_premium_amt,0)) prior_ytd_net_premium_amt, 
						sum(isnull(ps.ytd_net_premium_amt,0)) ytd_net_premium_amt, 
						--
						sum(isnull(ps.prior_inforce_ct,0)) prior_inforce_ct, 
						sum(isnull(ps.prior_inforce_net_premium_amt,0)) prior_inforce_net_premium_amt,
						sum(isnull(ps.inforce_ct,0)) inforce_ct, 
						sum(isnull(ps.inforce_net_premium_amt,0)) inforce_net_premium_amt,
						--
						/*
						sum(isnull(case when ps.product_sk = 3 then ps.inforce_ct else 0 end,0)) au_inforce_ct, 
						sum(isnull(case when ps.product_sk = 3 then ps.inforce_net_premium_amt else 0 end,0)) au_inforce_net_premium_amt,
						sum(isnull(case when ps.product_sk = 5 then ps.inforce_ct else 0 end,0)) co_inforce_ct, 
						sum(isnull(case when ps.product_sk = 5 then ps.inforce_net_premium_amt else 0 end,0)) co_inforce_net_premium_amt,
						sum(isnull(case when ps.product_sk = 1 then ps.inforce_ct else 0 end,0)) ho_inforce_ct, 
						sum(isnull(case when ps.product_sk = 1 then ps.inforce_net_premium_amt else 0 end,0)) ho_inforce_net_premium_amt,
						sum(isnull(case when ps.product_sk = 2 then ps.inforce_ct else 0 end,0)) lux_inforce_ct, 
						sum(isnull(case when ps.product_sk = 2 then ps.inforce_net_premium_amt else 0 end,0)) lux_inforce_net_premium_amt,
						sum(isnull(case when ps.product_sk = 4 then ps.inforce_ct else 0 end,0)) pel_inforce_ct, 
						sum(isnull(case when ps.product_sk = 4 then ps.inforce_net_premium_amt else 0 end,0)) pel_inforce_net_premium_amt, 
						*/
						
						sum(isnull(ps.au_inforce_ct,0)) au_inforce_ct, 
						sum(isnull(ps.au_inforce_net_premium_amt,0)) au_inforce_net_premium_amt,
						sum(isnull(ps.co_inforce_ct,0)) co_inforce_ct, 
						sum(isnull(ps.co_inforce_net_premium_amt,0)) co_inforce_net_premium_amt,
						sum(isnull(ps.ho_inforce_ct,0)) ho_inforce_ct, 
						sum(isnull(ps.ho_inforce_net_premium_amt,0)) ho_inforce_net_premium_amt,
						sum(isnull(ps.lux_inforce_ct,0)) lux_inforce_ct, 
						sum(isnull(ps.lux_inforce_net_premium_amt,0)) lux_inforce_net_premium_amt,
						sum(isnull(ps.pel_inforce_ct,0)) pel_inforce_ct, 
						sum(isnull(ps.pel_inforce_net_premium_amt,0)) pel_inforce_net_premium_amt, 
						
						--
						sum(isnull(ps.ves_inforce_ct,0)) ves_inforce_ct,  
						sum(isnull(ps.ves_inforce_net_premium_amt,0)) ves_inforce_net_premium_amt,
						sum(isnull(ps.vre_inforce_ct,0)) vre_inforce_ct,  
						sum(isnull(ps.vre_inforce_net_premium_amt,0)) vre_inforce_net_premium_amt,
						--
						sum(isnull(ps.one_year_earned_net_premium_amt,0)) one_year_earned_net_premium_amt, 
						sum(isnull(ps.three_year_earned_net_premium_amt,0)) three_year_earned_net_premium_amt, 
						sum(isnull(ps.one_year_earned_exposure,0)) one_year_earned_exposure, 
						sum(isnull(ps.three_year_earned_exposure,0)) three_year_earned_exposure,  
						sum(isnull(ps.ho_one_year_earned_net_premium_amt,0)) ho_one_year_earned_net_premium_amt, 
						sum(isnull(ps.ho_three_year_earned_net_premium_amt,0)) ho_three_year_earned_net_premium_amt, 
						sum(isnull(ps.ho_one_year_earned_exposure,0)) ho_one_year_earned_exposure, 
						sum(isnull(ps.ho_three_year_earned_exposure,0)) ho_three_year_earned_exposure,   
						--
						sum(isnull(cs.one_year_claim_ct,0)) one_year_claim_ct, 
						sum(isnull(cs.one_year_loss_incurred_amt,0)) one_year_loss_incurred_amt,
						sum(isnull(cs.one_year_loss_incurred_capped_amt,0)) one_year_loss_incurred_capped_amt,
						sum(isnull(cs.one_year_non_cat_claim_ct,0)) one_year_non_cat_claim_ct, 
						sum(isnull(cs.one_year_non_cat_loss_incurred_amt,0)) one_year_non_cat_loss_incurred_amt,
						sum(isnull(cs.one_year_non_cat_loss_incurred_capped_amt,0)) one_year_non_cat_loss_incurred_capped_amt,
						sum(isnull(cs.ho_one_year_claim_ct,0)) ho_one_year_claim_ct, 
						sum(isnull(cs.ho_one_year_non_cat_claim_ct,0)) ho_one_year_non_cat_claim_ct, 
						--
						sum(isnull(cs.three_year_claim_ct,0)) three_year_claim_ct, 
						sum(isnull(cs.three_year_loss_incurred_amt,0)) three_year_loss_incurred_amt,
						sum(isnull(cs.three_year_loss_incurred_capped_amt,0)) three_year_loss_incurred_capped_amt,
						sum(isnull(cs.three_year_non_cat_claim_ct,0)) three_year_non_cat_claim_ct, 
						sum(isnull(cs.three_year_non_cat_loss_incurred_amt,0)) three_year_non_cat_loss_incurred_amt, 
						sum(isnull(cs.three_year_non_cat_loss_incurred_capped_amt,0)) three_year_non_cat_loss_incurred_capped_amt,
						sum(isnull(cs.ho_three_year_claim_ct,0)) ho_three_year_claim_ct, 
						sum(isnull(cs.ho_three_year_non_cat_claim_ct,0)) ho_three_year_non_cat_claim_ct, 
						-- 
						getdate() update_ts, @etl_audit_sk etl_audit_sk
				into edw_temp.tbroker_summary_temp
				from pol_summ ps
				full join clm_summ cs  
						  on ps.broker_sk = cs.broker_sk  --and ps.product_sk = cs.product_sk  and ps.customer_sk = cs.customer_sk-- and ps.state_sk = cs.state_sk 
				full join quotes q  
						  on ps.broker_sk = q.broker_sk  --and ps.product_sk = q.product_sk  and ps.customer_sk = q.customer_sk-- and ps.state_sk = q.state_sk   
				--where  isnull(xpsr_rein.ee,0) <> 0
				group by --COALESCE(ps.customer_sk, cs.customer_sk, q.customer_sk),
						COALESCE(ps.broker_sk, cs.broker_sk, q.broker_sk)--,
						--COALESCE(ps.product_sk, cs.product_sk, q.product_sk)
						--,COALESCE(ps.state_sk, cs.state_sk, q.state_sk)
				; 
				delete from edw_core.tbroker_summary
				where month_sk = @month_end_dt_sk; 

				INSERT INTO edw_core.tbroker_summary
					( 
						month_sk,
						broker_sk, 
						prior_ytd_quote_ct,
						ytd_quote_ct,
						prior_customer_ct,
						customer_ct,
						prior_total_line_ct,
						total_line_ct,
						-- avg lines per account - can be calculated
						last_quote_dt,
						last_bound_dt,
						prior_ytd_new_business_ct, 
						prior_ytd_new_business_net_premium_amt, 
						ytd_new_business_ct, 
						ytd_new_business_net_premium_amt, 
						prior_ytd_net_premium_amt, 
						ytd_net_premium_amt,
						prior_inforce_ct, 
						prior_inforce_net_premium_amt,
						inforce_ct, 
						inforce_net_premium_amt,
						AU_inforce_ct,
						AU_inforce_net_premium_amt, 
						CO_inforce_ct,
						CO_inforce_net_premium_amt, 
						HO_inforce_ct,
						HO_inforce_net_premium_amt, 
						LUX_inforce_ct,
						LUX_inforce_net_premium_amt, 
						PEL_inforce_ct,
						PEL_inforce_net_premium_amt,
						admitted_inforce_ct,
						admitted_inforce_net_premium_amt,
						non_admitted_inforce_ct,  
						non_admitted_inforce_net_premium_amt,
						one_year_earned_net_premium_amt, 
						three_year_earned_net_premium_amt, 
						one_year_earned_exposure, 
						three_year_earned_exposure, 
						one_year_claim_ct, 
						one_year_loss_incurred_amt,
						one_year_loss_incurred_capped_amt,
						one_year_non_cat_claim_ct, 
						one_year_non_cat_loss_incurred_amt,
						one_year_non_cat_loss_incurred_capped_amt,
						ho_one_year_claim_ct,
    					ho_one_year_non_cat_claim_ct,
    					ho_one_year_earned_net_premium_amt,
    					ho_one_year_earned_exposure,
						three_year_claim_ct, 
						three_year_loss_incurred_amt,
						three_year_loss_incurred_capped_amt,
						three_year_non_cat_claim_ct, 
						three_year_non_cat_loss_incurred_amt, 
						three_year_non_cat_loss_incurred_capped_amt,
						ho_three_year_claim_ct,
    					ho_three_year_non_cat_claim_ct,
    					ho_three_year_earned_net_premium_amt,
    					ho_three_year_earned_exposure,
						--source_system_sk,
						update_ts,
						etl_audit_sk
					)
				select month_sk, broker_sk,  
						sum(prior_ytd_quote_ct), 
						sum(ytd_quote_ct), 
						sum(prior_customer_ct) prior_customer_ct, 
						sum(customer_ct) customer_ct, 
						sum(prior_total_line_ct),
						sum(total_line_ct),
						max(last_quote_dt), max(last_bound_dt), 
						sum(prior_ytd_new_business_ct), sum(prior_ytd_new_business_net_premium_amt), 
						sum(ytd_new_business_ct), sum(ytd_new_business_net_premium_amt),  
						sum(prior_ytd_net_premium_amt), sum(ytd_net_premium_amt),
						sum(prior_inforce_ct), sum(prior_inforce_net_premium_amt),  
						sum(inforce_ct), sum(inforce_net_premium_amt),  
						sum(au_inforce_ct), sum(au_inforce_net_premium_amt),  
						sum(co_inforce_ct), sum(co_inforce_net_premium_amt),  
						sum(ho_inforce_ct), sum(ho_inforce_net_premium_amt),  
						sum(lux_inforce_ct), sum(lux_inforce_net_premium_amt),  
						sum(pel_inforce_ct), sum(pel_inforce_net_premium_amt),  
						sum(vre_inforce_ct), sum(vre_inforce_net_premium_amt), 
						sum(ves_inforce_ct), sum(ves_inforce_net_premium_amt), 
						sum(one_year_earned_net_premium_amt), 
						sum(three_year_earned_net_premium_amt), 
						sum(one_year_earned_exposure), 
						sum(three_year_earned_exposure), 
						sum(one_year_claim_ct),
						 sum(one_year_loss_incurred_amt), 
						 sum(one_year_loss_incurred_capped_amt), 
						sum(one_year_non_cat_claim_ct), 
						sum(one_year_non_cat_loss_incurred_amt), 
						sum(one_year_non_cat_loss_incurred_capped_amt),
						sum(ho_one_year_claim_ct), sum(ho_one_year_non_cat_claim_ct), 
						sum(ho_one_year_earned_net_premium_amt),  
						sum(ho_one_year_earned_exposure), 
						sum(three_year_claim_ct), sum(three_year_loss_incurred_amt), sum(three_year_loss_incurred_capped_amt),
						sum(three_year_non_cat_claim_ct), sum(three_year_non_cat_loss_incurred_amt), sum( three_year_non_cat_loss_incurred_capped_amt),
						sum(ho_three_year_claim_ct), sum(ho_three_year_non_cat_claim_ct), 
						sum(ho_three_year_earned_net_premium_amt),  
						sum(ho_three_year_earned_exposure), 
						--max(source_system_sk),
						max(update_ts), max(etl_audit_sk)
				from edw_temp.tbroker_summary_temp summ
				group by month_sk, broker_sk;
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

				DROP TABLE IF EXISTS edw_temp.tbroker_summary_temp; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_quotes; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_claims;
				 
				FETCH NEXT FROM c2_rec INTO @yearmonth, @year;
			END; 
		CLOSE c2_rec;
		DEALLOCATE c2_rec;   

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
