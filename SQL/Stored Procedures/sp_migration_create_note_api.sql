/****** Object:  StoredProcedure [edw_core].[sp_nfp_claim_policy_webhook_snapsheet_api]    Script Date: 10-10-2024 01:06:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Description: This procedures migrates claim level notes for snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	10-15-2024				Yunus Mohammed				Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_create_note_api]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
		DROP TABLE IF EXISTS [edw_temp].[migration_create_note_api_temp1];
        select
        c.claim_no,
		n.INSERT_TIME,		
        (
                select
                    
                    'other' as [data.attributes.contact_type],
                    n.NOTE_CONTENT as [data.attributes.body],
                    'comment' as [data.attributes.note_type],
                    FORMAT(n.INSERT_TIME, 'yyyy-MM-ddTHH:mm:ssZ') as [data.attributes.originated_at],
                    capi.claimReferenceNumber as [data.relationships.note_target.data.id],
                    'claim' as [data.relationships.note_target.data.type],
                    'note' as [data.type]
                for json path, include_null_values,without_array_wrapper
            ) note_json,
            getdate() as create_ts, 'pending 'api_status
        into [edw_temp].[migration_create_note_api_temp1]
        from
        edw_stage.t_clm_case c
        inner join edw_stage.t_clm_note n on c.CASE_ID = n.CASE_ID
        inner join edw_stage.migration_create_claim_api capi on capi.claimNumber = c.CLAIM_NO
        where
            n.NOTE_LEVEL = 'Claim'            
            and capi.api_status = 'Success'
            and capi.claimReferenceNumber is not null
            and capi.create_ts > @last_source_extract_ts		

		-- Start Insert process
		INSERT INTO edw_stage.migration_create_note_api
		(			
	        claim_no,note_created_ts,note_json,api_status,create_ts,etl_audit_sk
		)
		SELECT
			claim_no,INSERT_TIME,note_json,api_status,getdate() as create_ts, 
			@etl_audit_sk as etl_audit_sk
		FROM [edw_temp].[migration_create_note_api_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM [edw_temp].[migration_create_note_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[migration_create_note_api_temp1];
		
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
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;

	END CATCH
END