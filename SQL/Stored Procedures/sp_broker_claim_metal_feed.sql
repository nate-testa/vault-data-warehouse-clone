
-- ==================================================================================================================================================
-- Author:		Yunus Mohammed
-- Description: This proceudre inserts broker claim feed
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						            |	Change Description 
---------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/03/25		Yunus Mohammed				1. Created this procedure
-- 09/05/25		Yunus Mohammed				2. loss_ratio rounded to 2 decimal
-- ================================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_broker_claim_metal_feed]
AS 
BEGIN
	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
		truncate table edw_integration.broker_claim_metal_feed;				
       
		select
		b.broker_id,		
		 round(case when sum(bs.one_year_earned_net_premium_amt) = 0 then 0 
								else 100.0*sum(bs.one_year_loss_incurred_amt)/sum(bs.one_year_earned_net_premium_amt) 
		end,2) as loss_ratio
		into edw_temp.broker_claim_metal_feed_temp
		from 
		edw_core.tbroker_summary bs
		inner join edw_core.tbroker b on bs.broker_sk = b.broker_sk
		where
		bs.month_sk = (
						select max(month_sk) 
						from edw_core.tbroker_summary bs1
						)
		group by broker_id

		SET @rows_affected=0;
		INSERT INTO edw_integration.broker_claim_metal_feed
			(	
				broker_id, loss_ratio,create_ts,update_ts, etl_audit_sk
			)
		select 
				broker_id,
				loss_ratio,
				getdate() as create_ts,
				getdate() as update_ts, 
				@etl_audit_sk as etl_audit_sk
		from edw_temp.broker_claim_metal_feed_temp
       
		SET @rows_affected=@@ROWCOUNT;
				
		-- Update control table
		SET @new_last_source_extract_ts=getdate();	
			
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts; 

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;    

		DROP TABLE IF EXISTS edw_temp.broker_claim_metal_feed_temp;
		
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
