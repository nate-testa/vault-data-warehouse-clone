-- ========================================================================================================
-- Description: This procedures updates tclaim_feature item_sk and vehicle_coverage_sk if they are null
-----------------------------------------------------------------------------------------------------------
-- Change date				|Author									|Change Description
-----------------------------------------------------------------------------------------------------------
-- 03/18/2025				Yunus Mohammd				1. Created this procedure

-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_feature_snapsheet_update]
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

        DROP TABLE IF EXISTS edw_temp.tclaim_feature_snapsheet_update_temp1;
        select *
        into edw_temp.tclaim_feature_snapsheet_update_temp1
        from
        (
        select ROW_NUMBER()over(partition by a.claim_no order by a.claim_no) as rn,
        b.claim_no,b.claim_feature_sk,a.item_sk,a.vehicle_coverage_sk,greatest(a.create_ts,a.update_ts) AS greatest_created_updated
        from
        edw_core.tclaim_feature  a
        inner join 
        (
            select claim_sk,claim_feature_sk,claim_no,item_sk,vehicle_coverage_sk
            from edw_core.tclaim_feature
            where 
            source_system_sk!=1
            and product_sk = 3
            and (item_sk is null or vehicle_coverage_sk is null)
        ) as b
        on a.claim_sk = b.claim_sk and a.claim_feature_sk != b.claim_feature_sk
        where
            greatest(a.create_ts,a.update_ts) > @last_source_extract_ts and
            (a.item_sk is not null or a.vehicle_coverage_sk is not null)

        ) as a
        where
            rn = 1

        update [target]
        set
            [target].item_sk = [source].item_sk,
            [target].vehicle_coverage_sk = [source].vehicle_coverage_sk
        from
            edw_core.tclaim_feature as [target]
            inner join edw_temp.tclaim_feature_snapsheet_update_temp1 as [source] on [source].claim_no = [target].claim_no
            and [source].claim_feature_sk = [target].claim_feature_sk

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest_created_updated) FROM edw_temp.tclaim_feature_snapsheet_update_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_feature_snapsheet_update_temp1;

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
