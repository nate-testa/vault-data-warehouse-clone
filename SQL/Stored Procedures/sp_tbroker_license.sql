-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert broker license data 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/20/25		Dinesh Bobbili				1. AD-9795 Added license_type column
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_license]

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

		-- Create temp table with name as tbroker_license_temp
		DROP TABLE IF EXISTS edw_temp.tbroker_license_temp

		SELECT
			tbrk.broker_id,tbrk.broker_sk,
			brkl.StateCode as state_cd,brkl.License AS license_no,brkl.ExpirationDate AS expiration_dt,
			brkl.HolderName AS licenseholder_nm,brkl.ResidencyCode AS residency_status,brkl.licenseCategory AS category_nm,brkl.LicenseType AS license_type,
			brkl.CreatedDate,brkl.UpdatedDate
		INTO edw_temp.tbroker_license_temp
		FROM
			edw_stage.Brokerage as brk
			inner join edw_core.tbroker tbrk on CAST(brk.ProducerId AS VARCHAR(255))=tbrk.broker_id
			inner join edw_stage.BrokerageLicense brkl on brk.Id=brkl.BrokerageId
		WHERE
			GREATEST(brkl.CreatedDate,brkl.UpdatedDate) > @last_source_extract_ts

		-- Delete from tbroker_license table
		DELETE FROM edw_core.tbroker_license;
		
		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tbroker_license',RESEED,0);

		INSERT INTO edw_core.tbroker_license
		(			
			broker_id,broker_sk,state_cd,license_no,expiration_dt,licenseholder_nm,residency_status,category_nm,license_type,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			broker_id,broker_sk,state_cd,license_no,expiration_dt,licenseholder_nm,residency_status,category_nm,license_type,
			@current_date AS create_ts,@current_date AS update_ts,@etl_audit_sk
		FROM
			edw_temp.tbroker_license_temp

		
		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_license_temp
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

