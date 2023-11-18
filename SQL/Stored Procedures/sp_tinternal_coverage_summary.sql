 -- =========================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedure summarizes data at the internal coverages level for each month
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 07/18/23		Architha Gudimalla				1. Created this procedure 
-- 08/24/23		Architha Gudimalla				2. Updated EP logic
-- 10/05/23		Architha Gudimalla				3. Fixed division by 0 error for EP calculation
-- 10/16/23		Architha Gudimalla				4. Used source_system_sk from tpolicy instead of tpolicy_transaction in prm subquery  
-- 10/17/23		Architha Gudimalla				5. Used source_system_sk, customer_sk, broker-sk, prudct_sk from max_tr
-- 10/24/23		Architha Gudimalla				6. Fixed division by 0 error for EP calculation  
-- 11/10/23		Architha Gudimalla				7. Corrected net ep code
-- ========================================================================================================================================= 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_tinternal_coverage_summary]
@in_month_end_dt date = null
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
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt = @in_month_end_dt 
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt >  case when @in_month_end_dt is not null then @in_month_end_dt else @last_source_extract_ts end
		  and   actual_dt <= case when @in_month_end_dt is not null then @in_month_end_dt else getdate() end
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

				select 	@prev_month_end_dt_sk = max(datE_sk) 
				from edw_core.tdate
				where yearmonth < @yearmonth;
				
				select 	@year_begin_sk = min(datE_sk) 
				from edw_core.tdate
				where calendar_year = @year;

				delete from edw_core.tinternal_coverage_summary 
				where month_sk = @month_end_dt_sk; 
			
				with inf as
				(
				 SELECT policy_sk, item_sk, internal_coverage_sk, coverage_sk, vehicle_coverage_sk, 
				 		premium_amt inforce_premium_amt, 
				 		net_premium_amt inforce_net_premium_amt
				 FROM	edw_core.tinternal_coverage_inforce
				 where	month_sk = @month_end_dt_sk
				),
				cancels as
				(
				 SELECT policy_sk, item_sk, internal_coverage_sk
				 FROM	edw_core.tpolicy_transaction
				 where	policy_transaction_type_sk = 5
				 and	calendar_month_sk = @month_end_dt_sk
				 and	transaction_effective_dt_sk <= @end_dt_sk
				 and	transaction_dt_sk <= @end_dt_sk
				 and 	internal_coverage_sk <> 0
				 group by policy_sk, item_sk, internal_coverage_sk
				),
				rein as
				(
				 SELECT policy_sk, item_sk, internal_coverage_sk
				 FROM	edw_core.tpolicy_transaction
				 where	policy_transaction_type_sk = 6
				 and	calendar_month_sk = @month_end_dt_sk
				 and	transaction_effective_dt_sk <= @end_dt_sk
				 and	transaction_dt_sk <= @end_dt_sk
				 and 	internal_coverage_sk <> 0
				 group by policy_sk, item_sk, internal_coverage_sk
				),
				xpsr_new as
				( 
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk,
						(
							case
									 -- new issued in the month and effective when ever
								when (tr.transaction_dt_sk between @month_begin_dt_sk AND @end_dt_sk and tr.transaction_effective_dt_sk <= @end_dt_sk)
									 or
									 -- new issued in the past and effective in the month
									 (tr.transaction_dt_sk < @month_begin_dt_sk and tr.transaction_effective_dt_sk between @month_begin_dt_sk AND @end_dt_sk)
								THEN 1.0*(tr.expiration_dt_sk - tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt ) 
								else 0
							end
						) we,
						(
							case
									 -- new issued in the month and effective when ever
								when  (tr.transaction_dt_sk between @month_begin_dt_sk AND @end_dt_sk and tr.transaction_effective_dt_sk <= @end_dt_sk)
									 or
									 -- new issued in the past and effective in the month
									 (tr.transaction_dt_sk < @month_begin_dt_sk and tr.transaction_effective_dt_sk between @month_begin_dt_sk AND @end_dt_sk)
								THEN 1.0*((case when tr.expiration_dt_sk > @end_dt_sk then @end_dt_sk else tr.expiration_dt_sk end
									  -
									  tr.transaction_effective_dt_sk
									  )+1)/datediff(dd,pol.effective_dt,pol.expiration_dt ) 
									 -- issued in the past and effective in the past
								when (tr.transaction_dt_sk < @month_begin_dt_sk and tr.transaction_effective_dt_sk < @month_begin_dt_sk and inf.policy_sk is not null) 
								THEN 1.0*((case when tr.expiration_dt_sk > @end_dt_sk then @end_dt_sk else tr.expiration_dt_sk end
									  - 
									  @month_begin_dt_sk
									  )+1)/datediff(dd,pol.effective_dt,pol.expiration_dt ) 
								else 1.0*0
							end
						) as ee
				 FROM edw_core.tpolicy_transaction tr
				 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
				 left join edw_core.tinternal_coverage_inforce inf on inf.policy_sk = tr.policy_sk and inf.item_sk = tr.item_sk and inf.internal_coverage_sk = tr.internal_coverage_sk and inf.month_sk = @end_dt_sk
				 where effective_dt <= @month_end_dt
				 and   expiration_dt > @month_end_dt
				 and 	tr.internal_coverage_sk <> 0
				 and   tr.transaction_seq_no = (select min(tr1.transaction_seq_no) from edw_core.tpolicy_transaction tr1 where tr1.policy_sk = tr.policy_sk and tr1.item_sk = tr.item_sk and tr1.internal_coverage_sk = tr.internal_coverage_sk)
				 and   tr.policy_transaction_sk = (select min(tr2.policy_transaction_sk) from edw_core.tpolicy_transaction tr2 where tr2.policy_sk = tr.policy_sk and tr2.item_sk = tr.item_sk and tr2.internal_coverage_sk = tr.internal_coverage_sk and tr2.transaction_seq_no = tr.transaction_seq_no) 
				),
				xpsr_exp as
				( 
				 SELECT pol.policy_sk, inf.item_sk, inf.internal_coverage_sk,
						0 we,
						1.0*(datediff(dd,@month_begin_dt,pol.expiration_dt))/datediff(dd,pol.effective_dt,pol.expiration_dt )  as ee
				 FROM edw_core.tpolicy pol, edw_core.tinternal_coverage_inforce inf
				 where inf.policy_sk = pol.policy_sk 
				   and inf.month_sk = @prev_month_end_dt_sk 
				   and expiration_dt between  @month_begin_dt AND @month_end_dt
				),
				xpsr_cancel as
				( 
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk,/*
		 				(   --if policy is issued in the month but effective before, then we for before month beginning
							case when tr.transaction_effective_dt_sk <  @month_begin_dt_sk
							then (@month_begin_dt_sk - tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
							else 0
							end
							+
							(
								(case when tr.expiration_dt_sk >  @@end_dt_sk then @@end_dt_sk else tr.expiration_dt_sk end
								-
								case when tr.transaction_effective_dt_sk <=  @month_begin_dt_sk then @month_begin_dt_sk else tr.transaction_effective_dt_sk end)
							)/datediff(dd,pol.effective_dt,pol.expiration_dt )  
						) we*/
		 				(
							1.0*((tr.transaction_effective_dt_sk-(select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt))-1)/datediff(dd,pol.effective_dt,pol.expiration_dt )  
						) we,
		 				(	
							case 
								--cancel is effective in past or current month
								when tr.transaction_effective_dt_sk <=  @month_begin_dt_sk 
									then 1.0*((tr.transaction_effective_dt_sk-(select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt))-1)/datediff(dd,pol.effective_dt,pol.expiration_dt )
								--cancel is effective in future
								else 0
							end 
						) ee 
				 FROM edw_core.tpolicy_transaction tr, edw_core.tpolicy pol 
				 where tr.policy_sk = pol.policy_sk 
				 and   tr.internal_coverage_sk <> 0
				 and   exists (select policy_sk from cancels c where tr.policy_sk = c.policy_sk and tr.item_sk = c.item_sk and tr.internal_coverage_sk = c.internal_coverage_sk) 
				 and   tr.transaction_seq_no = (select max(tr1.transaction_seq_no) from edw_core.tpolicy_transaction tr1 where tr1.policy_sk = tr.policy_sk and tr1.item_sk = tr.item_sk and tr1.internal_coverage_sk = tr.internal_coverage_sk)
				 and   tr.policy_transaction_sk = (select max(tr2.policy_transaction_sk) from edw_core.tpolicy_transaction tr2 where tr2.policy_sk = tr.policy_sk and tr2.item_sk = tr.item_sk and tr2.internal_coverage_sk = tr.internal_coverage_sk and tr2.transaction_seq_no = tr.transaction_seq_no)
				),
				xpsr_rein as
				( 
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, 
		 				(
							1.0*(((select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt) - tr.transaction_effective_dt_sk)+1)/datediff(dd,pol.effective_dt,pol.expiration_dt )  
						) we,
						0 ee
				 FROM edw_core.tpolicy_transaction tr, edw_core.tpolicy pol 
				 where tr.policy_sk = pol.policy_sk
				 and 	tr.internal_coverage_sk <> 0 
				 and   exists (select policy_sk from rein r where tr.policy_sk = r.policy_sk and tr.item_sk = r.item_sk and tr.internal_coverage_sk = r.internal_coverage_sk)
				 and   tr.transaction_seq_no = (select max(tr1.transaction_seq_no) from edw_core.tpolicy_transaction tr1 where tr1.policy_sk = tr.policy_sk and tr1.item_sk = tr.item_sk and tr1.internal_coverage_sk = tr.internal_coverage_sk)
				 and   tr.policy_transaction_sk = (select max(tr2.policy_transaction_sk) from edw_core.tpolicy_transaction tr2 where tr2.policy_sk = tr.policy_sk and tr2.item_sk = tr.item_sk and tr2.internal_coverage_sk = tr.internal_coverage_sk and tr2.transaction_seq_no = tr.transaction_seq_no)
				),
				prm as
				(
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, --tr.customer_sk, tr.broker_sk, tr.product_sk, pol.source_system_sk,
				 		max(tr.transaction_seq_no) transaction_seq_no,
						max(tr.coverage_sk)  coverage_sk,
						max(tr.vehicle_coverage_sk)  vehicle_coverage_sk,
		 				--max(first_value(tr.coverage_sk)  over (partition by tr.policy_sk order by tr.transaction_seq_no desc)) coverage_sk,
		 				sum(case when calendar_month_sk between @month_begin_dt_sk 	AND @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) mtd_premium_amt,
		 				sum(case when calendar_month_sk between @month_begin_dt_sk 	AND @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) mtd_commission_amt,
		 				sum(case when calendar_month_sk between @month_begin_dt_sk 	AND @month_end_dt_sk THEN tr.tax_fee_surcharge_amt ELSE 0 END) mtd_tax_fee_surcharge_amt,
		 				sum(case when calendar_month_sk between @month_begin_dt_sk 	AND @month_end_dt_sk THEN tr.premium_amt - tr.tax_fee_surcharge_amt ELSE 0 END) mtd_net_premium_amt,
		 				sum(case when calendar_month_sk between @year_begin_sk 		AND @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) ytd_premium_amt,
		 				sum(case when calendar_month_sk between @year_begin_sk 		AND @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) ytd_commission_amt,
		 				sum(case when calendar_month_sk between @year_begin_sk 		AND @month_end_dt_sk THEN tr.tax_fee_surcharge_amt ELSE 0 END) ytd_tax_fee_surcharge_amt,
		 				sum(case when calendar_month_sk between @year_begin_sk 		AND @month_end_dt_sk THEN tr.premium_amt - tr.tax_fee_surcharge_amt ELSE 0 END) ytd_net_premium_amt,
		 				sum(tr.premium_amt) itd_premium_amt,
		 				sum(tr.commission_amt) itd_commission_amt,
		 				sum(tr.tax_fee_surcharge_amt) itd_tax_fee_surcharge_amt,
		 				sum(tr.premium_amt - tr.tax_fee_surcharge_amt) itd_net_premium_amt,
						sum(case when expiration_dt_sk > @month_end_dt_sk THEN annual_premium_amt else 0 end) annual_premium_amt,
		 				sum(
		 					(--for transactions issued in the month, eff in the month or later
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) > 0
								then
										(1+(iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
											greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
										* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
							)
						   ) mtd_ep,
						sum(
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) > 0
								then
									(1+iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
									* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
						   ) total_ep,
		 				sum(
		 					(--for transactions issued in the month, eff in the month or later
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) > 0
								then
									(1+(iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
									* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
							)
						   ) mtd_net_ep,
						sum(
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) > 0
								then
									(1+iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
									* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
							) total_net_ep/*
		 				sum(
							(1+(iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
							-
							iif(tr.effective_dt_sk >= @month_begin_dt_sk, tr.effective_dt_sk, @month_begin_dt_sk))) 
							* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-tr.effective_dt_sk)
						   ) mtd_net_ep,
		 				sum(
							(1+iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
							-
							tr.effective_dt_sk) 
							* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-tr.effective_dt_sk)
						   ) total_net_ep*/
				 FROM edw_core.tpolicy_transaction tr, edw_core.tpolicy pol 
				 where tr.policy_sk = pol.policy_sk
				 and 	tr.internal_coverage_sk <> 0 
				 and   effective_dt_sk <= @end_dt_sk
				 and   transaction_effective_dt_sk <= @end_dt_sk
				 and   transaction_dt_sk <= @end_dt_sk
				 and   expiration_dt > @month_begin_dt --dateadd(month,-2,@month_begin_dt)
				 group by tr.policy_sk, tr.item_sk, tr.internal_coverage_sk--, tr.customer_sk, tr.broker_sk, tr.product_sk, pol.source_system_sk
				),
				max_tr as
				(
					select policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
					from edw_core.tpolicy_transaction 
					where effective_dt_sk <= @end_dt_sk
					and   transaction_effective_dt_sk <= @end_dt_sk
					and   transaction_dt_sk <= @end_dt_sk 
					group by policy_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
				)
				INSERT INTO edw_core.tinternal_coverage_summary
					( 
						month_sk, policy_sk, item_sk, internal_coverage_sk, coverage_sk, vehicle_coverage_sk, customer_sk, broker_sk, product_sk, source_system_sk, 
						inforce_ct, inforce_premium_amt, inforce_net_premium_amt,
						mtd_premium_amt, mtd_commission_amt, mtd_tax_fee_surcharge_amt, mtd_net_premium_amt, 
						ytd_premium_amt, ytd_commission_amt, ytd_tax_fee_surcharge_amt, ytd_net_premium_amt, 
						itd_premium_amt, itd_commission_amt, itd_tax_fee_surcharge_amt, itd_net_premium_amt,
						annual_premium_amt, 
						earned_premium_amt, unearned_premium_amt, 
						earned_net_premium_amt, unearned_net_premium_amt, 
						written_exposure, earned_exposure, update_ts, etl_audit_sk
					)
				select 	@month_end_dt_sk, prm.policy_sk, prm.item_sk, prm.internal_coverage_sk,
						case when inf.coverage_sk is not null then inf.coverage_sk else prm.coverage_sk end coverage_sk, 
						case when inf.vehicle_coverage_sk is not null then inf.vehicle_coverage_sk else prm.vehicle_coverage_sk end vehicle_coverage_sk, 
						max_tr.customer_sk, max_tr.broker_sk, max_tr.product_sk, max_tr.sourcE_system_sk,  
						iif(inf.policy_sk is null,0,1) inforce_ct, 
						iif(inf.policy_sk is null,0,inf.inforce_premium_amt) inforce_premium_amt, 
						iif(inf.policy_sk is null,0,inf.inforce_net_premium_amt) inforce_net_premium_amt, 
						prm.mtd_premium_amt, prm.mtd_commission_amt, prm.mtd_tax_fee_surcharge_amt, prm.mtd_net_premium_amt, 
						prm.ytd_premium_amt, prm.ytd_commission_amt, prm.ytd_tax_fee_surcharge_amt, prm.ytd_net_premium_amt, 
						prm.itd_premium_amt, prm.itd_commission_amt, prm.itd_tax_fee_surcharge_amt, prm.itd_net_premium_amt,
						prm.annual_premium_amt, 
						prm.mtd_ep earned_premium_amt, (1.0000 * prm.itd_premium_amt)-total_ep unearned_premium_amt, 
						prm.mtd_net_ep earned_net_premium_amt, (1.0000 * prm.itd_net_premium_amt)-total_net_ep unearned_net_premium_amt, 
						isnull(xpsr_new.we,0) + isnull(xpsr_exp.we,0) + isnull(xpsr_cancel.we,0) + isnull(xpsr_rein.we,0) 
						written_exposure,
						isnull(xpsr_new.ee,0) + isnull(xpsr_exp.ee,0) + isnull(xpsr_cancel.ee,0) + isnull(xpsr_rein.ee,0) 
						earned_exposure, 
						getdate(), @etl_audit_sk
				from prm
				inner join max_tr on prm.policy_sk = max_tr.policy_sk and prm.transaction_seq_no = max_tr.transaction_seq_no
				left join inf on prm.policy_sk = inf.policy_sk and prm.item_sk = inf.item_sk and prm.internal_coverage_sk = inf.internal_coverage_sk
				left join xpsr_new on prm.policy_sk = xpsr_new.policy_sk and prm.item_sk = xpsr_new.item_sk and prm.internal_coverage_sk = xpsr_new.internal_coverage_sk
				left join xpsr_exp on prm.policy_sk = xpsr_exp.policy_sk and prm.item_sk = xpsr_exp.item_sk and prm.internal_coverage_sk = xpsr_exp.internal_coverage_sk
				left join xpsr_cancel on prm.policy_sk = xpsr_cancel.policy_sk and prm.item_sk = xpsr_cancel.item_sk and prm.internal_coverage_sk = xpsr_cancel.internal_coverage_sk
				left join xpsr_rein on prm.policy_sk = xpsr_rein.policy_sk and prm.item_sk = xpsr_rein.item_sk and prm.internal_coverage_sk = xpsr_rein.internal_coverage_sk
				where prm.mtd_premium_amt <> 0
				   or prm.mtd_commission_amt <> 0
				   or prm.mtd_tax_fee_surcharge_amt <> 0
				   or prm.mtd_net_premium_amt <> 0
				   or prm.ytd_premium_amt <> 0
				   or prm.ytd_commission_amt <> 0
				   or prm.ytd_tax_fee_surcharge_amt <> 0
				   or prm.ytd_net_premium_amt <> 0
				   or prm.mtd_ep <> 0
				   or isnull(inf.inforce_premium_amt,0) <> 0
				   or isnull(xpsr_new.we,0) <> 0
				   or isnull(xpsr_exp.we,0) <> 0
				   or isnull(xpsr_cancel.we,0) <> 0
				   or isnull(xpsr_rein.we,0) <> 0 
				   or isnull(xpsr_new.ee,0) <> 0
				   or isnull(xpsr_exp.ee,0) <> 0
				   or isnull(xpsr_cancel.ee,0) <> 0
				   or isnull(xpsr_rein.ee,0) <> 0;
       
				SET @rows_affected=@@ROWCOUNT;

				-- Update control table
				SET @new_last_source_extract_ts = COALESCE(@end_dt,@last_source_extract_ts);  
				if @in_month_end_dt is not null
				begin
					set @new_last_source_extract_ts= @last_source_extract_ts
				end 	
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				if @in_month_end_dt is not null
				begin
					set @parameter_desc= 'last_source_extract_ts = ' + CAST(@in_month_end_dt AS VARCHAR(200))
				end 
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
