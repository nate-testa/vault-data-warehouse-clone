-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedures loads inforce at internal coverage level 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/18/23		Architha Gudimalla				1. Created this procedure 
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tinternal_coverage_inforce]
@in_inforce_dt DATETIME = null
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
		
		DECLARE c1_rec CURSOR
		FOR  
		select	yearmonth, max(calendar_year) year, max(date_sk) date_sk, max(actual_dt) actual_dt
		from	edw_core.tdate
		where	actual_dt = @in_inforce_dt 
		group by yearmonth
		union 
		select	yearmonth, max(calendar_year) year, max(date_sk) date_sk, max(actual_dt) actual_dt 
		from	edw_core.tdate
		where	actual_dt >  case when @in_inforce_dt is not null then @in_inforce_dt else @last_source_extract_ts end
		  and   actual_dt <= case when @in_inforce_dt is not null then @in_inforce_dt else getdate() end
		group by yearmonth
		order by 1;  

		DECLARE @inforce_dt DATETIME
		DECLARE @yearmonth INT
		DECLARE @year INT
		DECLARE @parameter_desc VARCHAR(255) 
		DECLARE @var_date_sk INT
		DECLARE @month_end_sk INT
		
		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @yearmonth, @year, @var_date_sk, @inforce_dt; 
		WHILE @@FETCH_STATUS = 0
		BEGIN

				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT; 
			
				-- Get last source extract date
				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
				
				SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

				set @month_end_sk = (select max(date_sk) from edw_core.tdate where yearmonth = @yearmonth);

				delete from edw_core.tinternal_coverage_inforce 
				where month_sk = @month_end_sk; 
				
				with max_tr as
				(
				 SELECT policy_sk, item_sk, internal_coverage_sk ,
						policy_transaction_sk, coverage_sk , vehicle_coverage_sk ,
						row_number() over (partition by policy_sk,item_sk, internal_coverage_sk order by transaction_seq_no desc, policy_transaction_sk desc) rnk,
						sum(premium_amt) over (partition by policy_sk, item_sk, internal_coverage_sk) prm,
				 		sum(annual_premium_amt) over (partition by policy_sk, item_sk, internal_coverage_sk) ann_prm,
				 		sum(tax_fee_surcharge_amt) over (partition by policy_sk, item_sk, internal_coverage_sk) tfs
				 FROM edw_core.tpolicy_transaction 
				 where effective_dt_sk <= @var_date_sk
				 and   transaction_effective_dt_sk <= @var_date_sk
				 and   transaction_dt_sk <= @var_date_sk 
				)
				INSERT INTO edw_core.tinternal_coverage_inforce
					( 
						policy_sk, item_sk, internal_coverage_sk, coverage_sk, vehicle_coverage_sk, customer_sk, broker_sk, product_sk, source_system_sk, month_sk, 
						premium_amt, net_premium_amt, annual_premium_amt, update_ts, etl_audit_sk
			        )
			    select 	tr.policy_sk, tr.item_sk, tr.internal_coverage_sk, tr.coverage_sk, tr.vehicle_coverage_sk, 
			    		tr.customer_sk, tr.broker_sk, tr.product_sk, tr.sourcE_system_sk, 
						@month_end_sk, 
						max_tr.prm, (max_tr.prm - max_tr.tfs), max_tr.ann_prm, getdate(), @etl_audit_sk
				from  edw_core.tpolicy_transaction tr, max_tr
				where tr.policy_sk = max_tr.policy_sk
				  and tr.item_sk = max_tr.item_sk
				  and tr.internal_coverage_sk = max_tr.internal_coverage_sk
				  and tr.policy_transaction_sk = max_tr.policy_transaction_sk
				  and tr.policy_transaction_type_sk <> 5
				  and tr.internal_coverage_sk <> 0
				  and tr.expiration_dt_sk > @var_date_sk
				  and max_tr.rnk = 1;
		       
				SET @rows_affected=@@ROWCOUNT;
		
				--Update control table
				SET @new_last_source_extract_ts = COALESCE(@inforce_dt,@last_source_extract_ts);  
				if @in_inforce_dt is not null
				begin
					set @new_last_source_extract_ts= @last_source_extract_ts
				end 
				EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
				-- Update audit table
				SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
				if @in_inforce_dt is not null
				begin
					set @parameter_desc= 'last_source_extract_ts = ' + CAST(@in_inforce_dt AS VARCHAR(200))
				end 
				EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;  
				 
				FETCH NEXT FROM c1_rec INTO @yearmonth, @year, @var_date_sk, @inforce_dt;
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
