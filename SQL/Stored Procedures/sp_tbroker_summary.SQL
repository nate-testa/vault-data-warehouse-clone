/****** Object:  StoredProcedure [edw_core].[sp_tbroker_summary]    Script Date: 1/10/2024 3:09:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =====================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the broker data for each month
------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------------------
-- 06/20/23		Architha Gudimalla				1. Created this procedure 
-- 10/13/23		Architha Gudimalla				2. Added risk state
-- 10/20/23		Architha Gudimalla				3. Removed source_system_sk
-- 10/31/23		Architha Gudimalla				4. Added addtional columns
-- 11/21/23		Architha Gudimalla				5. Added quotes logic
-- 11/27/23		Architha Gudimalla				6. Added temp table
-- 12/11/23		Architha Gudimalla				7. Added quote prm cols
-- 12/13/23		Architha Gudimalla				8. Added retention and submissions
-- 12/13/23		Architha Gudimalla				9. Changed grain of broker summary
-- 01/05/24		Architha Gudimalla				10. Corrected prior year gross new prm
-- 01/06/24		Architha Gudimalla				11. Updated to use tclaim summary instead of feature summary 
-- 01/06/24		Architha Gudimalla				12. Corrected date filter for gross net prm
-- 01/06/24		Architha Gudimalla				13. Corrected date filter for current month mtd new prm
-- 01/09/24		Architha Gudimalla				14. Corrected non cat claim filter
-- 01/10/24		Architha Gudimalla				15. Used cast as date for quote dates to remove timestamp
-- 01/11/24		Architha Gudimalla				16. Added one and three year written prms
-- ===================================================================================================================================== 

CREATE OR ALTER     PROCEDURE [edw_core].[sp_tbroker_summary] 
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
	
		DECLARE @prior_year_three_month_end_dt_sk INT
		DECLARE @prior_year_begin_dt_sk INT 
		DECLARE @year_begin_dt_sk INT 
		DECLARE @prior_year_begin_dt DATETIME 
		DECLARE @year_begin_dt DATETIME 
		DECLARE @prior_quarter_begin_dt_sk INT  
		DECLARE @quarter_begin_dt_sk INT  
		DECLARE @prior_year_month_begin_dt_sk INT  
		DECLARE @month_begin_dt_sk INT  
		DECLARE @prior_year_month_end_dt_sk INT 
		DECLARE @month_end_dt DATETIME 
		DECLARE @month_end_dt_sk INT  
		DECLARE @prior_quarter_begin_dt DATETIME 
		DECLARE @quarter_begin_dt DATETIME 
		DECLARE @prior_year_month_begin_dt DATETIME 
		DECLARE @month_begin_dt DATETIME 
		DECLARE @prior_year_three_month_end_dt DATETIME 
		DECLARE @prior_year_month_end_dt DATETIME 
		DECLARE @end_dt DATETIME  
		DECLARE @end_dt_sk INT  
		DECLARE @prior_three_year INT 
		DECLARE @prior_year INT 
		DECLARE @year INT 
		DECLARE @yearmonth INT  
		DECLARE @prior_quarter VARCHAR(255) 
		DECLARE @quarter VARCHAR(255)  
	
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
		
		open c2_rec; 
		FETCH NEXT FROM c2_rec INTO @yearmonth, @year; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				set @current_date =GETDATE()   
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				select 	@month_begin_dt_sk = min(datE_sk),
						@end_dt_sk = max(datE_sk),  
						@month_end_dt_sk = max(datE_sk),  
						@month_end_dt = max(actual_dt), 
						@end_dt = max(actual_dt),
						@month_begin_dt = min(actual_dt),
						@year = max(calendar_year),
						@quarter = max(year_quarter)
				from edw_core.tdate
				where yearmonth = @yearmonth;

				select 	@prior_year_month_end_dt_sk = date_sk ,
						@prior_year_month_end_dt = actual_dt ,
						@prior_year = calendar_year,
						@prior_quarter = year_quarter
				from edw_core.tdate
				where actual_Dt = dateadd(year,-1,@end_dt);

				--need to do this because tdate only has data from 2017
				if @prior_year_month_end_dt_sk is null 
				begin
					set @prior_year_month_end_dt_sk = 0
					set @prior_year_month_end_dt = dateadd(year,-1,@end_dt)
					set	@prior_year = datepart(yyyy,@prior_year_month_end_dt)
					set	@prior_quarter = cast(@prior_year as char) + right(@quarter,2)
				end;

				--if prior year is a leap year, add one day to month end data to change it to 2/29 instead of 2/28
				if @prior_year%4 = 0 and datepart(mm,@prior_year_month_end_dt) = 2
				begin
					set @prior_year_month_end_dt_sk = @prior_year_month_end_dt_sk + 1
					set @prior_year_month_end_dt = dateadd(dd,+1,@prior_year_month_end_dt)
				end

				select 	@quarter_begin_dt_sk = min(datE_sk), 
						@quarter_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where year_quarter = @quarter; 

				select 	@prior_quarter_begin_dt_sk = min(datE_sk), 
						@prior_quarter_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where year_quarter = @prior_quarter;

				--need to do this because tdate only has data from 2017
				if @prior_quarter_begin_dt_sk is null 
				begin
					set @prior_quarter_begin_dt_sk = 0
					set @prior_quarter_begin_dt = dateadd(year,-1,@quarter_begin_dt)
				end;

				select 	@prior_year_month_begin_dt_sk = date_sk ,
						@prior_year_month_begin_dt = actual_dt
				from edw_core.tdate
				where actual_Dt = dateadd(year,-1,@month_begin_dt);

				--need to do this because tdate only has data from 2017
				if @prior_year_month_begin_dt_sk is null 
				begin
					set @prior_year_month_begin_dt_sk = 0
					set @prior_year_month_begin_dt = dateadd(year,-1,@month_begin_dt)
				end;

				select 	@prior_year_begin_dt_sk = min(date_sk) , 
						@prior_year_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where yearmonth =  cast(cast(@prior_year as varchar) + '01' as int); 

				select 	@year_begin_dt_sk = min(date_sk) , 
						@year_begin_dt = min(actual_dt) 
				from edw_core.tdate
				where yearmonth =  cast(cast(@year as varchar) + '01' as int); 

				--need to do this because tdate only has data from 2017
				if @prior_year_begin_dt_sk is null 
				begin
					set @prior_year_begin_dt_sk = 0
					set @prior_year_begin_dt = dateadd(year,-1,@year_begin_dt)
				end;

				select 	@prior_year_three_month_end_dt_sk = date_sk ,
						@prior_year_three_month_end_dt = actual_dt,
						@prior_three_year = calendar_year
				from edw_core.tdate
				where actual_Dt = dateadd(year,-3,@end_dt);

				--need to do this because tdate only has data from 2017
				if @prior_year_three_month_end_dt_sk is null 
				begin
					set @prior_year_three_month_end_dt_sk = 0
					set @prior_year_three_month_end_dt = dateadd(year,-3,@end_dt)
					set	@prior_three_year = datepart(yyyy,@prior_year_three_month_end_dt) 
				end;

				--if prior year is a leap year, add one day to month end data to change it to 2/29 instead of 2/28
				if @prior_three_year%4 = 0 and datepart(mm,@prior_year_three_month_end_dt) = 2
				begin
					set @prior_year_three_month_end_dt_sk = @prior_year_three_month_end_dt_sk + 1
					set @prior_year_three_month_end_dt = dateadd(dd,+1,@prior_year_three_month_end_dt)
				end
				
				 IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
				BEGIN  
						select 	@end_dt = max(actual_dt) , @end_dt_sk = max(date_sk) 
						from edw_core.tdate
						where yearmonth = @yearmonth and actual_dt <= cast(getdate() as date); 
				END   
				

				--quotes data
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_quotes;
				select *
				into edw_temp.tbroker_summ_quotes
				FROM
				(
					select br.broker_sk, p.product_sk, cust.customer_sk, st.state_sk,
							replace(replace(isnull(q.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES') uwco,
							-- 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between 		 @prior_year_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_ytd_submission_ct, 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between 		 	   @year_begin_dt and 				   @end_dt then q.quote_sk end) 	  ytd_submission_ct, 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between 	  @prior_quarter_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_qtd_submission_ct, 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between 		 	@quarter_begin_dt and 				   @end_dt then q.quote_sk end) 	  qtd_submission_ct, 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between @prior_year_month_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_mtd_submission_ct, 
							count(distinct case when CAST(q.quote_create_ts AS DATE) between 		 	  @month_begin_dt and 				   @end_dt then q.quote_sk end) 	  mtd_submission_ct, 
							--
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between 		@prior_year_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_ytd_quote_ct, 
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between 			  @year_begin_dt and 				  @end_dt then q.quote_sk end) 		 ytd_quote_ct, 
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between 	 @prior_quarter_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_qtd_quote_ct, 
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between 		   @quarter_begin_dt and 				  @end_dt then q.quote_sk end) 		 qtd_quote_ct,
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between @prior_year_month_begin_dt and @prior_year_month_end_dt then q.quote_sk end) prior_mtd_quote_ct, 
							count(distinct case when CAST(q.first_offered_quote_ts AS DATE) between 			 @month_begin_dt and 				  @end_dt then q.quote_sk end) 		 mtd_quote_ct, 
							--
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between 		 @prior_year_begin_dt and @prior_year_month_end_dt 	then qh.net_premium_amt end) prior_ytd_quote_net_premium_amt, 
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between 		 	   @year_begin_dt and 				   @end_dt 	then qh.net_premium_amt end) 		ytd_quote_net_premium_amt, 
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between 	  @prior_quarter_begin_dt and @prior_year_month_end_dt 	then qh.net_premium_amt end) prior_qtd_quote_net_premium_amt, 
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between 		 	@quarter_begin_dt and 				   @end_dt 	then qh.net_premium_amt end) 		qtd_quote_net_premium_amt, 
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between @prior_year_month_begin_dt and @prior_year_month_end_dt 	then qh.net_premium_amt end) prior_mtd_quote_net_premium_amt, 
							sum(case when CAST(q.first_offered_quote_ts AS DATE) between 			  @month_begin_dt and 				   @end_dt 	then qh.net_premium_amt end)		mtd_quote_net_premium_amt, 
							--
							max(CAST(q.first_offered_quote_ts AS DATE)) max_quoted_dt, 
							max(q.bind_dt) max_bind_dt
					from edw_core.tquote q 
					inner join edw_core.tcustomer cust on cust.customer_id = q.customer_id
					inner join edw_core.tproduct p on p.product_cd = q.product_cd
					left join edw_core.tquote_history qh on q.first_offered_quote_history_sk = qh.quote_history_sk 
					inner join edw_core.tbroker br on q.broker_id = br.broker_id
					inner join edw_core.tstate st on q.risk_state_cd = st.state_cd
					where  q.quote_term = 'New'
					and (		  CAST(q.quote_create_ts AS DATE) between @prior_year_begin_dt and @end_dt 
							or CAST(q.first_offered_quote_ts AS DATE) between @prior_year_begin_dt and @end_dt 
							or 				  q.bind_dt between @prior_year_begin_dt and @end_dt) 
					group by br.broker_sk, p.product_sk, cust.customer_sk, st.state_sk,
							replace(replace(isnull(q.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES')
				) a
				where      prior_ytd_submission_ct <> 0 or ytd_submission_ct <> 0 
						or prior_qtd_submission_ct <> 0 or qtd_submission_ct <> 0 
						or prior_mtd_submission_ct <> 0 or mtd_submission_ct <> 0 
						or      prior_ytd_quote_ct <> 0 or      ytd_quote_ct <> 0 
						or      prior_qtd_quote_ct <> 0 or      qtd_quote_ct <> 0 
						or      prior_mtd_quote_ct <> 0 or      mtd_quote_ct <> 0 
						or prior_ytd_quote_net_premium_amt <> 0 or ytd_quote_net_premium_amt <> 0 
						or prior_qtd_quote_net_premium_amt <> 0 or qtd_quote_net_premium_amt <> 0 
						or prior_mtd_quote_net_premium_amt <> 0 or mtd_quote_net_premium_amt <> 0 
						or max_quoted_dt  is not null  
						or max_bind_dt is not null; ; 

				--retention data
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_retention;
				with ren AS
				(
					select 	r.month_sk,
							r.broker_sk, r.product_sk, r.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES') uwco, 
						   	sum(r.renewal_non_flat_cancelled_ct) renewal_ct, sum(r.non_flat_cancelled_ct-r.mid_term_cancelled_ct-r.non_renewal_ct) expiring_ct,
							sum(isnull(r.renewal_sixty_day_written_premium_amt,0)) renewal_prm, 
							sum(isnull(r.expiring_sixty_day_written_premium_amt,0) + isnull(r.expiring_mid_term_cancelled_premium_amt,0) + isnull(r.expiring_non_renewal_written_premium_amt,0)) expiring_prm
					from edw_core.trenewal_summary r, edw_core.tpolicy pol, edw_core.tstate st  
					where r.policy_sk = pol.policy_sk 
					and  pol.risk_state_cd = st.state_cd
					and month_sk between @year_begin_dt_sk and @month_end_dt_sk  
					group by r.month_sk, r.broker_sk, r.product_sk, r.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES')
				)
				select broker_sk,product_sk, customer_sk, uwco, state_sk,
						--  
						sum(case when month_sk between @year_begin_dt_sk and @month_end_dt_sk then renewal_ct else 0 end) renewal_ct,   
						sum(case when month_sk between @year_begin_dt_sk and @month_end_dt_sk then expiring_ct else 0 end) expiring_ct,
						sum(case when month_sk between @year_begin_dt_sk and @month_end_dt_sk then renewal_prm else 0 end) renewal_prm,   
						sum(case when month_sk between @year_begin_dt_sk and @month_end_dt_sk then expiring_prm else 0 end) expiring_prm  
				into edw_temp.tbroker_summ_retention
				from ren
				group by broker_sk,product_sk, customer_sk, uwco, state_sk;

				/*
				print '@prior_year_month_begin_dt_sk - ' + cast ( @prior_year_month_begin_dt_sk as char)
				print '@prior_year_month_end_dt_sk - ' + cast ( @prior_year_month_end_dt_sk as char)
				print '@month_begin_dt_sk - ' + cast ( @month_begin_dt_sk as char)
				print '@month_end_dt_sk - '+ cast (  @month_end_dt_sk as char)
				print '@@prior_year_three_month_end_dt_sk - '+ cast (  @prior_year_three_month_end_dt_sk as char) 
				*/

				--inforce and ytd prm data
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols;
				SELECT summ.broker_sk, summ.product_sk, summ.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES') uwco,   
							--
							sum(case when summ.month_sk = @month_end_dt_sk 			  and summ.inforce_ct = 1 then summ.inforce_ct else 0 end) inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk 			  and summ.inforce_ct = 1 then summ.annual_net_premium_amt else 0 end) inforce_net_premium_amt,
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.inforce_ct = 1 then summ.inforce_ct else 0 end) prior_inforce_ct,  
							sum(case when summ.month_sk = @prior_year_month_end_dt_sk and summ.inforce_ct = 1 then summ.annual_net_premium_amt else 0 end) prior_inforce_net_premium_amt,   
							
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
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between    	  @prior_year_begin_dt and @prior_year_month_end_dt and summ.inforce_ct = 1 then pol.policy_sk end) prior_ytd_new_business_ct ,
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	    @year_begin_dt and 			     	@end_dt and summ.inforce_ct = 1 then pol.policy_sk end) 	   ytd_new_business_ct ,
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between    @prior_quarter_begin_dt and @prior_year_month_end_dt and summ.inforce_ct = 1 then pol.policy_sk end) prior_qtd_new_business_ct ,
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	 @quarter_begin_dt and 				 	@end_dt and summ.inforce_ct = 1 then pol.policy_sk end) 	   qtd_new_business_ct ,
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between @prior_year_month_begin_dt and @prior_year_month_end_dt and summ.inforce_ct = 1 then pol.policy_sk end) prior_mtd_new_business_ct ,
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	   @month_begin_dt and 				 	@end_dt and summ.inforce_ct = 1 then pol.policy_sk end) 	   mtd_new_business_ct ,/*
							--
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  @prior_year_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_ytd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  		@year_begin_dt and 			   	 	@end_dt then summ.mtd_net_premium_amt else 0 end) 	     ytd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between    @prior_quarter_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_qtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	 @quarter_begin_dt and 				 	@end_dt then summ.mtd_net_premium_amt else 0 end) 	     qtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between @prior_year_month_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_mtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	   @month_begin_dt and 				 	@end_dt then summ.mtd_net_premium_amt else 0 end) 	     mtd_new_business_net_premium_amt ,  */
							--
							--
							sum(           case when pol.policy_term = 'New' and td.actual_dt between 	  @prior_year_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_ytd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and td.actual_dt between 	  		@year_begin_dt and 			   	 	@month_end_dt then summ.mtd_net_premium_amt else 0 end) 	     ytd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and td.actual_dt between    @prior_quarter_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_qtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and td.actual_dt between 	  	 @quarter_begin_dt and 				 	@month_end_dt then summ.mtd_net_premium_amt else 0 end) 	     qtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and td.actual_dt between @prior_year_month_begin_dt and @prior_year_month_end_dt then summ.mtd_net_premium_amt else 0 end) prior_mtd_new_business_net_premium_amt ,   
							sum(           case when pol.policy_term = 'New' and td.actual_dt between 	  	   @month_begin_dt and 				 	@month_end_dt then summ.mtd_net_premium_amt else 0 end) 	     mtd_new_business_net_premium_amt ,  
							--
							--sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between @prior_year_month_begin_dt and @prior_year_month_end_dt and summ.inforce_ct = 1 then ph.net_premium_amt else 0 end) prior_mtd_gross_new_business_net_premium_amt,   
							--sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	   @month_begin_dt and 				 	@end_dt and summ.inforce_ct = 1 then ph.net_premium_amt else 0 end) 	  mtd_gross_new_business_net_premium_amt,   
							--
							sum(case when summ.month_sk between @prior_year_month_begin_dt_sk and @prior_year_month_end_dt_sk then summ.mtd_premium_amt else 0 end) prior_mtd_written_premium_amt,   
							sum(case when summ.month_sk between 	  	   @month_begin_dt_sk and 	  		 @month_end_dt_sk then summ.mtd_premium_amt else 0 end) 	  mtd_written_premium_amt,     
							--
							sum(case when summ.month_sk > @prior_year_month_end_dt_sk 		then summ.mtd_premium_amt else 0 end) one_year_written_premium_amt,   
							sum(case when summ.month_sk > @prior_year_three_month_end_dt_sk then summ.mtd_premium_amt else 0 end) three_year_written_premium_amt,   
							--
							sum(case when  summ.month_sk >       @prior_year_month_end_dt_sk then summ.earned_net_premium_amt else 0 end)   one_year_earned_net_premium_amt,
							sum(case when  summ.month_sk > @prior_year_three_month_end_dt_sk then summ.earned_net_premium_amt else 0 end) three_year_earned_net_premium_amt, 
							sum(case when  summ.month_sk >       @prior_year_month_end_dt_sk then summ.earned_exposure 		  else 0 end)   one_year_earned_exposure,
							sum(case when  summ.month_sk > @prior_year_three_month_end_dt_sk then summ.earned_exposure 		  else 0 end) three_year_earned_exposure
							--
				 into edw_temp.tbroker_summ_pols
				 FROM	edw_core.tpolicy_summary summ, edw_core.tpolicy pol, edw_core.tstate st,  edw_core.tdate td,
				 		edw_core.tpolicy_history ph,
				 		(select policy_sk, min(transaction_seq_no) transaction_seq_no
							from edw_core.tpolicy_history
							group by policy_sk ) min_ph
					 where	summ.month_sk between  @prior_year_three_month_end_dt_sk and  @month_end_dt_sk
					 and td.date_sk = summ.month_sk
					 and 	summ.policy_sk = pol.policy_sk
					 and 	pol.risk_state_cd = st.state_cd
					 and 	summ.policy_sk = ph.policy_sk 
					 and 	ph.policy_sk = min_ph.policy_sk and ph.transaction_seq_no = min_ph.transaction_seq_no
					 group by summ.broker_sk, summ.product_sk, summ.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES')
				 
				--inforce and ytd prm data
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols1;
				SELECT ph.broker_sk, ph.product_sk, ph.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES') uwco,   
							--
							sum(case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between @prior_year_month_begin_dt and @prior_year_month_end_dt and prior_inf.policy_sk is not null then ph.net_premium_amt else 0 end) prior_mtd_gross_new_business_net_premium_amt,   
							sum(case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) between 	  	    @month_begin_dt and 			 	 @end_dt and curr_inf.policy_sk is not null then ph.net_premium_amt else 0 end) 	  mtd_gross_new_business_net_premium_amt 
							--
				into edw_temp.tbroker_summ_pols1
				FROM	edw_core.tpolicy pol
				inner join  edw_core.tpolicy_history ph on pol.policy_sk = ph.policy_sk
				inner join (select policy_sk, min(transaction_seq_no) transaction_seq_no
							from edw_core.tpolicy_history
							where greatest(cast(transaction_ts as date), transaction_effective_dt) <= @end_dt 
							group by policy_sk ) min_ph on ph.policy_sk = min_ph.policy_sk and ph.transaction_seq_no = min_ph.transaction_seq_no
				inner join edw_core.tstate st on pol.risk_state_cd = st.state_cd
				left join edw_core.tdaily_inforce_policy prior_inf on pol.policy_sk = prior_inf.policy_sk and prior_inf.inforce_dt_sk = @prior_year_month_end_dt_sk 
				left join edw_core.tdaily_inforce_policy curr_inf  on pol.policy_sk =  curr_inf.policy_sk and  curr_inf.inforce_dt_sk = 		   @end_dt_sk 
				group by ph.broker_sk, ph.product_sk, ph.customer_sk, st.state_sk,
						replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES')
				
				--claims date
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_claims;
				select  cs.broker_sk, cs.product_sk, cs.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES') uwco, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt then 1 else 0 end) one_year_claim_ct, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt then [itd_total_incurred_amt] else 0 end) one_year_loss_incurred_amt, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt 
									 then (case when [itd_total_incurred_amt] > 500000 then 500000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_loss_incurred_capped_amt, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt and c.catastrophe_sk is null then 1 else 0 end) one_year_non_cat_claim_ct, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt and c.catastrophe_sk is null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) one_year_non_cat_loss_incurred_amt, 
							sum(case when c.loss_dt between dateadd(yy,-1,@end_dt) and @end_dt and c.catastrophe_sk is null
									 then (case when [itd_total_incurred_amt] > 500000 then 500000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_non_cat_loss_incurred_capped_amt, 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt then 1 else 0 end) three_year_claim_ct, 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt then [itd_total_incurred_amt] else 0 end) three_year_loss_incurred_amt, 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt 
									 then (case when [itd_total_incurred_amt] > 500000 then 500000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_loss_incurred_capped_amt, 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt and c.catastrophe_sk is null then 1 else 0 end) three_year_non_cat_claim_ct, 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt and c.catastrophe_sk is null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) three_year_non_cat_loss_incurred_amt , 
							sum(case when c.loss_dt between dateadd(yy,-3,@end_dt) and @end_dt and c.catastrophe_sk is null
									 then (case when [itd_total_incurred_amt] > 500000 then 500000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_non_cat_loss_incurred_capped_amt
					into edw_temp.tbroker_summ_claims
					from edw_core.tclaim_summary cs, edw_core.tclaim c,  edw_core.tpolicy pol, edw_core.tstate st 
					where	cs.claim_sk  = c.claim_sk
					and 	cs.policy_sk = pol.policy_sk 
					 and 	pol.risk_state_cd = st.state_cd
					and 	month_sk in (@month_end_dt_sk)
					group by cs.broker_sk, cs.product_sk, cs.customer_sk, st.state_sk,
							replace(replace(isnull(pol.uw_company_nm,'Other'), 'Vault Reciprocal Exchange', 'VRE'), 'Vault E & S Insurance Company', 'VES')
				
				DROP TABLE IF EXISTS edw_temp.tbroker_summary_temp;
				with pol_summ as
				(
					select * 
					from  edw_temp.tbroker_summ_pols
					 
				), pol_summ1 as
				(
					select * 
					from  edw_temp.tbroker_summ_pols1
					 
				), 
				clm_summ as
				( 
					select *
					from edw_temp.tbroker_summ_claims  
				) , 
				quotes as
				(   
					select *
					from edw_temp.tbroker_summ_quotes
				)   
				select 	COALESCE(ps.broker_sk, ps1.broker_sk, cs.broker_sk, q.broker_sk) broker_sk,
						COALESCE(ps.product_sk, ps1.product_sk, cs.product_sk, q.product_sk) product_sk,
						COALESCE(ps.customer_sk, ps1.customer_sk, cs.customer_sk, q.customer_sk) customer_sk,
						COALESCE(ps.state_sk, ps1.state_sk, cs.state_sk, q.state_sk) state_sk,
						COALESCE(ps.uwco, ps1.uwco, cs.uwco, q.uwco) uwco,
						--
						sum(isnull(q.prior_ytd_submission_ct,0)) prior_ytd_submission_ct,
						sum(isnull(q.ytd_submission_ct,0)) ytd_submission_ct,
						sum(isnull(q.prior_qtd_submission_ct,0)) prior_qtd_submission_ct,
						sum(isnull(q.qtd_submission_ct,0)) qtd_submission_ct,
						sum(isnull(q.prior_mtd_submission_ct,0)) prior_mtd_submission_ct,
						sum(isnull(q.mtd_submission_ct,0)) mtd_submission_ct,
						--
						sum(isnull(q.prior_ytd_quote_ct,0)) prior_ytd_quote_ct,
						sum(isnull(q.ytd_quote_ct,0)) ytd_quote_ct,
						sum(isnull(q.prior_qtd_quote_ct,0)) prior_qtd_quote_ct,
						sum(isnull(q.qtd_quote_ct,0)) qtd_quote_ct,
						sum(isnull(q.prior_mtd_quote_ct,0)) prior_mtd_quote_ct,
						sum(isnull(q.mtd_quote_ct,0)) mtd_quote_ct,
						--
						sum(isnull(q.prior_ytd_quote_net_premium_amt,0)) prior_ytd_quote_net_premium_amt,
						sum(isnull(q.ytd_quote_net_premium_amt,0)) ytd_quote_net_premium_amt,  
						sum(isnull(q.prior_qtd_quote_net_premium_amt,0)) prior_qtd_quote_net_premium_amt,
						sum(isnull(q.qtd_quote_net_premium_amt,0)) qtd_quote_net_premium_amt,  
						sum(isnull(q.prior_mtd_quote_net_premium_amt,0)) prior_mtd_quote_net_premium_amt,
						sum(isnull(q.mtd_quote_net_premium_amt,0)) mtd_quote_net_premium_amt,  
						-- avg lines per account - can be calculated
						max(cast(case when q.max_quoted_dt is not null then q.max_quoted_dt end as date)) last_quote_dt,
						max(case when q.max_bind_dt is not null then q.max_bind_dt end) last_bound_dt,
						--
						sum(isnull(ps.prior_customer_ct,0)) prior_customer_ct, 
						sum(isnull(ps.customer_ct,0)) customer_ct, 
						sum(isnull(ps.prior_line_ct,0)) prior_total_line_ct,
						sum(isnull(ps.line_ct,0)) total_line_ct,
						--
						sum(isnull(ps.prior_ytd_new_business_ct,0)) prior_ytd_new_business_ct, 
						sum(isnull(ps.prior_ytd_new_business_net_premium_amt,0)) prior_ytd_new_business_net_premium_amt, 
						sum(isnull(ps.prior_qtd_new_business_ct,0)) prior_qtd_new_business_ct, 
						sum(isnull(ps.prior_qtd_new_business_net_premium_amt,0)) prior_qtd_new_business_net_premium_amt, 
						sum(isnull(ps.prior_mtd_new_business_ct,0)) prior_mtd_new_business_ct, 
						sum(isnull(ps.prior_mtd_new_business_net_premium_amt,0)) prior_mtd_new_business_net_premium_amt, 
						--
						sum(isnull(ps.ytd_new_business_ct,0)) ytd_new_business_ct, 
						sum(isnull(ps.ytd_new_business_net_premium_amt,0)) ytd_new_business_net_premium_amt, 
						sum(isnull(ps.qtd_new_business_ct,0)) qtd_new_business_ct, 
						sum(isnull(ps.qtd_new_business_net_premium_amt,0)) qtd_new_business_net_premium_amt, 
						sum(isnull(ps.mtd_new_business_ct,0)) mtd_new_business_ct, 
						sum(isnull(ps.mtd_new_business_net_premium_amt,0)) mtd_new_business_net_premium_amt, 
						--
						sum(isnull(ps1.prior_mtd_gross_new_business_net_premium_amt,0)) prior_mtd_gross_new_business_net_premium_amt, 
						sum(isnull(ps1.mtd_gross_new_business_net_premium_amt,0)) mtd_gross_new_business_net_premium_amt, 
						--
						sum(isnull(ps.prior_mtd_written_premium_amt,0)) prior_mtd_written_premium_amt, 
						sum(isnull(ps.mtd_written_premium_amt,0)) mtd_written_premium_amt,  
						--
						sum(isnull(ps.one_year_written_premium_amt,0)) one_year_written_premium_amt, 
						sum(isnull(ps.three_year_written_premium_amt,0)) three_year_written_premium_amt,   
						--
						sum(isnull(ps.prior_inforce_ct,0)) prior_inforce_ct, 
						sum(isnull(ps.prior_inforce_net_premium_amt,0)) prior_inforce_net_premium_amt,
						sum(isnull(ps.inforce_ct,0)) inforce_ct, 
						sum(isnull(ps.inforce_net_premium_amt,0)) inforce_net_premium_amt, 
						--
						sum(isnull(ps.one_year_earned_net_premium_amt,0)) one_year_earned_net_premium_amt, 
						sum(isnull(ps.three_year_earned_net_premium_amt,0)) three_year_earned_net_premium_amt, 
						sum(isnull(ps.one_year_earned_exposure,0)) one_year_earned_exposure, 
						sum(isnull(ps.three_year_earned_exposure,0)) three_year_earned_exposure,   
						--
						sum(isnull(cs.one_year_claim_ct,0)) one_year_claim_ct, 
						sum(isnull(cs.one_year_loss_incurred_amt,0)) one_year_loss_incurred_amt,
						sum(isnull(cs.one_year_loss_incurred_capped_amt,0)) one_year_loss_incurred_capped_amt,
						sum(isnull(cs.one_year_non_cat_claim_ct,0)) one_year_non_cat_claim_ct, 
						sum(isnull(cs.one_year_non_cat_loss_incurred_amt,0)) one_year_non_cat_loss_incurred_amt,
						sum(isnull(cs.one_year_non_cat_loss_incurred_capped_amt,0)) one_year_non_cat_loss_incurred_capped_amt, 
						--
						sum(isnull(cs.three_year_claim_ct,0)) three_year_claim_ct, 
						sum(isnull(cs.three_year_loss_incurred_amt,0)) three_year_loss_incurred_amt,
						sum(isnull(cs.three_year_loss_incurred_capped_amt,0)) three_year_loss_incurred_capped_amt,
						sum(isnull(cs.three_year_non_cat_claim_ct,0)) three_year_non_cat_claim_ct, 
						sum(isnull(cs.three_year_non_cat_loss_incurred_amt,0)) three_year_non_cat_loss_incurred_amt, 
						sum(isnull(cs.three_year_non_cat_loss_incurred_capped_amt,0)) three_year_non_cat_loss_incurred_capped_amt, 
						-- 
						getdate() update_ts, @etl_audit_sk etl_audit_sk
				into edw_temp.tbroker_summary_temp
				from pol_summ ps
				full join pol_summ1 ps1 on ps.broker_sk = ps1.broker_sk and ps.product_sk = ps1.product_sk and ps.customer_sk = ps1.customer_sk and ps.uwco = ps1.uwco and ps.state_sk = ps1.state_sk
				full join clm_summ cs  on ps.broker_sk =  cs.broker_sk and ps.product_sk =  cs.product_sk and ps.customer_sk =  cs.customer_sk and ps.uwco =  cs.uwco and ps.state_sk =  cs.state_sk
				full join quotes q     on ps.broker_sk =   q.broker_sk  and ps.product_sk =  q.product_sk and ps.customer_sk =   q.customer_sk and ps.uwco =   q.uwco and ps.state_sk =   q.state_sk
				group by  COALESCE(ps.broker_sk, ps1.broker_sk, cs.broker_sk, q.broker_sk),
						COALESCE(ps.product_sk, ps1.product_sk, cs.product_sk, q.product_sk),
						COALESCE(ps.customer_sk, ps1.customer_sk, cs.customer_sk, q.customer_sk),
						COALESCE(ps.state_sk, ps1.state_sk, cs.state_sk, q.state_sk),
						COALESCE(ps.uwco, ps1.uwco, cs.uwco, q.uwco);

				delete from edw_core.tbroker_summary
				where month_sk = @month_end_dt_sk; 
       
				SET @rows_affected=0;

				INSERT INTO edw_core.tbroker_summary
					( 
						month_sk,
						broker_sk,
						product_sk, 
						customer_sk,
						state_sk, 
						uw_company_cd,
						--
						prior_ytd_submission_ct,
						ytd_submission_ct,
						prior_qtd_submission_ct,
						qtd_submission_ct,
						prior_mtd_submission_ct,
						mtd_submission_ct,
						--
						prior_ytd_quote_ct,
						ytd_quote_ct,
						prior_qtd_quote_ct,
						qtd_quote_ct,
						prior_mtd_quote_ct,
						mtd_quote_ct,
						--
						prior_ytd_quote_net_premium_amt,
						ytd_quote_net_premium_amt,
						prior_qtd_quote_net_premium_amt,
						qtd_quote_net_premium_amt,
						prior_mtd_quote_net_premium_amt,
						mtd_quote_net_premium_amt,
						--
						prior_customer_ct,
						customer_ct,
						prior_total_line_ct,
						total_line_ct, 
						--
						last_quote_dt,
						last_bound_dt,
						--
						prior_ytd_new_business_ct, 
						prior_ytd_new_business_net_premium_amt, 
						prior_qtd_new_business_ct, 
						prior_qtd_new_business_net_premium_amt, 
						prior_mtd_new_business_ct, 
						prior_mtd_new_business_net_premium_amt, 
						--
						ytd_new_business_ct, 
						ytd_new_business_net_premium_amt,  
						qtd_new_business_ct, 
						qtd_new_business_net_premium_amt,  
						mtd_new_business_ct, 
						mtd_new_business_net_premium_amt, 
						--
						prior_mtd_gross_new_business_net_premium_amt, 
						mtd_gross_new_business_net_premium_amt, 
						--
						prior_mtd_written_premium_amt, 
						mtd_written_premium_amt,  
						--
						one_year_written_premium_amt,
						three_year_written_premium_amt,  
						--
						prior_inforce_ct, 
						prior_inforce_net_premium_amt,
						inforce_ct, 
						inforce_net_premium_amt, 
						--
						one_year_earned_net_premium_amt, 
						three_year_earned_net_premium_amt, 
						one_year_earned_exposure, 
						three_year_earned_exposure, 
						--
						one_year_claim_ct, 
						one_year_loss_incurred_amt,
						one_year_loss_incurred_capped_amt,
						one_year_non_cat_claim_ct, 
						one_year_non_cat_loss_incurred_amt,
						one_year_non_cat_loss_incurred_capped_amt, 
						--
						three_year_claim_ct, 
						three_year_loss_incurred_amt,
						three_year_loss_incurred_capped_amt,
						three_year_non_cat_claim_ct, 
						three_year_non_cat_loss_incurred_amt, 
						three_year_non_cat_loss_incurred_capped_amt,  
						--
						policy_expiring_ct,
						policy_renewal_ct,
						policy_expiring_premium_amt,
						policy_renewal_premium_amt, 
						--
						update_ts,
						etl_audit_sk
					)
				select @month_end_dt_sk, 
						coalesce(summ.broker_sk, r.broker_sk), 
						coalesce(summ.product_sk, r.product_sk), 
						coalesce(summ.customer_sk, r.customer_sk), 
						coalesce(summ.state_sk, r.state_sk), 
						coalesce(summ.uwco, r.uwco), 
						--
						sum(summ.prior_ytd_submission_ct), 
						sum(summ.ytd_submission_ct), 
						sum(summ.prior_qtd_submission_ct), 
						sum(summ.qtd_submission_ct), 
						sum(summ.prior_mtd_submission_ct), 
						sum(summ.mtd_submission_ct), 
						--
						sum(summ.prior_ytd_quote_ct), 
						sum(summ.ytd_quote_ct), 
						sum(summ.prior_qtd_quote_ct), 
						sum(summ.qtd_quote_ct), 
						sum(summ.prior_mtd_quote_ct), 
						sum(summ.mtd_quote_ct), 
						--
						sum(summ.prior_ytd_quote_net_premium_amt), 
						sum(summ.ytd_quote_net_premium_amt),
						sum(summ.prior_qtd_quote_net_premium_amt), 
						sum(summ.qtd_quote_net_premium_amt),
						sum(summ.prior_mtd_quote_net_premium_amt), 
						sum(summ.mtd_quote_net_premium_amt),  
						--
						sum(summ.prior_customer_ct) prior_customer_ct, 
						sum(summ.customer_ct) customer_ct, 
						sum(summ.prior_total_line_ct),
						sum(summ.total_line_ct),
						--
						max(summ.last_quote_dt), 
						max(summ.last_bound_dt), 
						--
						sum(summ.prior_ytd_new_business_ct), 
						sum(summ.prior_ytd_new_business_net_premium_amt), 
						sum(summ.prior_qtd_new_business_ct), 
						sum(summ.prior_qtd_new_business_net_premium_amt), 
						sum(summ.prior_mtd_new_business_ct), 
						sum(summ.prior_mtd_new_business_net_premium_amt), 
						--
						sum(summ.ytd_new_business_ct), 
						sum(summ.ytd_new_business_net_premium_amt), 
						sum(summ.qtd_new_business_ct), 
						sum(summ.qtd_new_business_net_premium_amt), 
						sum(summ.mtd_new_business_ct), 
						sum(summ.mtd_new_business_net_premium_amt), 
						--
						sum(summ.prior_mtd_gross_new_business_net_premium_amt) prior_mtd_gross_new_business_net_premium_amt, 
						sum(summ.mtd_gross_new_business_net_premium_amt) mtd_gross_new_business_net_premium_amt, 
						--
						sum(summ.prior_mtd_written_premium_amt) prior_mtd_written_premium_amt, 
						sum(summ.mtd_written_premium_amt) mtd_written_premium_amt,  
						--
						sum(summ.one_year_written_premium_amt) one_year_written_premium_amt, 
						sum(summ.three_year_written_premium_amt) three_year_written_premium_amt,   
						--
						sum(summ.prior_inforce_ct), sum(summ.prior_inforce_net_premium_amt),  
						sum(summ.inforce_ct), sum(summ.inforce_net_premium_amt),   
						--
						sum(summ.one_year_earned_net_premium_amt), 
						sum(summ.three_year_earned_net_premium_amt), 
						sum(summ.one_year_earned_exposure), 
						sum(summ.three_year_earned_exposure), 
						--
						sum(summ.one_year_claim_ct),
						sum(summ.one_year_loss_incurred_amt), 
						sum(summ.one_year_loss_incurred_capped_amt), 
						sum(summ.one_year_non_cat_claim_ct), 
						sum(summ.one_year_non_cat_loss_incurred_amt), 
						sum(summ.one_year_non_cat_loss_incurred_capped_amt), 
						--
						sum(summ.three_year_claim_ct), 
						sum(summ.three_year_loss_incurred_amt), 
						sum(summ.three_year_loss_incurred_capped_amt),
						sum(summ.three_year_non_cat_claim_ct), 
						sum(summ.three_year_non_cat_loss_incurred_amt), 
						sum(summ. three_year_non_cat_loss_incurred_capped_amt), 
						--
						sum(isnull(r.expiring_ct,0)) policy_expiring_ct,
						sum(isnull(r.renewal_ct,0)) policy_renewal_ct,
						sum(isnull(r.expiring_prm,0)) policy_expiring_premium_amt,
						sum(isnull(r.renewal_prm,0)) policy_renewal_premium_amt,
						--
						max(summ.update_ts), max(summ.etl_audit_sk)
				from edw_temp.tbroker_summary_temp summ
				LEFT join edw_temp.tbroker_summ_retention r on summ.broker_sk = r.broker_sk and summ.product_sk = r.product_sk and summ.customer_sk = r.customer_sk and summ.uwco = r.uwco and summ.state_sk = r.state_sk  
				group by  
						coalesce(summ.broker_sk, r.broker_sk), 
						coalesce(summ.product_sk, r.product_sk), 
						coalesce(summ.customer_sk, r.customer_sk), 
						coalesce(summ.state_sk, r.state_sk), 
						coalesce(summ.uwco, r.uwco);
       
				SET @rows_affected=@@ROWCOUNT;

				
				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);	
				if @in_end_dt is not null
				begin
					set @new_last_source_extract_ts= @last_source_extract_ts
				end 	
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts; 

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				if @in_end_dt is not null
				begin
					set @parameter_desc= 'last_source_extract_ts = ' + CAST(@in_end_dt AS VARCHAR(200))
				end 
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;    

				DROP TABLE IF EXISTS edw_temp.tbroker_summary_temp; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_quotes; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols1; 
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_claims;
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_retention;
				 
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

	    IF CURSOR_STATUS('global','c1_rec')>=-1
		BEGIN
		 DEALLOCATE c2_rec
		END; 
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
