SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the broker data at risk state level for each month
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/27/23		Architha Gudimalla				1. Created this procedure  
-- ================================================================================================= 

create OR ALTER PROCEDURE [edw_core].[sp_tbroker_risk_state_summary] 
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
				select br.broker_sk,  st.state_sk, 
						sum(case when q.first_offered_quote_ts between @begin_end_dt and @end_dt then 1 else 0 end) quote_ct, 
						sum(case when q.bind_dt between @begin_end_dt and @end_dt then 1 else 0 end) bind_ct 
				into edw_temp.tbroker_summ_quotes
				from edw_core.tquote q, edw_core.tcustomer cust, edw_core.tbroker br, edw_core.tproduct pr, edw_core.tstate st
				where q.customer_id = cust.customer_id
				and q.broker_id = br.broker_id
				and q.product_cd = pr.product_cd 
				and q.risk_state_cd = st.state_cd
				and (q.first_offered_quote_ts is not null or q.bind_dt is not null)
				--and quote_create_ts <= @end_dt
				group by br.broker_sk, st.state_sk 
 
				
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols;
				SELECT summ.broker_sk,   
							st.state_sk, 
							--
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_ct else 0 end) inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_net_premium_amt else 0 end) inforce_net_premium_amt,
							--
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_ct else 0 end) ves_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_net_premium_amt else 0 end) ves_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_ct else 0 end) vre_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_net_premium_amt else 0 end) vre_inforce_net_premium_amt,
							--
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @year_begin_dt then pol.policy_sk end) ytd_new_business_ct ,
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @year_begin_dt then summ.mtd_net_premium_amt else 0 end) ytd_new_business_net_premium_amt ,   
							count(distinct case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @prior_year_begin_dt then pol.policy_sk end) prior_ytd_new_business_ct ,
							sum(           case when pol.policy_term = 'New' and greatest(cast(ph.transaction_ts as date), ph.transaction_effective_dt) >= @prior_year_begin_dt then summ.mtd_net_premium_amt else 0 end) prior_ytd_new_business_net_premium_amt 
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
					 group by summ.broker_sk--, 
							,st.state_sk 
				 
				
				DROP TABLE IF EXISTS edw_temp.tbroker_risk_state_summary_temp;
				with pol_summ as
				(
					select * 
					from  edw_temp.tbroker_summ_pols
					 
				)  , 
				quotes as
				(   
					select *
					from edw_temp.tbroker_summ_quotes
				) 
				select 	@month_end_dt_sk month_sk,
						COALESCE(ps.broker_sk, q.broker_sk) broker_sk,
						COALESCE(ps.state_sk, q.state_sk) state_sk,
						-- 
						sum(isnull(q.quote_ct,0)) quote_ct,
						sum(isnull(q.bind_ct,0)) bind_ct,
						--
						sum(isnull(ps.ytd_new_business_ct,0)) ytd_new_business_ct, 
						sum(isnull(ps.ytd_new_business_net_premium_amt,0)) ytd_new_business_net_premium_amt, 
						-- 
						sum(isnull(ps.inforce_ct,0)) inforce_ct, 
						sum(isnull(ps.inforce_net_premium_amt,0)) inforce_net_premium_amt,  
						--
						sum(isnull(ps.ves_inforce_ct,0)) ves_inforce_ct,  
						sum(isnull(ps.ves_inforce_net_premium_amt,0)) ves_inforce_net_premium_amt,
						sum(isnull(ps.vre_inforce_ct,0)) vre_inforce_ct,  
						sum(isnull(ps.vre_inforce_net_premium_amt,0)) vre_inforce_net_premium_amt, 
						-- 
						getdate() update_ts, @etl_audit_sk etl_audit_sk
				into edw_temp.tbroker_risk_state_summary_temp
				from pol_summ ps
				full join quotes q  on ps.broker_sk = q.broker_sk  and ps.state_sk = q.state_sk   
				group by COALESCE(ps.broker_sk, q.broker_sk)
						,COALESCE(ps.state_sk, q.state_sk)
				; 

				delete from edw_core.tbroker_risk_state_summary
				where month_sk = @month_end_dt_sk; 

				INSERT INTO edw_core.tbroker_risk_state_summary
					(  
						month_sk,
						broker_sk,  
						risk_state_sk,
						quote_ct,
						bind_ct,  
						ytd_new_business_ct, ytd_new_business_net_premium_amt,  
						inforce_ct,  inforce_net_premium_amt, 
						admitted_inforce_ct, admitted_inforce_net_premium_amt,
						non_admitted_inforce_ct, non_admitted_inforce_net_premium_amt, 
						--source_system_sk,
						update_ts,
						etl_audit_sk
					)
				select month_sk, broker_sk, state_sk,  
						sum(quote_ct) quote_ct, 
						sum(bind_ct) bind_ct,  
						sum(ytd_new_business_ct), sum(ytd_new_business_net_premium_amt), 
						sum(inforce_ct), sum(inforce_net_premium_amt),   
						sum(vre_inforce_ct), sum(vre_inforce_net_premium_amt), 
						sum(ves_inforce_ct), sum(ves_inforce_net_premium_amt),  
						--max(source_system_sk),
						max(update_ts), max(etl_audit_sk)
				from edw_temp.tbroker_risk_state_summary_temp summ
				group by month_sk, broker_sk, state_sk;
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

				DROP TABLE IF EXISTS edw_temp.tbroker_risk_state_summary_temp;  
				DROP TABLE IF EXISTS edw_temp.tbroker_summ_pols;  
				 
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
