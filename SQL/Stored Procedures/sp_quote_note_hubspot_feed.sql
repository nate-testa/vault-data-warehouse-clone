-- ====================================================================================================================
-- Description: This procedures inserts and updates quote note hubspot data
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 07/23/24		        Architha Gudimalla			1. Created this procedure
-- 07/29/24		        Architha Gudimalla			2. Corrections after first run
-- 08/09/24		        Architha Gudimalla			3. Exclude notes before 20240601
-- 10/11/24		        Architha Gudimalla			4. Exclude yacht
-- 10/25/24		        Architha Gudimalla			5. Include notes for only those quotes that are in the quote feed
-- 01/08/25		        Alberto Almario				6. VI35257 - Add note_user_nm
-- ==================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_quote_note_hubspot_feed]

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
		DECLARE @current_date DATETIME2(7)=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.quote_note_hubspot_feed_temp1;

        select n.policy_no as quote_no, n.note_desc, n.note_created_ts, n.note_updated_ts, n.note_id, n.create_ts,n.update_ts, nullif(trim(CONCAT(isnull(u.first_nm,''),' ',isnull(u.last_nm,''))),'') as note_user_nm
        into edw_temp.quote_note_hubspot_feed_temp1
        from [edw_core].[tnote] n
		left join [edw_core].[tuser] u on n.user_sk = u.user_sk
        where n.object_type = 'Account' 
		and greatest(n.note_created_ts, n.note_updated_ts) > @last_source_extract_ts
		and n.policy_no is not null 
		and exists (select quote_no from edw_integration.quote_hubspot_feed q
					where n.policy_no = q.quote_no );

        -- Start Merge process
		MERGE INTO [edw_integration].[quote_note_hubspot_feed] AS target
        USING [edw_temp].[quote_note_hubspot_feed_temp1] AS source on target.note_id = source.note_id
        WHEN NOT MATCHED BY Target THEN
        INSERT
        (
            quote_no, note_desc, note_created_ts, note_updated_ts, note_id, create_ts, update_ts, etl_audit_sk, note_user_nm 
        )
        VALUES
        (
            quote_no , note_desc, note_created_ts, note_updated_ts, note_id, getdate(), getdate(), @etl_audit_sk, note_user_nm
        )
        WHEN MATCHED THEN UPDATE
        SET        
            [target].note_desc	        =	[source].note_desc, 
            [target].note_updated_ts	=	[source].note_updated_ts,
            [target].update_ts	        =	GETDATE(),
            [target].etl_audit_sk	    =	@etl_audit_sk,
			[target].note_user_nm		=	[source].note_user_nm;
        
        SET @rows_affected=@@ROWCOUNT;
        -- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(create_ts,update_ts)) FROM edw_temp.[quote_note_hubspot_feed_temp1]),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.quote_note_hubspot_feed_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END