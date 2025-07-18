-- =================================================================================================
-- Author:		Hernando Gonzalez
-- Create Date: 07/17/2025
-- Description: This procedures inserts and updates claim notes
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 07/17/2025	Hernando Gonzalez			1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_claim_note]

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

		--************Start************

		DROP TABLE IF EXISTS edw_temp.tcommercial_claim_note_snapsheet_temp1;

		SELECT 
			c.claim_number as claim_no,
			tc.claim_sk,
			n.body as content_desc,
			n.note_type,
			u.name as note_created_by_nm,
			n.created_at as note_created_ts,
			n.contact_type,
			cf.claim_feature_sk,
			5 AS source_system_sk
		INTO edw_temp.tcommercial_claim_note_snapsheet_temp1
		FROM edw_stage_snapsheet.claims as c
		INNER JOIN edw_stage_snapsheet.notes as n ON n.claim_id = c.id
		LEFT JOIN edw_stage_snapsheet.users as u ON u.id = n.logged_by_user_id
		INNER JOIN edw_core.tclaim as tc ON tc.claim_no = c.claim_number
		LEFT JOIN edw_core.tclaim_feature as cf ON cf.claim_no = c.claim_number and cf.claim_coverage_cd=n.exposure_id
		WHERE n.created_at > @last_source_extract_ts
		and exists
			(
				select 1
				from
					edw_stage_snapsheet.tags ctg
				where
					ctg.claim_id = c.id
					and ctg.[name] like 'Commercial%'
			)
		;

		-- Start Insert process
		INSERT INTO edw_core.tcommercial_claim_note
			(
				claim_no,
				claim_sk,
				content_desc,
				note_type,
				note_created_by_nm,
				note_created_ts,
				contact_type,
				claim_feature_sk,
				source_system_sk,
				create_ts,
				update_ts,
				etl_audit_sk
			)
		SELECT 
			claim_no,
			claim_sk,
			content_desc,
			note_type,
			note_created_by_nm,
			note_created_ts,
			contact_type,
			claim_feature_sk,
			source_system_sk,
			GETDATE() AS create_ts,
			GETDATE() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tcommercial_claim_note_snapsheet_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(note_created_ts) FROM edw_temp.tcommercial_claim_note_snapsheet_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_claim_note_snapsheet_temp1

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