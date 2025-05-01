/****** Object:  StoredProcedure [edw_core].[sp_tcommercial_policy_summary]    Script Date: 12/5/2023 12:59:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ========================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This proceudre summarizes the policy data for each month
-----------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------
-- 04/29/25		Architha Gudimalla				1. Created this procedure  
-- ======================================================================================================================================== 

CREATE or ALTER    PROCEDURE [edw_core].[sp_tcommercial_policy_summary]
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
		where	actual_dt = @in_end_dt 
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year 
		from	edw_core.tdate
		where	actual_dt >= case when @in_end_dt is not null then @in_end_dt else @last_source_extract_ts end
		  and   actual_dt <  case when @in_end_dt is not null then @in_end_dt else cast(getdate() as date)  end
		group by yearmonth
		order by 1;  
	
		DECLARE @parameter_desc VARCHAR(255) 

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

				delete from edw_commercial.tcommercial_policy_summary
				where month_sk = @month_end_dt_sk; 

				DROP TABLE IF EXISTS edw_temp.tcommercial_policy_summary_can_rein_temp1;
				--insert cancels
				 SELECT commercial_policy_sk, policy_transaction_type_sk , transaction_seq_no 
				 into edw_temp.tcommercial_policy_summary_can_rein_temp1
				 FROM	edw_commercial.tcommercial_policy_transaction
				 where	policy_transaction_type_sk = 5
				 and   transaction_effective_dt_sk <> expiration_dt_sk
				 and	calendar_month_sk = @month_end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				 group by commercial_policy_sk, policy_transaction_type_sk, transaction_seq_no 
				 union all
				 SELECT commercial_policy_sk, policy_transaction_type_sk , transaction_seq_no 
				 FROM	edw_commercial.tcommercial_policy_transaction
				 where	policy_transaction_type_sk = 6
				 and   transaction_effective_dt_sk <> expiration_dt_sk
				 and	calendar_month_sk = @month_end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				 group by commercial_policy_sk, policy_transaction_type_sk, transaction_seq_no ; 
				DROP TABLE IF EXISTS edw_temp.tcommercial_policy_summary_max_tr;
				
				--remove the policy if its issued and cancelled in the same month, no need to adjust exposures
				delete a
				from edw_temp.tcommercial_policy_summary_can_rein_temp1 a
				inner join ( select commercial_policy_sk, 
									sum(case when policy_transaction_type_sk = 5 then 1 else 0 end) cancel_ct, 
									sum(case when policy_transaction_type_sk = 6 then 1 else 0 end) rein_ct
							from edw_temp.tcommercial_policy_summary_can_rein_temp1
							group by commercial_policy_sk) b on a.commercial_policy_sk = b.commercial_policy_sk
				where b.cancel_ct = b.rein_ct;	

				 
				DROP TABLE IF EXISTS edw_temp.tcommercial_policy_summary_max_tr;
				select commercial_policy_sk, max(transaction_seq_no) transaction_seq_no
				into edw_temp.tcommercial_policy_summary_max_tr
				from edw_commercial.tcommercial_policy_transaction 
				where effective_dt_sk <= @end_dt_sk
				and   transaction_effective_dt_sk <= @end_dt_sk
				and   transaction_dt_sk <= @end_dt_sk 
				and   expiration_dt_sk > @month_begin_dt_sk
				group by commercial_policy_sk;

				--remove the policy if the policy is issued and cancelled multiple times and the last seq no is not a rein or cancel, no need to adjust exposures
				delete  
				from a
				from edw_temp.tcommercial_policy_summary_can_rein_temp1 a
				inner join (select commercial_policy_sk 
							from edw_temp.tcommercial_policy_summary_can_rein_temp1 
				            group by commercial_policy_sk
							having count(distinct policy_transaction_type_sk) > 1) c on a.commercial_policy_sk = c.commercial_policy_sk
				where not exists (select * from edw_temp.tcommercial_policy_summary_max_tr b where a.commercial_policy_sk = b.commercial_policy_sk and a.transaction_seq_no = b.transaction_seq_no);
				 
				DROP TABLE IF EXISTS edw_temp.tcommercial_policy_summary_max_tr;
 
				
				with inf as
				(
				 SELECT commercial_policy_sk, premium_amt inforce_premium_amt
				 FROM	edw_commercial.tcommercial_daily_inforce_policy
				 where	inforce_dt_sk = @end_dt_sk
				),
				max_tr as
				(
					select commercial_policy_sk, commercial_policy_history_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
					from edw_commercial.tcommercial_policy_transaction 
					where effective_dt_sk <= @end_dt_sk
					and   transaction_effective_dt_sk <= @end_dt_sk
					and   transaction_dt_sk <= @end_dt_sk 
					group by commercial_policy_sk,commercial_policy_history_sk, customer_sk, broker_sk , product_sk, source_system_sk, transaction_seq_no
				),  
				min_tr as
				(
					select distinct commercial_policy_sk,  
							min(calendar_month_sk) over (partition by commercial_policy_sk --order by transaction_seq_no
								) calendar_month_sk,
							max(transaction_seq_no) over (partition by commercial_policy_sk) max_tr_seq_no
					from edw_commercial.tcommercial_policy_transaction 
					where effective_dt_sk <= @end_dt_sk
					and   transaction_effective_dt_sk <= @end_dt_sk
					and   transaction_dt_sk <= @end_dt_sk  
				),  
				xpsr_new as
				( 
				 SELECT tr.commercial_policy_sk,
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
							case when inf.commercial_policy_sk is not null  
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
									when (tr.transaction_dt_sk < @month_begin_dt_sk and tr.transaction_effective_dt_sk < @month_begin_dt_sk and inf.commercial_policy_sk is not null) 
									THEN 1.0*((case when tr.expiration_dt_sk > @end_dt_sk then @end_dt_sk else tr.expiration_dt_sk end
										  - 
										  @month_begin_dt_sk
										  )+1)/datediff(dd,pol.effective_dt,pol.expiration_dt ) 
									else 1.0*0
								end
							else  1.0*0
							end
						) as ee
				 FROM edw_commercial.tcommercial_policy_transaction tr
				 inner join edw_commercial.tcommercial_policy pol on tr.commercial_policy_sk = pol.commercial_policy_sk
				 left join edw_commercial.tcommercial_daily_inforce_policy inf on inf.commercial_policy_sk = pol.commercial_policy_sk and inf.inforce_dt_sk = @end_dt_sk
				 where pol.effective_dt <= @month_end_dt
				 and   pol.expiration_dt > @month_end_dt
				 and   tr.transaction_effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_dt_sk <= @end_dt_sk
				 and   tr.transaction_seq_no = (select min(tr1.transaction_seq_no) from edw_commercial.tcommercial_policy_transaction tr1 
				 								where tr1.commercial_policy_sk = tr.commercial_policy_sk)
				 and   tr.commercial_policy_transaction_sk = (select min(tr2.commercial_policy_transaction_sk) from edw_commercial.tcommercial_policy_transaction tr2 
				 								   where tr2.commercial_policy_sk = tr.commercial_policy_sk and tr2.transaction_seq_no = tr.transaction_seq_no) 
				),
				xpsr_exp as
				( 
				 SELECT pol.commercial_policy_sk,
						0 we,
						1.0*(datediff(dd,@month_begin_dt,pol.expiration_dt))/datediff(dd,pol.effective_dt,pol.expiration_dt )  as ee
				 FROM edw_commercial.tcommercial_policy pol, edw_commercial.tcommercial_daily_inforce_policy inf
				 where inf.commercial_policy_sk = pol.commercial_policy_sk 
				   and inf.inforce_dt_sk = @prev_month_end_dt_sk
				   and pol.expiration_dt between  @month_begin_dt AND @month_end_dt
				   and not exists (select commercial_policy_sk from edw_temp.tcommercial_policy_summary_can_rein_temp1 c where pol.commercial_policy_sk = c.commercial_policy_sk and c.policy_transaction_type_sk = 5)
				),
				xpsr_cancel as
				( 
					 select commercial_policy_sk , sum(we) we, sum(ee) ee
					 from
					 (
						 SELECT distinct tr.commercial_policy_sk, tr.transaction_seq_no,
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
						 FROM edw_commercial.tcommercial_policy_transaction tr
						 inner join edw_commercial.tcommercial_policy pol on tr.commercial_policy_sk = pol.commercial_policy_sk
						 left join min_tr on min_tr.commercial_policy_sk = pol.commercial_policy_sk  
						 --inner join min_tr max_tr on max_tr.commercial_policy_sk = tr.commercial_policy_sk and max_tr.max_tr_seq_no = tr.transaction_seq_no  
						 where exists (select commercial_policy_sk from edw_temp.tcommercial_policy_summary_can_rein_temp1 c where tr.commercial_policy_sk = c.commercial_policy_sk and tr.transaction_seq_no = c.transaction_seq_no and c.policy_transaction_type_sk = 5)
						 and	tr.policy_transaction_type_sk = 5   
						 and tr.calendar_month_sk = @month_end_dt_sk
					) aa
					group by commercial_policy_sk
												 	
				),
				xpsr_rein as
				( 
					 select commercial_policy_sk , sum(we) we, sum(ee) ee
					 from
					 (
						 SELECT distinct tr.commercial_policy_sk, transaction_seq_no,
		 						(
									1.0*(((select date_sk from edw_core.tdate where actual_dt = pol.expiration_dt) - tr.transaction_effective_dt_sk))/datediff(dd,pol.effective_dt,pol.expiration_dt )  
								) we,
								case when inf.commercial_policy_sk is not null  
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
									 when inf.commercial_policy_sk is null and tr.expiration_dt_sk between @month_begin_dt_sk and @month_end_dt_sk 
									 then  1.0*(tr.expiration_dt_sk-tr.transaction_effective_dt_sk)/datediff(dd,pol.effective_dt,pol.expiration_dt )
								else 0
								end ee
						 FROM edw_commercial.tcommercial_policy_transaction tr
						 inner join edw_commercial.tcommercial_policy pol on tr.commercial_policy_sk = pol.commercial_policy_sk
						 left join edw_commercial.tcommercial_daily_inforce_policy inf on inf.commercial_policy_sk = pol.commercial_policy_sk and inf.inforce_dt_sk = @end_dt_sk
						 --inner join min_tr max_tr on max_tr.commercial_policy_sk = tr.commercial_policy_sk and max_tr.max_tr_seq_no = tr.transaction_seq_no 
						 where exists (select commercial_policy_sk from edw_temp.tcommercial_policy_summary_can_rein_temp1 r where tr.commercial_policy_sk = r.commercial_policy_sk and tr.transaction_seq_no = r.transaction_seq_no and r.policy_transaction_type_sk = 6)
						 and	tr.policy_transaction_type_sk = 6
						 and tr.calendar_month_sk = @month_end_dt_sk 
					) aa
					group by commercial_policy_sk
				),
				prm as
				(
				 SELECT tr.commercial_policy_sk,  --tr.customer_sk, tr.broker_sk, tr.product_sk, pol.source_system_sk,
				 		max(tr.transaction_seq_no) transaction_seq_no,
		 				sum(case when tr.calendar_month_sk = @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) mtd_premium_amt,
		 				sum(case when tr.calendar_month_sk = @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) mtd_commission_amt,
		 				sum(case when tr.calendar_month_sk = @month_end_dt_sk THEN tr.premium_amt - tr.commission_amt ELSE 0 END) mtd_net_premium_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.premium_amt ELSE 0 END) ytd_premium_amt,
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.commission_amt ELSE 0 END) ytd_commission_amt, 
		 				sum(case when tr.calendar_month_sk between @year_begin_sk AND @month_end_dt_sk THEN tr.premium_amt - tr.commission_amt ELSE 0 END) ytd_net_premium_amt,
		 				sum(tr.premium_amt) itd_premium_amt,
		 				sum(tr.commission_amt) itd_commission_amt,
		 				sum(tr.premium_amt - tr.commission_amt) itd_net_premium_amt,
						sum(annual_premium_amt) annual_premium_amt,
						sum(annual_premium_amt-commission_amt) annual_net_premium_amt,
		 				sum(
		 						(--for transactions issued in the month, eff in the month or later
									case when tr.expiration_dt_sk > @month_begin_dt_sk and 
											(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
											greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
										* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									 when tr.calendar_month_sk  = @month_end_dt_sk
									  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
									 then tr.premium_amt
									else 0
									end
								) 
						   ) mtd_ep,
						sum(
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
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
											(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
									then
										(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
										-
										iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
											greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
										* (tr.premium_amt - tr.commission_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
									 when tr.calendar_month_sk  between @month_begin_dt_sk  and @month_end_dt_sk
									  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
									 then (tr.premium_amt - tr.commission_amt)
									else 0
									end
								) 
						   ) mtd_net_ep,
						sum(
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
								then
									(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
									* (tr.premium_amt - tr.commission_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								 when tr.calendar_month_sk  between @month_begin_dt_sk  and @month_end_dt_sk
								  and tr.expiration_dt_sk <= @month_begin_dt_sk and (tr.transaction_dt_sk - tr.expiration_dt_sk) between 1 and 60
								 then (tr.premium_amt - tr.commission_amt)
								else 0
								end
							) total_net_ep/*, 
		 				sum(
		 					(--for transactions issued in the month, eff in the month or later
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
								then
									(1+(iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									iif(greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk) >= @month_begin_dt_sk, 
										greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk), @month_begin_dt_sk))) 
									* (tr.premium_amt - tr.commission_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
							)
						   ) mtd_net_ep,
						sum(
								case when (tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) <> 0
								then
									(1+iif(tr.expiration_dt_sk > @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
									-
									greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) 
									* (tr.premium_amt - tr.commission_amt)/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
								else 0
								end
							) total_net_ep*/
				 FROM edw_commercial.tcommercial_policy_transaction tr, edw_commercial.tcommercial_policy pol 
				 where tr.commercial_policy_sk = pol.commercial_policy_sk --and pol.commercial_policy_sk in (107033)
				 and   tr.effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_effective_dt_sk <= @end_dt_sk
				 and   tr.transaction_dt_sk <= @end_dt_sk
				 and   tr.transaction_effective_dt_sk <> tr.expiration_dt_sk
				 and   (pol.expiration_dt > @month_begin_dt --or (tr.transaction_dt_sk - tr.expiration_dt_sk) <= 60
						) --dateadd(month,-2,@month_begin_dt)
				 group by tr.commercial_policy_sk --, tr.customer_sk, tr.broker_sk, tr.product_sk, pol.source_system_sk
				)
				INSERT INTO  edw_commercial.tcommercial_policy_summary
					( 
						month_sk, commercial_policy_sk,  customer_sk, broker_sk, product_sk, source_system_sk, 
						inforce_ct, inforce_premium_amt, inforce_net_premium_amt,
						mtd_premium_amt, mtd_commission_amt, mtd_net_premium_amt, 
						ytd_premium_amt, ytd_commission_amt, ytd_net_premium_amt, 
						itd_premium_amt, itd_commission_amt, itd_net_premium_amt,
						annual_premium_amt, 
						earned_premium_amt, unearned_premium_amt, 
						earned_net_premium_amt, unearned_net_premium_amt, 
						written_exposure, earned_exposure, update_ts, etl_audit_sk
					)
				select 	@month_end_dt_sk, prm.commercial_policy_sk, max_tr.customer_sk, max_tr.broker_sk, max_tr.product_sk, max_tr.sourcE_system_sk, 
						iif(inf.commercial_policy_sk is null,0,1) inforce_ct, 
						iif(inf.commercial_policy_sk is null,0,inf.inforce_premium_amt) inforce_premium_amt, 
						iif(inf.commercial_policy_sk is null,0,inf.inforce_premium_amt-itd_commission_amt) inforce_net_premium_amt, 
						prm.mtd_premium_amt, prm.mtd_commission_amt, prm.mtd_net_premium_amt, 
						prm.ytd_premium_amt, prm.ytd_commission_amt, prm.ytd_net_premium_amt, 
						prm.itd_premium_amt, prm.itd_commission_amt,  prm.itd_net_premium_amt,
						prm.annual_premium_amt, 
						prm.mtd_ep earned_premium_amt, (1.0000 * prm.itd_premium_amt)-total_ep unearned_premium_amt, 
						prm.mtd_net_ep earned_net_premium_amt, (1.0000 * prm.itd_net_premium_amt)-total_net_ep unearned_net_premium_amt, 
						isnull(xpsr_new.we,0) + isnull(xpsr_exp.we,0) + isnull(xpsr_cancel.we,0) + isnull(xpsr_rein.we,0) 
						written_exposure,
						isnull(xpsr_new.ee,0) + isnull(xpsr_exp.ee,0) + isnull(xpsr_cancel.ee,0) + isnull(xpsr_rein.ee,0) 
						earned_exposure, 
						getdate(), @etl_audit_sk
				from prm
				inner join max_tr on prm.commercial_policy_sk = max_tr.commercial_policy_sk and prm.transaction_seq_no = max_tr.transaction_seq_no
				left join inf on prm.commercial_policy_sk = inf.commercial_policy_sk
				left join xpsr_new on prm.commercial_policy_sk = xpsr_new.commercial_policy_sk
				left join xpsr_exp on prm.commercial_policy_sk = xpsr_exp.commercial_policy_sk
				left join xpsr_cancel on prm.commercial_policy_sk = xpsr_cancel.commercial_policy_sk
				left join xpsr_rein on prm.commercial_policy_sk = xpsr_rein.commercial_policy_sk
				where prm.mtd_premium_amt <> 0
				   or prm.mtd_commission_amt <> 0 
				   or prm.mtd_net_premium_amt <> 0
				  or prm.ytd_premium_amt <> 0
				   or prm.ytd_commission_amt <> 0 
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

				DROP TABLE IF EXISTS edw_temp.tcommercial_policy_summary_can_rein_temp1;
				 
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
