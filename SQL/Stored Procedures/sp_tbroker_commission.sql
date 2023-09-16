-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert broker commission data 
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_commission]

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
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 

		-- Create temp table with name as tbroker_commission_temp
		
		DROP TABLE IF EXISTS edw_temp.tbroker_commission_temp

		SELECT
			tbrk.broker_id,tbrk.broker_sk,brkc.[State] AS state_cd,prd.[Name] AS product_nm,cov.[Name] AS coverage_cd,
			brkc.ProgramType AS program_type,
			brkc.BusinessType AS business_type,
			brkc.EffectiveDate AS effective_dt,dateadd(year,1,brkc.EffectiveDate) AS expiration_dt,CommissionPercent commission_pc,
			CASE brkc.IsExpired
				WHEN 1 THEN 'Active'
				WHEN 0 THEN 'Expired'
			END AS broker_commission_status,brkc.CreatedDate,brkc.UpdatedDate
		INTO edw_temp.tbroker_commission_temp
		FROM
			edw_stage.Brokerage as brk
			inner join edw_core.tbroker tbrk on brk.ProducerId=tbrk.broker_id
			inner join edw_stage.BrokerageCommission brkc on brk.Id=brkc.BrokerageId
			left join edw_stage.Product prd on brkc.ProductId=prd.Id
			left join [edw_stage].[Coverage] cov on brkc.CoverageId=cov.Id
		WHERE
			GREATEST(brkc.CreatedDate,brkc.UpdatedDate) > @last_source_extract_ts

		-- Delete from tbroker_commission table
		DELETE FROM edw_core.tbroker_commission;
		
		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tbroker_commission',RESEED,0);

		INSERT INTO edw_core.tbroker_commission
		(
			broker_id,broker_sk,state_cd,product_nm,coverage_cd,program_type,
			business_type,effective_dt,expiration_dt,commission_pc,broker_commission_status,
			create_ts,update_ts,etl_audit_sk
		)
		SELECT
			broker_id,broker_sk,state_cd,product_nm,coverage_cd,program_type,
			business_type,effective_dt,expiration_dt,commission_pc,broker_commission_status
			,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk
		FROM
			edw_temp.tbroker_commission_temp
		
		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(br.CreatedDate,br.UpdatedDate)) FROM edw_temp.tbroker_commission_temp br),@last_source_extract_ts)
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_commission_temp
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

