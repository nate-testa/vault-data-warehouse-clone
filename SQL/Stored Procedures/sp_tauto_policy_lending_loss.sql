SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================================================================
-- Description: This stored procedure insert and update info related to tauto_policy_lending_loss.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 01/07/26		Dinesh Bobbili					1. Created the proc
--
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_policy_lending_loss] 
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_policy_lending_loss_temp1];
		
        SELECT IssuedDate,policy_no,effective_dt,transaction_effective_dt,expiration_dt,transaction_dt,
		transaction_seq_no,policy_history_sk,source_system_sk,UniqueId, [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], 
		[TotalPayout], [Disputed], [LendingLoss], [IncludeInRate], [VehicleOperatorName]
        INTO [edw_temp].[tauto_policy_lending_loss_temp1]
        FROM (
            SELECT  
            acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acct.TransactionEffectiveDate as transaction_effective_dt, 
                        acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                        ph.policy_history_sk,
                        acctvof.[Field], acctvof.[Value],acctvo.UniqueId,
                        CASE 
                            WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                            ELSE 4 --(Metal)
                        END as [source_system_sk]
                    FROM
                        (SELECT *
                        FROM [edw_stage].[AccountTransaction]
                        WHERE [State] = 'ISSUED'
                            AND IssuedDate > @last_source_extract_ts
                        ) acct
                    INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                    INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                    INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                    INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                    LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                        ON ph.policy_no = acct.PolicyNumber
                        AND ph.effective_dt = acct.EffectiveDate
                        AND ph.transaction_seq_no = acct.policychangenumber
                    WHERE
                        p.[Name] = 'Automobile'
                        AND p.ProductLine = 'PersonalLines'
                        AND acctvof.[Group] in ('Lending Losses')
                        AND isnull(acctvof.[Value],'') != ''
                        ) t
                PIVOT 
                (
                    MAX([Value]) FOR [Field] IN 
                    ([IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], 
                    [TotalPayout], [Disputed], [LendingLoss], [IncludeInRate], [VehicleOperatorName]
                    )
                ) pivottable

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_policy_lending_loss]
        (
            policy_no
            ,effective_dt
            ,transaction_effective_dt
            ,lending_loss_unique_id
            ,expiration_dt
            ,transaction_dt
            ,transaction_seq_no
            ,policy_history_sk
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
        SELECT 
            t1.policy_no
            ,t1.effective_dt
            ,t1.transaction_effective_dt
            ,t1.UniqueId AS lending_loss_unique_id
            ,t1.expiration_dt
            ,t1.transaction_dt
            ,t1.transaction_seq_no
            ,t1.policy_history_sk
            ,t1.[IncidentSource] AS incident_source
            ,t1.[IncidentDate] AS incident_dt
            ,t1.[IncidentType] AS incident_type
            ,t1.[IncidentDescription] AS incident_desc
            ,t1.[TotalPayout] AS total_payout_amt
            ,t1.[Disputed] AS disputed_in
            ,t1.[IncludeInRate] AS include_in_rate_in
            ,t1.[VehicleOperatorName] AS vehicle_operator_nm
            ,t1.source_system_sk 
            ,getdate() AS create_ts
            ,getdate() AS update_ts
            ,@etl_audit_sk AS etl_audit_sk
        FROM 
            [edw_temp].[tauto_policy_lending_loss_temp1] AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_policy_lending_loss_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_policy_lending_loss_temp1];

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
