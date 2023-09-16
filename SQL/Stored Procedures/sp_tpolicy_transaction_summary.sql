
-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedure summarizes data at the internal coverages level for each month
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 08/30/23		Architha Gudimalla				1. Created this procedure  
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_transaction_summary]
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

				delete from edw_core.tpolicy_transaction_summary 
				where month_sk = @month_end_dt_sk; 
			
				with
				prm as
				(
				 SELECT tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.transaction_seq_no, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk,
						tr.effective_dt_sk,
						tr.transaction_effective_dt_sk,
						tr.expiration_dt_sk,
						tr.transaction_dt_sk,
						tr.policy_transaction_type_sk, 
						max(tr.coverage_sk) coverage_sk,
		 				sum(tr.premium_amt) premium_amt,
		 				sum(
		 					--for transactions issued in the month, eff in the month or later
							 	(1+(iif(tr.expiration_dt_sk >= @end_dt_sk, @end_dt_sk, (tr.expiration_dt_sk-1))
								- (greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk)) ))
								* tr.premium_amt/(tr.expiration_dt_sk-greatest(tr.transaction_dt_sk, tr.transaction_effective_dt_sk))
							
						   ) mtd_ep 
				 FROM edw_core.tpolicy_transaction tr, edw_core.tpolicy pol 
				 where tr.policy_sk = pol.policy_sk
				 and 	tr.internal_coverage_sk <> 0 
				 and   effective_dt_sk <= @end_dt_sk
				 and   transaction_effective_dt_sk <= @end_dt_sk
				 and   transaction_dt_sk <= @end_dt_sk
				 and   expiration_dt > @month_begin_dt
				 group by tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.transaction_seq_no, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.source_system_sk,
						tr.effective_dt_sk,
						tr.transaction_effective_dt_sk,
						tr.expiration_dt_sk,
						tr.transaction_dt_sk,
						tr.policy_transaction_type_sk
				)
				INSERT INTO edw_core.tpolicy_transaction_summary
					( 
						month_sk, policy_sk, item_sk, transaction_seq_no, internal_coverage_sk, coverage_sk, customer_sk, broker_sk, product_sk, 
						effective_dt_sk,
						transaction_effective_dt_sk,
						expiration_dt_sk,
						transaction_dt_sk,
						policy_transaction_type_sk, premium_amt,  
						earned_premium_amt, unearned_premium_amt,  source_system_sk, update_ts, etl_audit_sk
					)
				select 	@month_end_dt_sk, prm.policy_sk, prm.item_sk, prm.transaction_seq_no,  prm.internal_coverage_sk,
						prm.coverage_sk, 
						prm.customer_sk, prm.broker_sk, prm.product_sk,  
						prm.effective_dt_sk,
						prm.transaction_effective_dt_sk,
						prm.expiration_dt_sk,
						prm.transaction_dt_sk,
						prm.policy_transaction_type_sk, prm.premium_amt,  
						prm.mtd_ep earned_premium_amt, (1.0000 * prm.premium_amt)-mtd_ep unearned_premium_amt, 
						source_system_sk, getdate(), @etl_audit_sk
				from prm
				where prm.premium_amt <> 0
				   or prm.mtd_ep <> 0;
       
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
