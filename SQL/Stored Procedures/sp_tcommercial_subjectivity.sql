-- =================================================================================================
-- Description: This stored procedure insert and update Subjectivity data for Commercial Line
---------------------------------------------------------------------------------------------------
-- Change date 	|Author					|	Change Description
---------------------------------------------------------------------------------------------------
-- 05/05/26		Yunus Mohammed		    1. Created the proc
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_subjectivity]
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
		DROP TABLE IF EXISTS edw_temp.tcommercial_subjectivity_temp1;

        SELECT
            acc.[Number] as quote_no,
            acc.EffectiveDate as effective_dt,
            acc.ExpirationDate as expiration_dt,
            accs.Id as subjectivity_id,
            accs.CreatedDate as subjectivity_created_ts,
            accs.UpdatedDate as subjectivity_updated_ts,
            accs.[Required] as required_for,
            accs.[Description] as subjectivity_desc,
            case
            when accs.IsCompleted = 1 then 'Yes'
            when accs.IsCompleted = 0 then 'No'
            end as completed_in,
            case
            when accs.IsSignaturePackage = 1 then 'Yes'
            when accs.IsSignaturePackage = 0 then 'No'
            end as signature_package_in,
            case
            when accs.IsUploadRequired = 1 then 'Yes'
            when accs.IsUploadRequired = 0 then 'No'
            end as upload_required_in,
            case
            when accs.IsSignatureDocument = 1 then 'Yes'
            when accs.IsSignatureDocument = 0 then 'No'
            end as signature_document_in,
            case
            when accs.AddedByRule = 1 then 'Yes'
            when accs.AddedByRule = 0 then 'No'
            end as added_by_rule_in,
            case
            when accs.IsCritical = 1 then 'Yes'
            when accs.IsCritical = 0 then 'No'
            end as critical_in,
            case
            when accs.IsDeleted = 1 then 'Yes'
            when accs.IsDeleted = 0 then 'No'
            end as deleted_in,
            CONCAT_WS(ua.first_nm, ' ', ua.last_nm) as added_by_user_nm,
            CONCAT_WS(uc.first_nm, ' ', uc.last_nm) as completed_by_user_nm,
            acc.CreatedDate,
            acc.UpdatedDate,
            GETDATE() as create_ts,
            GETDATE() as update_ts,
            @etl_audit_sk as etl_audit_sk,
            case when acc.ExternalSourceId is not NULL 
            then 2 --(AV2) 
            Else 4 --(Metal)
            end source_system_sk
        INTO edw_temp.tcommercial_subjectivity_temp1
        FROM
            edw_stage.Account acc
            INNER JOIN edw_stage.Product pr on acc.ProductId = pr.id
            INNER JOIN edw_stage.AccountSubjectivity accs on acc.Id= accs.AccountId
            LEFT JOIN edw_core.[tuser] ua on ua.[user_id] = accs.AddedByUserId
            LEFT JOIN edw_core.[tuser] uc on uc.[user_id] = accs.CompletedByUserId
        WHERE
            pr.ProductLine = 'CommercialLines' AND
            GREATEST(accs.CreatedDate, accs.UpdatedDate) >  @last_source_extract_ts

		-- Start Merge process
		MERGE edw_commercial.tcommercial_subjectivity AS [Target]
		USING edw_temp.tcommercial_subjectivity_temp1 [Source]
		ON [Source].subjectivity_id = [Target].subjectivity_id
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT 
		(
            quote_no,effective_dt,expiration_dt,subjectivity_id,subjectivity_created_ts,subjectivity_updated_ts,
            required_for,subjectivity_desc,completed_in,signature_package_in,upload_required_in,signature_document_in,
            added_by_rule_in,deleted_in,added_by_user_nm,completed_by_user_nm,critical_in,
            create_ts,update_ts,etl_audit_sk,source_system_sk
		)
		VALUES 
		(
            quote_no,effective_dt,expiration_dt,subjectivity_id,subjectivity_created_ts,subjectivity_updated_ts,
            required_for,subjectivity_desc,completed_in,signature_package_in,upload_required_in,signature_document_in,
            added_by_rule_in,deleted_in,added_by_user_nm,completed_by_user_nm,critical_in,
            create_ts,update_ts,etl_audit_sk,source_system_sk		
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET	
            [Target].subjectivity_updated_ts = [Source].subjectivity_updated_ts,
            [Target].required_for = [Source].required_for,
            [Target].subjectivity_desc = [Source].subjectivity_desc,
            [Target].completed_in = [Source].completed_in,
            [Target].signature_package_in = [Source].signature_package_in,
            [Target].upload_required_in = [Source].upload_required_in,
            [Target].signature_document_in = [Source].signature_document_in,
            [Target].added_by_rule_in = [Source].added_by_rule_in,
            [Target].deleted_in= [Source].deleted_in,
            [Target].added_by_user_nm = [Source].added_by_user_nm,
            [Target].completed_by_user_nm = [Source].completed_by_user_nm,
            [Target].critical_in = [Source].critical_in,
            [Target].update_ts = [Source].update_ts;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate, UpdatedDate)) FROM edw_temp.tcommercial_subjectivity_temp1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tcommercial_subjectivity_temp1;
		
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