-- ======================================================================================================== 
-- Description: This procedures inserts claim tag data
-----------------------------------------------------------------------------------------------------------
-- Change date 			|Author									|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 04/25/2025		 Yununs Mohammed		    1. Created this procedue
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_tag]
AS	
BEGIN
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

		drop table if exists edw_temp.tclaim_tag_temp1;

        select
        tc.claim_sk,
        tc.claim_no,
        t.[name] as tag_nm,
        t.tagged_at as tag_created_ts,
        5 as  source_system_sk
        into  edw_temp.tclaim_tag_temp1
        from
        edw_stage_snapsheet.claims c
        inner join edw_core.tclaim tc on c.claim_number = tc.claim_no
        inner join edw_stage_snapsheet.tags t on c.id = t.claim_id
        where
        tagged_at > @last_source_extract_ts
		and not exists
                (
                    select 1
                    from
                        edw_stage_snapsheet.tags ctg
                    where
                        ctg.claim_id = c.id
                    and ctg.[name] in 
                    (
                        'Commercial XS-LPL','Commercial MPL','Commercial PRF','TPA Assigned','Commercial - Primary','Commercial - First Excess'
                    )
                )

        insert into edw_core.tclaim_tag
        (
            claim_sk,claim_no,tag_nm,tag_created_ts,source_system_sk,etl_audit_sk,create_ts,update_ts
        )
		select 
            claim_sk,claim_no,tag_nm,tag_created_ts,source_system_sk,@etl_audit_sk as etl_audit_sk,@current_date  as create_ts,@current_date as update_ts
         from
            edw_temp.tclaim_tag_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(tag_created_ts) FROM edw_temp.tclaim_tag_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_tag_temp1;
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