SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert broker vault team data 
---------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_vault_team]

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
		DROP TABLE IF EXISTS edw_temp.tbroker_vault_team_temp

		SELECT
			tbrk.broker_id,tbrk.broker_sk,tpr.product_nm AS product_nm,
			brkctm.[State] AS state_cd,brkctm.ProgramType AS program_type,
			brkctm.TeamMemberType AS team_member_type,u.name as team_member_nm,
			brkctm.CreatedDate,brkctm.UpdatedDate
			,tpr.product_sk
		INTO edw_temp.tbroker_vault_team_temp
		FROM
			edw_stage.Brokerage as brk
			inner join edw_core.tbroker tbrk on CAST(brk.ProducerId AS VARCHAR(255)) = tbrk.broker_id
			inner join edw_stage.BrokerageCompanyTeamMember brkctm on brk.Id=brkctm.BrokerageId
			left join edw_stage.Product prd on brkctm.ProductId=prd.Id
			left join edw_core.tproduct tpr on tpr.product_cd=prd.ProductCode
			left join edw_stage.[User] u on brkctm.UserId=u.id
		WHERE
			GREATEST(brkctm.CreatedDate,brkctm.UpdatedDate) > @last_source_extract_ts

		-- Delete from tbroker_license table
		DELETE FROM edw_core.tbroker_vault_team;
		
		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tbroker_vault_team',RESEED,0);

		INSERT INTO edw_core.tbroker_vault_team
		(			
			broker_id,broker_sk,state_cd,product_nm,program_type,team_member_type,
			team_member_nm,create_ts,update_ts,etl_audit_sk,product_sk
		)
		SELECT
			broker_id,broker_sk,state_cd,product_nm,program_type,team_member_type,
			team_member_nm,@current_date AS create_ts,@current_date AS update_ts,@etl_audit_sk,product_sk
		FROM
			edw_temp.tbroker_vault_team_temp

		
		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_vault_team_temp
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