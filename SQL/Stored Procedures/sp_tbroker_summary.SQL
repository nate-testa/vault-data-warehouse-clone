/****** Object:  StoredProcedure [edw_core].[sp_tbroker_summary]    Script Date: 9/13/2023 4:26:45 AM ******/
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
-- ================================================================================================= 

create or ALTER PROCEDURE [edw_core].[sp_tbroker_summary]
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
	
		DECLARE @one_year_prior_month_end_dt_sk INT
		DECLARE @three_year_prior_month_end_dt_sk INT
		DECLARE @year_begin_month_end_dt_sk INT 
		DECLARE @month_end_dt_sk INT  
		DECLARE @end_dt DATETIME 
		DECLARE @year INT 
		DECLARE @yearmonth INT   
		
		DECLARE c1_rec CURSOR
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
	
		DECLARE @parameter_desc VARCHAR(255) 

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth, @year; 
		WHILE @@FETCH_STATUS = 0
			BEGIN

				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				select 	@month_end_dt_sk = max(datE_sk),  
						@end_dt = max(actual_dt),
						@year = max(calendar_year)
				from edw_core.tdate
				where yearmonth = @yearmonth;

				select 	@one_year_prior_month_end_dt_sk = date_sk 
				from edw_core.tdate
				where actual_Dt = dateadd(year,-1,@end_dt);

				select 	@three_year_prior_month_end_dt_sk = date_sk 
				from edw_core.tdate
				where actual_Dt = dateadd(year,-3,@end_dt);

				select 	@year_begin_month_end_dt_sk = max(date_sk) 
				from edw_core.tdate
				where yearmonth =  cast(cast(@year as varchar) + '01' as int); 
				
				 IF @yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,'0','') ,datepart(mm,getdate()) )
				BEGIN  
						select 	@end_dt = max(actual_dt) 
						from edw_core.tdate
						where yearmonth = @yearmonth and actual_dt < cast(getdate() as date); 
				END  

				delete from edw_core.tbroker_summary
				where month_sk = @month_end_dt_sk; 

				with pol_summ as
				(
					 SELECT summ.broker_sk, --policy_sk, 
							summ.customer_sk,
							summ.product_sk,  
							--st.state_sk,
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_ct else 0 end) inforce_ct,  
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_premium_amt else 0 end) inforce_premium_amt, 
							sum(case when summ.month_sk = @month_end_dt_sk then summ.inforce_net_premium_amt else 0 end) inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_ct else 0 end) ves_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault E & S Insurance Company' then summ.inforce_net_premium_amt else 0 end) ves_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_ct else 0 end) vre_inforce_ct,   
							sum(case when summ.month_sk = @month_end_dt_sk and pol.uw_company_nm = 'Vault Reciprocal Exchange' then summ.inforce_net_premium_amt else 0 end) vre_inforce_net_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk then summ.mtd_commission_amt else 0 end) mtd_commission_amt,
							sum(case when summ.month_sk = @month_end_dt_sk then summ.mtd_tax_fee_surcharge_amt else 0 end) mtd_tax_fee_surcharge_amt,
							sum(case when summ.month_sk = @month_end_dt_sk then summ.mtd_premium_amt else 0 end) mtd_premium_amt,
							sum(case when summ.month_sk = @month_end_dt_sk then summ.mtd_net_premium_amt else 0 end) mtd_net_premium_amt,
							sum(case when summ.month_sk >= @year_begin_month_end_dt_sk then summ.mtd_premium_amt else 0 end) ytd_premium_amt,
							sum(case when summ.month_sk >= @year_begin_month_end_dt_sk then summ.mtd_net_premium_amt else 0 end) ytd_net_premium_amt,
							count(distinct case when pol.policy_term = 'New' and summ.month_sk >= @year_begin_month_end_dt_sk then pol.policy_sk end) ytd_new_business_ct ,
							sum(case when pol.policy_term = 'New' and summ.month_sk >= @year_begin_month_end_dt_sk then summ.mtd_premium_amt else 0 end) ytd_new_business_premium_amt ,
							sum(case when pol.policy_term = 'New' and summ.month_sk >= @year_begin_month_end_dt_sk then summ.mtd_net_premium_amt else 0 end) ytd_new_business_net_premium_amt ,   
							sum(case when summ.month_sk >= @one_year_prior_month_end_dt_sk 		then summ.earned_net_premium_amt else 0 end) one_year_earned_net_premium_amt,
							sum(case when summ.month_sk >= @three_year_prior_month_end_dt_sk 	then summ.earned_net_premium_amt else 0 end) three_year_earned_net_premium_amt, 
							sum(case when summ.month_sk >= @one_year_prior_month_end_dt_sk 		then summ.earned_exposure else 0 end) one_year_earned_exposure,
							sum(case when summ.month_sk >= @three_year_prior_month_end_dt_sk 	then summ.earned_exposure else 0 end) three_year_earned_exposure
					 FROM	edw_core.tpolicy_summary summ, edw_core.tpolicy pol, edw_core.tstate st
					 where	summ.month_sk between  @three_year_prior_month_end_dt_sk and  @month_end_dt_sk
					 and 	summ.policy_sk = pol.policy_sk
					 and 	pol.risk_state_cd = st.state_cd
					 and 	summ.inforce_ct = 1
					 group by summ.broker_sk, --policy_sk, 
							summ.customer_sk,
							summ.product_sk
							--,st.state_sk
				), 
				clm_summ as
				( 
					select  cs.broker_sk, --policy_sk, 
							cs.customer_sk,
							cs.product_sk,  
							--st.state_sk,
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 then 1 else 0 end) one_year_claim_ct, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 then [itd_total_incurred_amt] else 0 end) one_year_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 and c.catastrophe_sk is not null then 1 else 0 end) one_year_non_cat_claim_ct, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 and c.catastrophe_sk is not null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) one_year_non_cat_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 365 and c.catastrophe_sk is not null
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) one_year_non_cat_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 then 1 else 0 end) three_year_claim_ct, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 then [itd_total_incurred_amt] else 0 end) three_year_loss_incurred_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_loss_incurred_capped_amt, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 and c.catastrophe_sk is not null then 1 else 0 end) three_year_non_cat_claim_ct, 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 and c.catastrophe_sk is not null 
									 then [itd_total_incurred_amt] 
									 else 0 
							end) three_year_non_cat_loss_incurred_amt , 
							sum(case when datediff(d,c.loss_dt,getdate()) between 0 and 1095 and c.catastrophe_sk is not null
									 then (case when [itd_total_incurred_amt] > 100000 then 100000 else [itd_total_incurred_amt] end) 
									 else 0 end
							) three_year_non_cat_loss_incurred_capped_amt
					from edw_core.tclaim_feature_summary cs, edw_core.tclaim c,  edw_core.tpolicy pol , edw_core.tstate st
					where	month_sk = @month_end_dt_sk
					and 	cs.claim_sk  = c.claim_sk
					and 	cs.policy_sk = pol.policy_sk
					 and pol.risk_state_cd = st.state_cd
					group by cs.broker_sk, --policy_sk, 
							cs.customer_sk, 
							cs.product_sk
							--,st.state_sk
				) 
				INSERT INTO edw_core.tbroker_summary
					( 
						month_sk,
						--policy_sk,
						broker_sk,
						customer_sk,
						product_sk,
						--risk_state_sk, 
						quote_ct,
						customer_ct,
						-- avg lines per account - can be calculated
						last_quote_dt,
						last_bound_dt,
						ytd_new_business_ct, 
						ytd_new_business_premium_amt,
						ytd_new_business_net_premium_amt, 
						inforce_ct, 
						inforce_premium_amt,
						inforce_net_premium_amt,
						non_admitted_inforce_ct,  
						non_admitted_inforce_net_premium_amt,
						admitted_inforce_ct,  
						admitted_inforce_net_premium_amt,
						mtd_commission_amt,
						mtd_tax_fee_surcharge_amt,
						mtd_premium_amt, 
						mtd_net_premium_amt,  
						ytd_premium_amt, 
						ytd_net_premium_amt,  
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
						three_year_claim_ct, 
						three_year_loss_incurred_amt,
						three_year_loss_incurred_capped_amt,
						three_year_non_cat_claim_ct, 
						three_year_non_cat_loss_incurred_amt, 
						three_year_non_cat_loss_incurred_capped_amt,
						update_ts,
						etl_audit_sk
					)
				select 	@month_end_dt_sk, 
						isnull(ps.broker_sk, cs.broker_sk),
						isnull(ps.customer_sk, cs.customer_sk),
						isnull(ps.product_sk, cs.product_sk),
						--isnull(ps.state_sk, cs.state_sk), 
						0 quote_ct,
						count(distinct isnull(ps.customer_sk, cs.customer_sk)) customer_ct,
						-- avg lines per account - can be calculated
						null last_quote_dt,
						null last_bound_dt,
						sum(ps.ytd_new_business_ct) new_business_ct, 
						sum(ps.ytd_new_business_premium_amt) new_business_premium_amt,  
						sum(ps.ytd_new_business_net_premium_amt) new_business_net_premium_amt, 
						sum(ps.inforce_ct), 
						sum(ps.inforce_premium_amt),
						sum(ps.inforce_net_premium_amt),
						sum(ps.ves_inforce_ct),  
						sum(ps.ves_inforce_net_premium_amt),
						sum(ps.vre_inforce_ct),  
						sum(ps.vre_inforce_net_premium_amt),
						sum(ps.mtd_commission_amt),
						sum(ps.mtd_tax_fee_surcharge_amt),
						sum(ps.mtd_premium_amt), 
						sum(ps.mtd_net_premium_amt),  
						sum(ps.ytd_premium_amt), 
						sum(ps.ytd_net_premium_amt),  
						sum(ps.one_year_earned_net_premium_amt), 
						sum(ps.three_year_earned_net_premium_amt), 
						sum(ps.one_year_earned_exposure), 
						sum(ps.three_year_earned_exposure), 
						sum(isnull(cs.one_year_claim_ct,0)), 
						sum(isnull(cs.one_year_loss_incurred_amt,0)),
						sum(isnull(cs.one_year_loss_incurred_capped_amt,0)),
						sum(isnull(cs.one_year_non_cat_claim_ct,0)), 
						sum(isnull(cs.one_year_non_cat_loss_incurred_amt,0)),
						sum(isnull(cs.one_year_non_cat_loss_incurred_capped_amt,0)),
						sum(isnull(cs.three_year_claim_ct,0)), 
						sum(isnull(cs.three_year_loss_incurred_amt,0)),
						sum(isnull(cs.three_year_loss_incurred_capped_amt,0)),
						sum(isnull(cs.three_year_non_cat_claim_ct,0)), 
						sum(isnull(cs.three_year_non_cat_loss_incurred_amt,0)), 
						sum(isnull(cs.three_year_non_cat_loss_incurred_capped_amt,0)), 
						getdate(), @etl_audit_sk
				from pol_summ ps
				full join clm_summ cs 
				on ps.broker_sk = cs.broker_sk 
				and ps.customer_sk = cs.customer_sk  
				and ps.product_sk = cs.product_sk  
				--and ps.state_sk = cs.state_sk 
				--where  isnull(xpsr_rein.ee,0) <> 0
				group by isnull(ps.customer_sk, cs.customer_sk),
						isnull(ps.broker_sk, cs.broker_sk),
						isnull(ps.product_sk, cs.product_sk)
						--,isnull(ps.state_sk, cs.state_sk)
				;
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts=COALESCE(@end_dt,@last_source_extract_ts);
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 
				 
				FETCH NEXT FROM c1_rec INTO @yearmonth, @year;
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