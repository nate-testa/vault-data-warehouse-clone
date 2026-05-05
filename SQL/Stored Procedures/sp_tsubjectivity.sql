-- =================================================================================================
-- Description: This stored procedure insert and update GRPEL participants
---------------------------------------------------------------------------------------------------
-- Change date 	|Author					|	Change Description
---------------------------------------------------------------------------------------------------
-- 05/05/26		Yunus Mohammed		    1. Created the proc
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tsubjectivity]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tsubjectivity_temp1;

        SELECT 
			accg.PolicyNumber as grpel_master_policy_no,
			acc.PolicyNumber as policy_no,
			giep.Id as grpel_participant_id,
			giep.FirstName as first_nm,
			giep.LastName as last_nm,
			giep.Email as email,
			giep.Tier as tier_type,
			giep.EnrollmentStatus as enrollment_status,
			case
				when giep.IsDeleted = 1 then 'Yes'
				when giep.IsDeleted = 0 then 'No'
			end as deleted_in,
			case when acc.ExternalSourceId is not NULL 
				then 2 --(AV2) 
				Else 4 --(Metal)
			end source_system_sk,
			GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk etl_audit_sk,
			giep.CreatedDate,giep.UpdatedDate
		INTO edw_temp.tgrpel_participant_temp1
		FROM
			edw_stage.GroupInsurance gi
			inner join edw_stage.Account accg on accg.Id= gi.GroupAccountId
			inner join edw_stage.GroupInsuranceEnrollmentParticipant giep on giep.GroupInsuranceId = gi.Id
			left join edw_stage.Account acc on giep.AccountId = acc.Id
		WHERE
		 	GREATEST(giep.CreatedDate,giep.UpdatedDate) > @last_source_extract_ts

		-- Start Merge process
		MERGE edw_core.tgrpel_participant AS [Target]
		USING edw_temp.tgrpel_participant_temp1 [Source]
		ON Source.grpel_participant_id = [Target].grpel_participant_id
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT 
		(
			grpel_master_policy_no,policy_no,grpel_participant_id,first_nm,last_nm,email,tier_type,
            enrollment_status,deleted_in,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		VALUES 
		(
			grpel_master_policy_no,policy_no,grpel_participant_id,first_nm,last_nm,email,tier_type,
            enrollment_status,deleted_in,source_system_sk,create_ts,update_ts,etl_audit_sk			
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET       		
			[Target].policy_no = [Source].policy_no,            
            [Target].first_nm = [Source].first_nm,
            [Target].last_nm = [Source].last_nm,
            [Target].email = [Source].email,
            [Target].tier_type = [Source].tier_type,
            [Target].enrollment_status = [Source].enrollment_status,
            [Target].deleted_in = [Source].deleted_in,
			[Target].update_ts = [Source].update_ts;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate, UpdatedDate)) FROM edw_temp.tgrpel_participant_temp1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tgrpel_participant_temp1;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;


	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END