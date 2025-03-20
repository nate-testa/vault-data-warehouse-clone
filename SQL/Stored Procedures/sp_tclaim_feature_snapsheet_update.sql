-- ========================================================================================================
-- Description: This procedures updates tclaim_feature snapsheet data (item_sk, vehicle_coverage_sk and claim_feature_status)
-----------------------------------------------------------------------------------------------------------
-- Change date				|Author						                |Change Description
-----------------------------------------------------------------------------------------------------------
-- 03/18/2025				Yunus Mohammd				1. Created this procedure
--                                                                                              item_sk and vehicle_coverage_sk from another exposure
--                                                                                              claim_feature_status also updated

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

        drop table if exists edw_temp.tclaim_feature_snapsheet_update_temp1;
		drop table if exists edw_temp.tclaim_feature_snapsheet_update_temp2;		

        select [source].rn,
        [target].claim_no,[target].claim_feature_sk,[source].item_sk,[source].vehicle_coverage_sk,
        greatest([source].create_ts,[source].update_ts) AS greatest_created_updated
        into edw_temp.tclaim_feature_snapsheet_update_temp1
        from
        (
            SELECT ROW_NUMBER()over(partition by claim_no order by claim_no) as rn, *
            FROM
            edw_core.tclaim_feature
            where
            (item_sk is not null or vehicle_coverage_sk is not null)
            
        ) as [source]
        inner join 
        (
            select claim_sk,claim_feature_sk,claim_no,item_sk,vehicle_coverage_sk
            from edw_core.tclaim_feature
            where 
            source_system_sk!=1
            and product_sk = 3
            and (item_sk is null or vehicle_coverage_sk is null)
        ) as [target]
        on [source].claim_sk = [target].claim_sk and [source].claim_feature_sk != [target].claim_feature_sk
        where  
            [source].rn = 1

        update [target]
        set
            [target].item_sk = [source].item_sk,
            [target].vehicle_coverage_sk = [source].vehicle_coverage_sk
        from
            edw_core.tclaim_feature as [target]
            inner join edw_temp.tclaim_feature_snapsheet_update_temp1 as [source] on [source].claim_no = [target].claim_no
            and [source].claim_feature_sk = [target].claim_feature_sk
		
		-- Update claim_feature_status
		select tf.claim_feature_sk,exps.[status] AS claim_feature_status
		into edw_temp.tclaim_feature_snapsheet_update_temp2
		from edw_stage_snapsheet.claims clm
		inner join edw_core.tclaim tcl ON clm.claim_number = tcl.claim_no
		inner join edw_stage_snapsheet.exposures exps on exps.claim_id = clm.id
		inner join edw_core.tclaim_feature tf on tf.claim_no = tcl.claim_no and tf.claim_coverage_cd = exps.id
		where
            greatest(tf.create_ts,tf.update_ts) > @last_source_extract_ts

		update [target]
		set [target].claim_feature_status = [source].claim_feature_status
		from
			edw_core.tclaim_feature [target]
			inner join edw_temp.tclaim_feature_snapsheet_update_temp2 [source] on [target].claim_feature_sk = [source].claim_feature_sk

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
