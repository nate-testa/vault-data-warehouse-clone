SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================================================================
-- Description: This stored procedure insert and update info related to tquote_auto_policy_lending_loss.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 01/07/26		Dinesh Bobbili					1. Created the proc
--
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_policy_lending_loss_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_policy_lending_loss_wip_temp1];
        SELECT 
			CreatedDate,UpdatedDate,quote_no,effective_dt,expiration_dt,
		transaction_seq_no,quote_history_sk,source_system_sk,[UniqueId], [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], 
		[TotalPayout], [Disputed], [LendingLoss], [IncludeInRate], [VehicleOperatorName]
        INTO [edw_temp].[tquote_auto_policy_lending_loss_wip_temp1]
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, 
                    acc.ExpirationDate as expiration_dt, acc.Number as transaction_seq_no,
                    qh.quote_history_sk, accof.[Field], accof.[Value],acco.UniqueId,
                    CASE 
                        WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (
                        SELECT  *
                        FROM [edw_stage].[Account] AS a
                        WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                    ) acc
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                LEFT JOIN [edw_core].[tquote_history] AS qh  ON qh.quote_no = acc.PolicyNumber AND qh.effective_dt = acc.EffectiveDate AND qh.transaction_seq_no = 0
                WHERE p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Lending Losses')
					AND isnull(accof.[Value],'') != ''
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], 
				[TotalPayout], [Disputed], [LendingLoss], [IncludeInRate], [VehicleOperatorName]
                )
			) pivottable

		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_policy_lending_loss] AS target
        USING [edw_temp].[tquote_auto_policy_lending_loss_wip_temp1] AS source
            ON target.quote_no = source.quote_no
            AND target.effective_dt = source.effective_dt 
            AND target.transaction_seq_no = source.transaction_seq_no
            AND target.lending_loss_unique_id = source.[UniqueId]
        WHEN MATCHED THEN
            UPDATE SET
                target.expiration_dt = source.expiration_dt
                ,target.quote_history_sk = source.quote_history_sk
                ,target.incident_source = source.[IncidentSource]
                ,target.incident_dt = source.[IncidentDate]
                ,target.incident_type = source.[IncidentType]
                ,target.incident_desc = source.[IncidentDescription]
                ,target.total_payout_amt = source.[TotalPayout]
                ,target.disputed_in = source.[Disputed] 
                ,target.include_in_rate_in = source.[IncludeInRate]
                ,target.vehicle_operator_nm = source.[VehicleOperatorName] 
                ,target.source_system_sk = source.source_system_sk
                ,target.update_ts = GETDATE()
                ,target.etl_audit_sk = @etl_audit_sk
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no
                ,effective_dt
                ,expiration_dt
                ,lending_loss_unique_id
                ,transaction_seq_no
                ,quote_history_sk
                ,incident_source
                ,incident_dt 
                ,incident_type
                ,incident_desc
                ,total_payout_amt
                ,disputed_in 
                ,include_in_rate_in
                ,vehicle_operator_nm
                ,source_system_sk
                ,create_ts
                ,update_ts
                ,etl_audit_sk
            )
            VALUES (
                source.quote_no
                ,source.effective_dt
                ,source.expiration_dt
                ,source.[UniqueId]
                ,source.transaction_seq_no
                ,source.quote_history_sk
                ,source.[IncidentSource]
                ,source.[IncidentDate]
                ,source.[IncidentType]
                ,source.[IncidentDescription]
                ,source.[TotalPayout]
                ,source.[Disputed]
                ,source.[IncludeInRate]
                ,source.[VehicleOperatorName]
                ,source.source_system_sk 
                ,getdate()
                ,getdate()
                ,@etl_audit_sk
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(CreatedDate,UpdatedDate)) FROM edw_temp.[tquote_auto_policy_lending_loss_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_policy_lending_loss_wip_temp1];

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
