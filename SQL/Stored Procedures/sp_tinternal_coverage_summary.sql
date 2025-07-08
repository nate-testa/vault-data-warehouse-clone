/****** Object:  StoredProcedure [edw_core].[sp_tinternal_coverage_summary]    Script Date: 2/8/2024 1:15:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 -- =========================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedure summarizes data at the internal coverages level for each month
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author							 |	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 07/18/23		Architha Gudimalla				 1. Created this procedure 
-- 08/24/23		Architha Gudimalla				 2. Updated EP logic
-- 10/05/23		Architha Gudimalla				 3. Fixed division by 0 error for EP calculation
-- 10/16/23		Architha Gudimalla				 4. Used source_system_sk from tpolicy instead of tpolicy_transaction in prm subquery  
-- 10/17/23		Architha Gudimalla				 5. Used source_system_sk, customer_sk, broker-sk, prudct_sk from max_tr
-- 10/24/23		Architha Gudimalla				 6. Fixed division by 0 error for EP calculation  
-- 11/10/23		Architha Gudimalla				 7. Corrected net ep code
-- 12/06/23		Architha Gudimalla				 8. Fixed exposure calculation
-- 02/07/24		Architha Gudimalla				 9. Added annual net prm
-- 03/26/24		Architha Gudimalla				10. Added collection_class_type_sk
-- 07/03/24		Yunus Mohammed					11. Added policy_history_sk
-- 07/18/24		Architha Gudimalla				12. Updated logic for @last_source_extract_ts
-- 07/08/25		Architha Gudimalla				13. Updated EP logic 
-- ========================================================================================================================================= 

create or ALTER  PROCEDURE [edw_core].[sp_tinternal_coverage_summary]
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
		DECLARE @parameter_desc VARCHAR(255) 
		
		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt = @in_month_end_dt 
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt >= case when @in_month_end_dt is not null then @in_month_end_dt else @last_source_extract_ts end
		  and   actual_dt <  case when @in_month_end_dt is not null then @in_month_end_dt else cast(getdate() as date) end
		group by yearmonth
		order by 1;   

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth, @year; 
		WHILE @@FETCH_STATUS = 0
			BEGIN 
				
				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				set @current_date =GETDATE() ;  
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
			
				DROP TABLE IF EXISTS edw_temp.tinternal_coverage_summary_can_rein_temp1;
				--insert cancels
				 SELECT policy_sk, item_sk, internal_coverage_sk, policy_transaction_type_sk , transaction_seq_no 
				 into edw_temp.tinternal_coverage_summary_can_rein_temp1
				 FROM	edw_core.tpolicy_transaction
				 where	isnull(internal_coverage_sk,0) <> 0 
				 and  policy_transaction_type_sk = 5
				 and   transaction_effective_dt_sk <> expiration_dt_sk
				 and	calendar_month_sk = @month_end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				 group by policy_sk, item_sk, internal_coverage_sk, policy_transaction_type_sk, transaction_seq_no 
				 
				 union all
				 
				 SELECT policy_sk, item_sk, internal_coverage_sk, policy_transaction_type_sk , transaction_seq_no 
				 FROM	edw_core.tpolicy_transaction
				 where	isnull(internal_coverage_sk,0) <> 0 
				 and  policy_transaction_type_sk = 6
				 and   transaction_effective_dt_sk <> expiration_dt_sk
				 and	calendar_month_sk = @month_end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				 group by policy_sk, item_sk, internal_coverage_sk, policy_transaction_type_sk, transaction_seq_no ;  
				 
				delete a
				from edw_temp.tinternal_coverage_summary_can_rein_temp1 a
				inner join ( select policy_sk, item_sk, internal_coverage_sk, 
									sum(case when policy_transaction_type_sk = 5 then 1 else 0 end) cancel_ct, 
									sum(case when policy_transaction_type_sk = 6 then 1 else 0 end) rein_ct
							from edw_temp.tinternal_coverage_summary_can_rein_temp1
							group by policy_sk, item_sk, internal_coverage_sk
						   ) b on a.policy_sk = b.policy_sk and a.item_sk = b.item_sk and a.internal_coverage_sk = b.internal_coverage_sk
				where b.cancel_ct = b.rein_ct;		

				 
				DROP TABLE IF EXISTS edw_temp.tinternal_coverage_summary_max_tr;
				select policy_sk, item_sk, internal_coverage_sk, max(transaction_seq_no) transaction_seq_no
				into edw_temp.tinternal_coverage_summary_max_tr
				from edw_core.tpolicy_transaction 
				where isnull(internal_coverage_sk,0) <> 0 
				 and  effective_dt_sk <= @end_dt_sk
				and   transaction_effective_dt_sk <= @end_dt_sk
				and   transaction_dt_sk <= @end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				group by policy_sk, item_sk, internal_coverage_sk;

				--remove the policy if the policy is issued and cancelled multiple times and the last seq no is not a rein or cancel, no need to adjust exposures
				delete  
				from a
				from edw_temp.tinternal_coverage_summary_can_rein_temp1 a
				inner join (select policy_sk, item_sk, internal_coverage_sk 
							from edw_temp.tinternal_coverage_summary_can_rein_temp1 
				            group by policy_sk, item_sk, internal_coverage_sk
							having count(distinct policy_transaction_type_sk) > 1) c on a.policy_sk = c.policy_sk and a.item_sk = c.item_sk and a.internal_coverage_sk = c.internal_coverage_sk
				where not exists (select * from edw_temp.tinternal_coverage_summary_max_tr b 
								  where a.policy_sk = b.policy_sk and a.item_sk = b.item_sk and a.internal_coverage_sk = b.internal_coverage_sk and a.transaction_seq_no = b.transaction_seq_no);
				 
				DROP TABLE IF EXISTS edw_temp.tinternal_coverage_summary_max_tr; 
				
				with inf as
				(
				 SELECT policy_sk, item_sk, internal_coverage_sk, coverage_sk, vehicle_coverage_sk,
				 		premium_amt inforce_premium_amt, 
				 		net_premium_amt inforce_net_premium_amt
				 FROM	edw_core.tinternal_coverage_inforce
				 where	month_sk = @month_end_dt_sk
				), 
				max_tr as
				(
					select policy_sk, policy_history_sk,  customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
					from edw_core.tpolicy_transaction 
					where isnull(internal_coverage_sk,0) <> 0 
				 	and  effective_dt_sk <= @end_dt_sk
					and   transaction_effective_dt_sk <= @end_dt_sk
					and   transaction_dt_sk <= @end_dt_sk 
					group by policy_sk, policy_history_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
				),  
				min_tr as
				(
					select distinct policy_sk, item_sk, internal_coverage_sk,  
							min(calendar_month_sk) over (partition by policy_sk, item_sk, internal_coverage_sk) calendar_month_sk,
							max(transaction_seq_no) over (partition by policy_sk,item_sk, internal_coverage_sk) max_tr_seq_no
					from edw_core.tpolicy_transaction 
					where isnull(internal_coverage_sk,0) <> 0 
				 	and  effective_dt_sk <= @end_dt_sk
					and   transaction_effective_dt_sk <= @end_dt_sk
					and   transaction_dt_sk <= @end_dt_sk  
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
							case when inf.policy_sk is not null  
							then 
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
							else  1.0*0
							end
						) as ee
				 FROM edw_core.tpolicy_transaction tr
				 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
				 left join edw_core.tinternal_coverage_inforce inf on inf.policy_sk = tr.policy_sk and inf.item_sk = tr.item_sk and inf.internal_coverage_sk = tr.internal_coverage_sk and inf.month_sk = @month_end_dt_sk
				 where isnull(tr.internal_coverage_sk,0) <> 0 
				 and  pol.effective_dt <= @month_end_dt
				 and   pol.expiration_dt > @month_end_dt
				 and   tr.transaction_effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_dt_sk <= @end_dt_sk
				 and   tr.transaction_seq_no = (select min(tr1.transaction_seq_no) from edw_core.tpolicy_transaction tr1 
				 								where tr1.policy_sk = tr.policy_sk and tr1.item_sk = tr.item_sk and tr1.internal_coverage_sk = tr.internal_coverage_sk)
				 and   tr.policy_transaction_sk = (select min(tr2.policy_transaction_sk) from edw_core.tpolicy_transaction tr2 
				 								   where tr2.policy_sk = tr.policy_sk and tr2.item_sk = tr.item_sk and tr2.internal_coverage_sk = tr.internal_coverage_sk 
												   and tr2.transaction_seq_no = tr.transaction_seq_no) 
				),
				xpsr_exp as
				( 
				 SELECT inf.policy_sk, inf.item_sk, inf.internal_coverage_sk,
						0 we,
						1.0*(datediff(dd,@month_begin_dt,pol.expiration_dt))/datediff(dd,pol.effective_dt,pol.expiration_dt )  as ee
				 FROM edw_core.tpolicy pol, edw_core.tinternal_coverage_inforce inf
				 where inf.policy_sk = pol.policy_sk 
				   and inf.month_sk = @prev_month_end_dt_sk
				   and pol.expiration_dt between  @month_begin_dt AND @month_end_dt
				   and not exists (select policy_sk from edw_temp.tinternal_coverage_summary_can_rein_temp1 c 
									where inf.policy_sk = c.policy_sk and inf.item_sk = c.item_sk and inf.internal_coverage_sk = c.internal_coverage_sk 
									and c.policy_transaction_type_sk = 5)
				),
				xpsr_cancel as
				( 
					 select policy_sk, item_sk, internal_coverage_sk , sum(we) we, sum(ee) ee
					 from
					 (
						 SELECT distinct tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.transaction_seq_no,
		 						(
									1.0*((tr.transaction_effective_dt_sk-(select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt)))/datediff(dd,pol.effective_dt,pol.expiration_dt )  
								) we,
		 						(	
									case 
										--cancellation on an expired policy
										when (tr.expiration_dt_sk <=  @month_begin_dt_sk)  
											then 1.0*(tr.transaction_effective_dt_sk-expiration_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
										--cancel is effective in past or current month
										when tr.transaction_effective_dt_sk <=  @month_begin_dt_sk   and  min_tr.calendar_month_sk <> @month_end_dt_sk
											then 1.0*(tr.transaction_effective_dt_sk-@month_begin_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
										--cancel is effective in current month but pol also started in curr month
											when tr.transaction_effective_dt_sk between  @month_begin_dt_sk  and  @month_end_dt_sk  and tr.effective_dt_sk between  @month_begin_dt_sk  and  @month_end_dt_sk   
												then 1.0*(tr.transaction_effective_dt_sk -  tr.effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
										--cancel is effective in the current month, calculate the missing ee
										when tr.transaction_effective_dt_sk >  @month_begin_dt_sk and tr.transaction_effective_dt_sk <=  @month_end_dt_sk 
											and  min_tr.calendar_month_sk not between  @month_begin_dt_sk  and  @month_end_dt_sk   
											then 1.0*(tr.transaction_effective_dt_sk-@month_begin_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt ) 
										--cancel is effective in past but policy started this month
										when tr.transaction_effective_dt_sk <=  @month_end_dt_sk 
											and  tr.transaction_effective_dt_sk <> tr.effective_dt_sk  
											and  min_tr.calendar_month_sk between  @month_begin_dt_sk  and  @month_end_dt_sk   
											then 1.0*(tr.transaction_effective_dt_sk-tr.effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )  
										--cancel is effective in future
										else 0
									end 
								) ee 
						 FROM edw_core.tpolicy_transaction tr
						 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
						 left join min_tr on min_tr.policy_sk = tr.policy_sk and min_tr.item_sk = tr.item_sk and min_tr.internal_coverage_sk = tr.internal_coverage_sk  
						 where isnull(tr.internal_coverage_sk,0) <> 0 
				 		 and  exists (select policy_sk from edw_temp.tinternal_coverage_summary_can_rein_temp1 c 
									   where tr.policy_sk = c.policy_sk and tr.item_sk = c.item_sk and tr.internal_coverage_sk = c.internal_coverage_sk 
									   and c.policy_transaction_type_sk = 5)
						 and tr.policy_transaction_type_sk = 5   
						 and tr.calendar_month_sk = @month_end_dt_sk
					) aa
					group by policy_sk, item_sk, internal_coverage_sk
												 	
				),
				xpsr_rein as
				( 
					 select policy_sk, item_sk, internal_coverage_sk , sum(we) we, sum(ee) ee
					 from
					 (
						 SELECT distinct tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, transaction_seq_no,
		 						(
									1.0*(((select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt) - tr.transaction_effective_dt_sk))/datediff(dd,pol.effective_dt,pol.expiration_dt )  
								) we,
								case when inf.policy_sk is not null   
								then	
										case 
											--cancel is effective in past 
											when tr.transaction_effective_dt_sk <=  @month_begin_dt_sk --removed +1
												then 1.0*(@month_begin_dt_sk-tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
											--cancel is effective in the current month--removed +1
											when tr.transaction_effective_dt_sk >  @month_begin_dt_sk and tr.transaction_effective_dt_sk <=  @month_end_dt_sk 
												then 1.0*(@month_end_dt_sk-tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )  
											--cancel is effective in future
											else 0
										end  
									 when inf.policy_sk is null and tr.expiration_dt_sk between @month_begin_dt_sk and @month_end_dt_sk 
									 then  1.0*(tr.expiration_dt_sk-tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
								else 0
								end ee
						 FROM edw_core.tpolicy_transaction tr
						 inner join edw_core.tpolicy pol on tr.policy_sk = pol.policy_sk
						 left join edw_core.tinternal_coverage_inforce inf 
									on inf.policy_sk = tr.policy_sk and inf.item_sk = tr.item_sk and inf.internal_coverage_sk = tr.internal_coverage_sk and inf.month_sk = @month_end_dt_sk
						 where isnull(tr.internal_coverage_sk,0) <> 0 
				 		and  exists (select policy_sk from edw_temp.tinternal_coverage_summary_can_rein_temp1 r 
										where tr.policy_sk = r.policy_sk and tr.item_sk = r.item_sk and tr.internal_coverage_sk = r.internal_coverage_sk and r.policy_transaction_type_sk = 6)
						 and	tr.policy_transaction_type_sk = 6
						 and tr.calendar_month_sk = @month_end_dt_sk 
					) aa
					group by policy_sk, item_sk, internal_coverage_sk
				),
				prm as
				(
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.product_sk, --tr.customer_sk, tr.broker_sk, pol.source_system_sk,
				 		max(tr.transaction_seq_no) transaction_seq_no,
						max(tr.collection_class_type_sk) collection_class_type_sk,
						--max(tr.product_sk)  product_sk,
						max(tr.coverage_sk)  coverage_sk,
						max(tr.vehicle_coverage_sk)  vehicle_coverage_sk,
		 				sum(case when tr.calendar_month_sk between @month_begin_dt_sk AND @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) mtd_premium_amt,
		 				sum(case when tr.calendar_month_sk between @month_begin_dt_sk AND @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) mtd_commission_amt,
		 				sum(case when tr.calendar_month_sk between @month_begin_dt_sk AND @month_end_dt_sk THEN tr.tax_fee_surcharge_amt ELSE 0 END) mtd_tax_fee_surcharge_amt,
		 				sum(case when tr.calendar_month_sk between @month_begin_dt_sk AND @month_end_dt_sk THEN tr.premium_amt - tr.tax_fee_surcharge_amt ELSE 0 END) mtd_net_premium_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) ytd_premium_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) ytd_commission_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.tax_fee_surcharge_amt ELSE 0 END) ytd_tax_fee_surcharge_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.premium_amt - tr.tax_fee_surcharge_amt ELSE 0 END) ytd_net_premium_amt,
		 				sum(tr.premium_amt) itd_premium_amt,
		 				sum(tr.commission_amt) itd_commission_amt,
		 				sum(tr.tax_fee_surcharge_amt) itd_tax_fee_surcharge_amt,
		 				sum(tr.premium_amt - tr.tax_fee_surcharge_amt) itd_net_premium_amt,
						sum(tr.annual_premium_amt) annual_premium_amt, 
				 		sum(case when tr.tax_fee_surcharge_sk = 0 then tr.annual_premium_amt else 0 end) annual_net_premium_amt,
						sum(tr.ceded_premium_amt) ceded_premium_amt,
		 				sum(
		 						(--for transactions issued in the month, eff in the month or later
									case when tr.expiration_dt_sk > @month_begin_dt_sk and 
											tr.policy_transaction_type_sk in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
										then
											(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
											-
											iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
												greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
											* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
										 when tr.expiration_dt_sk > @month_begin_dt_sk and 
											tr.policy_transaction_type_sk not in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
										then
											(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
											-
											iif(tr.transaction_effective_dt_sk >= @month_begin_dt_sk, tr.transaction_effective_dt_sk, @month_begin_dt_sk))) 
											* tr.premium_amt/(tr.expiration_dt_sk-tr.transaction_effective_dt_sk)
										 when tr.calendar_month_sk  = @month_end_dt_sk
										  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
										 then tr.premium_amt
										else 0
									end
								)  
						   ) mtd_ep,  
						sum(
								case when tr.policy_transaction_type_sk in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
										* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									  when tr.policy_transaction_type_sk not in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
										* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									 when tr.calendar_month_sk  = @month_end_dt_sk
									  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
									 then tr.premium_amt
									else 0
								end
							) total_ep, 
		 				sum(
		 						(--for transactions issued in the month, eff in the month or later
									case when tr.expiration_dt_sk > @month_begin_dt_sk and 
											tr.policy_transaction_type_sk in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
										then
											(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
											-
											iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
												greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
											* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
										 when tr.expiration_dt_sk > @month_begin_dt_sk and 
											tr.policy_transaction_type_sk not in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
										then
											(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
											-
											iif(tr.transaction_effective_dt_sk >= @month_begin_dt_sk, tr.transaction_effective_dt_sk, @month_begin_dt_sk))) 
											* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-tr.transaction_effective_dt_sk)
										 when tr.calendar_month_sk  = @month_end_dt_sk
										  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
										 then (tr.premium_amt - tr.tax_fee_surcharge_amt)
										else 0
									end
								) 
						   ) mtd_net_ep,
						sum(
								case when tr.policy_transaction_type_sk in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
										* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									  when tr.policy_transaction_type_sk not in (1,7) 
											and (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
										* (tr.premium_amt - tr.tax_fee_surcharge_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									 when tr.calendar_month_sk  = @month_end_dt_sk
									  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
									 then (tr.premium_amt - tr.tax_fee_surcharge_amt)
									else 0
								end
							) total_net_ep 
				 FROM edw_core.tpolicy_transaction tr, edw_core.tpolicy pol 
				 where isnull(tr.internal_coverage_sk,0) <> 0 
				 and  tr.policy_sk = pol.policy_sk --and pol.policy_sk in (107033)
				 and   tr.effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_dt_sk <= @end_dt_sk
				 and   tr.transaction_effective_dt_sk <> tr.expiration_dt_sk
				 and   (pol.expiration_dt > @month_begin_dt --or (tr.transaction_dt_sk - tr.expiration_dt_sk) <= 60
						) --dateadd(month,-2,@month_begin_dt)
				 group by tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.product_sk--, tr.customer_sk, tr.broker_sk, pol.source_system_sk
				)
				INSERT INTO edw_core.tinternal_coverage_summary
					( 
						month_sk, policy_sk, policy_history_sk, item_sk, internal_coverage_sk, 
						coverage_sk, vehicle_coverage_sk, customer_sk, broker_sk, product_sk, source_system_sk, 
						inforce_ct, inforce_premium_amt, inforce_net_premium_amt,
						mtd_premium_amt, mtd_commission_amt, mtd_tax_fee_surcharge_amt, mtd_net_premium_amt, 
						ytd_premium_amt, ytd_commission_amt, ytd_tax_fee_surcharge_amt, ytd_net_premium_amt, 
						itd_premium_amt, itd_commission_amt, itd_tax_fee_surcharge_amt, itd_net_premium_amt,
						annual_premium_amt, 
						annual_net_premium_amt, 
						earned_premium_amt, unearned_premium_amt, 
						earned_net_premium_amt, unearned_net_premium_amt, 
						written_exposure, earned_exposure, update_ts, etl_audit_sk
						,collection_class_type_sk
					) 
				select 	@month_end_dt_sk, prm.policy_sk, max_tr.policy_history_sk, prm.item_sk, prm.internal_coverage_sk,
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
						prm.annual_net_premium_amt, 
						prm.mtd_ep earned_premium_amt, (1.0000 * prm.itd_premium_amt)-total_ep unearned_premium_amt, 
						prm.mtd_net_ep earned_net_premium_amt, (1.0000 * prm.itd_net_premium_amt)-total_net_ep unearned_net_premium_amt, 
						isnull(xpsr_new.we,0) + isnull(xpsr_exp.we,0) + isnull(xpsr_cancel.we,0) + isnull(xpsr_rein.we,0) 
						written_exposure,
						isnull(xpsr_new.ee,0) + isnull(xpsr_exp.ee,0) + isnull(xpsr_cancel.ee,0) + isnull(xpsr_rein.ee,0) 
						earned_exposure, 
						getdate(), @etl_audit_sk
						,prm.collection_class_type_sk 
				from prm
				inner join max_tr on prm.policy_sk = max_tr.policy_sk and prm.transaction_seq_no = max_tr.transaction_seq_no
				left join inf on prm.policy_sk = inf.policy_sk and prm.item_sk = inf.item_sk and prm.internal_coverage_sk = inf.internal_coverage_sk
				left join xpsr_new on prm.policy_sk = xpsr_new.policy_sk and prm.item_sk = xpsr_new.item_sk and prm.internal_coverage_sk = xpsr_new.internal_coverage_sk
				left join xpsr_exp on prm.policy_sk = xpsr_exp.policy_sk and prm.item_sk = xpsr_exp.item_sk and prm.internal_coverage_sk = xpsr_exp.internal_coverage_sk
				left join xpsr_cancel on prm.policy_sk = xpsr_cancel.policy_sk and prm.item_sk = xpsr_cancel.item_sk and prm.internal_coverage_sk = xpsr_cancel.internal_coverage_sk
				left join xpsr_rein on prm.policy_sk = xpsr_rein.policy_sk and prm.item_sk = xpsr_rein.item_sk and prm.internal_coverage_sk = xpsr_rein.internal_coverage_sk
				where  (prm.mtd_premium_amt <> 0
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
				   or isnull(xpsr_rein.ee,0) <> 0); 
       
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

	    IF CURSOR_STATUS('global','c1_rec')>=-1
		BEGIN
		 DEALLOCATE c1_rec
		END
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
