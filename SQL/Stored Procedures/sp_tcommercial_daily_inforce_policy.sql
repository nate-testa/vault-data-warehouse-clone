-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedures loads inforce data at policy level 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/29/25		Architha Gudimalla				1. Created this procedure  
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_daily_inforce_policy]
@in_inforce_dt DATE = null
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
		select	date_sk, actual_dt
		from	edw_core.tdate
		where	actual_dt = @in_inforce_dt  
		union 
		select	date_sk, actual_dt
		from	edw_core.tdate
		where	actual_dt >= case when @in_inforce_dt is not null then @in_inforce_dt else @last_source_extract_ts end
		  and   actual_dt <  case when @in_inforce_dt is not null then @in_inforce_dt else cast(getdate() as date) end  
		order by 1; 
		
		DECLARE @inforce_dt DATETIME
		DECLARE @var_date_sk INT
		DECLARE @parameter_desc VARCHAR(255) 
		
		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @var_date_sk, @inforce_dt; 
		WHILE @@FETCH_STATUS = 0
			BEGIN  
	
				EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
				
				-- Get last source extract date
				SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
			
				sET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
				delete from edw_commercial.tcommercial_tdaily_inforce_policy
				where inforce_dt_sk = @var_date_sk; 
				
				with max_tr as
				(
				 SELECT commercial_policy_sk,
						commercial_policy_transaction_sk,
						row_number() over (partition by commercial_policy_sk order by transaction_seq_no desc, commercial_policy_transaction_sk desc) rnk,
				 		sum(premium_amt) 						over (partition by commercial_policy_sk) prm,
				 		sum(annual_premium_amt) 				over (partition by commercial_policy_sk) ann_prm,
				 		sum(annual_premium_amt-commission_amt) 	over (partition by commercial_policy_sk) annual_net_premium_amt,
				 		sum(commission_amt) 					over (partition by commercial_policy_sk) commission_amt
				 FROM edw_commercial.tcommercial_policy_transaction 
				 where effective_dt_sk <= @var_date_sk
				 and   transaction_effective_dt_sk <= @var_date_sk
				 and   transaction_dt_sk <= @var_date_sk 
				)
				INSERT INTO edw_commercial.tcommercial_tdaily_inforce_policy
					( 
						commercial_policy_sk, commercial_policy_history_sk, customer_sk, broker_sk, product_sk, source_system_sk, inforce_dt_sk, 
						premium_amt, annual_premium_amt, net_premium_amt , update_ts, etl_audit_sk
						,annual_net_premium_amt
						,commission_amt
			        )
			    select 	tr.commercial_policy_sk, tr.commercial_policy_history_sk, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.sourcE_system_sk, 
						@var_date_sk, 
						max_tr.prm, max_tr.ann_prm, max_tr.prm-max_tr.commission_amt, getdate(), @etl_audit_sk
						,max_tr.annual_net_premium_amt
						,max_tr.commission_amt
				from  edw_commercial.tcommercial_policy_transaction tr, edw_core.tpolicy_transaction_type tt, max_tr
				where tr.policy_transaction_type_sk = tt.policy_transaction_type_sk
				  and tr.commercial_policy_sk = max_tr.commercial_policy_sk
				  and tr.commercial_policy_transaction_sk = max_tr.commercial_policy_transaction_sk
				  and tt.policy_transaction_type_nm <> 'Cancellation'
				  and expiration_dt_sk > @var_date_sk
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
				 
				FETCH NEXT FROM c1_rec INTO @var_date_sk, @inforce_dt;
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
