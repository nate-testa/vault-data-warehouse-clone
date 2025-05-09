SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ===========================================================================================================
-- Description: This procedures inserts data into tbroker_servicing_team
------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
------------------------------------------------------------------------------------------------------------
-- 05/08/05		Architha Gudimalla				1. Created the proc 
-- 05/08/05		Architha Gudimalla				2. Updated after initital run
-- 05/08/05		Architha Gudimalla				3. Added setting broker_servicing_team_sk to null in tbroker
-- =========================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_servicing_team]

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
		DROP TABLE IF EXISTS edw_temp.tbroker_servicing_team_temp

		SELECT
			bst.name broker_servicing_team_nm,
			bst.CreatedDate,bst.UpdatedDate
		INTO edw_temp.tbroker_servicing_team_temp
		FROM edw_stage.[BrokerageServicingTeam] bst
		WHERE
			GREATEST(bst.CreatedDate,bst.UpdatedDate) > @last_source_extract_ts

		update edw_core.tbroker 
		set broker_servicing_team_sk = null;

		-- Delete from tbroker_license table
		DELETE FROM edw_core.tbroker_servicing_team_member;
		DELETE FROM edw_core.tbroker_servicing_team;
		
		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tbroker_servicing_team',RESEED,0); 

		INSERT INTO edw_core.tbroker_servicing_team
		(			
			broker_servicing_team_nm, 
			create_ts, update_ts, etl_audit_sk 
		)
		SELECT
			broker_servicing_team_nm,
			@current_date AS create_ts,@current_date AS update_ts,@etl_audit_sk
		FROM
			edw_temp.tbroker_servicing_team_temp

		
		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_servicing_team_temp
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

GO