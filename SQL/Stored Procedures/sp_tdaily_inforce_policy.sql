-- =================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedures loads inforce data at policy level 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/16/23		Architha Gudimalla				1. Created this procedure 
-- 02/07/24		Architha Gudimalla				2. Added annual net prm  
-- 03/20/24		Architha Gudimalla				3. Added commission_amt
-- 07/03/24		Yunus Mohammed					4. Added policy_history_sk
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tdaily_inforce_policy]
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
		where	actual_dt >  case when @in_inforce_dt is not null then @in_inforce_dt else @last_source_extract_ts end
		  and   actual_dt <= case when @in_inforce_dt is not null then @in_inforce_dt else getdate() end 
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
		
				delete from edw_core.tdaily_inforce_policy
				where inforce_dt_sk = @var_date_sk;
				
				with max_tr as
				(
				 SELECT policy_sk,
						policy_transaction_sk,
						row_number() over (partition by policy_sk order by transaction_seq_no desc, policy_transaction_sk desc) rnk,
				 		sum(premium_amt) over (partition by policy_sk) prm,
				 		sum(annual_premium_amt) over (partition by policy_sk) ann_prm,
				 		sum(case when tax_fee_surcharge_sk = 0 then annual_premium_amt else 0 end) over (partition by policy_sk) annual_net_premium_amt,
				 		sum(tax_fee_surcharge_amt) over (partition by policy_sk) tfs,
				 		sum(commission_amt) over (partition by policy_sk) commission_amt
				 FROM edw_core.tpolicy_transaction 
				 where effective_dt_sk <= @var_date_sk
				 and   transaction_effective_dt_sk <= @var_date_sk
				 and   transaction_dt_sk <= @var_date_sk 
				)
				INSERT INTO edw_core.tdaily_inforce_policy
					( 
						policy_sk, policy_history_sk, customer_sk, broker_sk, product_sk, source_system_sk, inforce_dt_sk, 
						premium_amt, annual_premium_amt, net_premium_amt , update_ts, etl_audit_sk
						,annual_net_premium_amt
						,commission_amt
			        )
			    select 	tr.policy_sk, tr.policy_history_sk, tr.customer_sk, tr.broker_sk, tr.product_sk, tr.sourcE_system_sk, 
						@var_date_sk, 
						max_tr.prm, max_tr.ann_prm, max_tr.prm-max_tr.tfs, getdate(), @etl_audit_sk
						,max_tr.annual_net_premium_amt
						,max_tr.commission_amt
				from  edw_core.tpolicy_transaction tr, edw_core.tpolicy_transaction_type tt, max_tr
				where tr.policy_transaction_type_sk = tt.policy_transaction_type_sk
				  and tr.policy_sk = max_tr.policy_sk
				  and tr.policy_transaction_sk = max_tr.policy_transaction_sk
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
