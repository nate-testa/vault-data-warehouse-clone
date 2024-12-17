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

-- Unique ID
--  [policy_no],
-- 	[effective_dt],
-- 	[vehicle_unique_id],
-- 	[transaction_seq_no]

CREATE OR ALTER PROCEDURE [edw_temp].[sp_tauto_vehicle_coverage_backfill_7911]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_backfill_7911_temp1];


        SELECT 
            IssuedDate, policy_no, effective_dt, vehicle_no, vehicle_unique_id, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, policy_history_sk, auto_vehicle_sk, auto_garage_location_sk,
            source_system_sk, vehicle_deleted_in, [RaterPIPDiscount]
        INTO [edw_temp].[tauto_vehicle_coverage_backfill_7911_temp1]
        FROM
            (
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, av.[vehicle_no] as vehicle_no, [UniqueId] as vehicle_unique_id, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                    ph.policy_history_sk, av.auto_vehicle_sk, 0 auto_garage_location_sk, 
                    acctvo.IsdeletedOnPolicyChange as vehicle_deleted_in,
                    acctvof.[Field],
                    CASE
                        WHEN acctvof.Field = 'GaragingLocationId' THEN CAST(acctvof.ReferenceObjectId AS nvarchar(3800))
                        ELSE acctvof.[Value]
                    END AS [Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM [edw_stage].[AccountTransaction] AS acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                    ON ph.policy_no = acct.PolicyNumber
                    AND ph.effective_dt = acct.EffectiveDate
                    AND ph.transaction_seq_no = acct.policychangenumber
                LEFT JOIN [edw_core].[tauto_vehicle] AS av
                    ON av.policy_no = acct.PolicyNumber
                    AND av.effective_dt = acct.EffectiveDate
                    AND av.vehicle_unique_id = acctvo.[UniqueId]
                WHERE acct.[State] = 'ISSUED'
                    AND acct.IssuedDate > @last_source_extract_ts
                    AND p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Discounts')
                    AND acctvof.field = 'RaterPIPDiscount'
            ) t
        PIVOT 
            (
                MAX([Value]) FOR [Field] IN 
                (
                    [RaterPIPDiscount]
                )
            ) pivottable
   

		-- Start Upate process
		-- SELECT * 
        UPDATE a SET a.rater_pip_discount = b.RaterPIPDiscount
        FROM [edw_core].[tauto_vehicle_coverage] a
        INNER JOIN [edw_temp].[tauto_vehicle_coverage_backfill_7911_temp1] b
        ON a.policy_no = b.policy_no
        AND a.effective_dt = b.effective_dt
        AND a.vehicle_unique_id = b.vehicle_unique_id
        AND a.transaction_seq_no = b.transaction_seq_no
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_coverage_backfill_7911_temp1];

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
