SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
-- ================================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2024-12-16
-- Description: This stored procedure update rater_pip_discount.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 12/17/24		Alberto Almario					1. create this procedure
-- ================================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_vehicle_coverage_wip_backfill_7911] 
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

        -- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1];

        WITH 
        FinalTable AS (
            SELECT 
                CreatedDate, UpdatedDate, quote_no, effective_dt, vehicle_no,  expiration_dt, 0 as transaction_seq_no, quote_history_sk, quote_auto_vehicle_sk, 
                source_system_sk, vehicle_deleted_in, vehicle_unique_id, [RaterPIPDiscount]
            
            FROM
                (
                    SELECT
                        acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, qav.[vehicle_no] as vehicle_no, acco.[UniqueId] as vehicle_unique_id,
                        acc.ExpirationDate as expiration_dt, --acc.Number as transaction_seq_no,
                        qh.quote_history_sk, qav.quote_auto_vehicle_sk, 
                        acco.IsdeletedOnPolicyChange as vehicle_deleted_in,
                        accof.[Field], 
                        CASE
                        WHEN accof.Field = 'GaragingLocationId' THEN CAST(accof.ReferenceObjectId AS NVARCHAR(3800))
                        ELSE accof.[Value]
                        END AS [Value],
                        CASE 
                            WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                            ELSE 4 --(Metal)
                        END as [source_system_sk]
                    FROM [edw_stage].[Account] acc
                    INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                    INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                    INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                    LEFT JOIN [edw_core].[tquote_history] AS qh 
                        ON qh.quote_no = acc.PolicyNumber
                        AND qh.effective_dt = acc.EffectiveDate
                        AND qh.transaction_seq_no = 0
                    LEFT JOIN [edw_core].[tquote_auto_vehicle] AS qav
                        ON qav.quote_no = acc.PolicyNumber
                        --AND qav.effective_dt = acc.effectivedate
                        AND qav.vehicle_unique_id = cast(acco.[UniqueId] as varchar(max))
                        -- AND qav.vehicle_no = acco.[Index]
                    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=acc.id)
                        AND GREATEST(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts
                        AND acc.PolicyNumber IS NOT NULL
                        AND p.[Name] = 'Automobile'
                        AND p.ProductLine = 'PersonalLines'
                        AND accof.[Group] in ('Discounts')
                        AND accof.field = 'RaterPIPDiscount'
                        
                ) t
            PIVOT 
                (
                    MAX([Value]) FOR [Field] IN 
                    (
                        [RaterPIPDiscount]
                    )
                ) pivottable
        )

        SELECT 
            a.*
        INTO [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1]
        FROM FinalTable AS a 
        WHERE RaterPIPDiscount IS NOT NULL


        -- Start Upate process
		-- SELECT * 
        UPDATE a SET a.rater_pip_discount = b.RaterPIPDiscount
        FROM [edw_core].[tquote_auto_vehicle_coverage] a
        INNER JOIN [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1] b
        ON a.quote_no = b.quote_no
        AND a.effective_dt = b.effective_dt
        AND a.vehicle_unique_id = b.vehicle_unique_id
        AND a.transaction_seq_no = b.transaction_seq_no
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1];

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
GO
