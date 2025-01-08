SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2024-11-25
-- Description: This procedures insert boat yacht data
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 25/11/2024		Alberto Almario				1. Create this stored procedure.
-- ===============================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tmarine_boat_yacht_watercraft]
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

		DROP TABLE IF EXISTS edw_temp.tmarine_boat_yacht_watercraft_temp1;

		SELECT 
			policy_no,
			effective_dt,
			transaction_effective_dt,
			expiration_dt,
			transaction_dt,
			transaction_seq_no,
			watercraft_no,
			watercraft_unique_id,
			policy_history_sk,
			[Year] AS watercraft_make,
			Make AS watercraft_model,
			Model AS watercraft_year,
			PWCId AS watercraft_pwc_id,
			source_system_sk,
			IssuedDate
		INTO edw_temp.tmarine_boat_yacht_watercraft_temp1
		FROM
			(
				SELECT
					act.PolicyNumber as policy_no,
					CAST(act.EffectiveDate AS DATE) as effective_dt,
					CAST(act.TransactionEffectiveDate AS DATE) as transaction_effective_dt,
					CAST(act.ExpirationDate AS DATE) as expiration_dt,
					act.IssuedDate as transaction_dt,
					act.policychangenumber as transaction_seq_no,
					atvo.[Index] as watercraft_no,
					atvo.[UniqueId] as watercraft_unique_id,
					tph.policy_history_sk,
					CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END as source_system_sk,
					atvof.Field,
					atvof.[Value],
					act.IssuedDate
				FROM
					edw_stage.AccountTransaction act
					INNER JOIN edw_stage.Product p ON p.Id = act.ProductId
					INNER JOIN edw_stage.AccountTransactionVersion atv ON act.Id = atv.AccountTransactionId
					INNER JOIN edw_stage.AccountTransactionVersionObject atvo ON atv.Id = atvo.AccountTransactionVersionId
					INNER JOIN edw_stage.AccountTransactionVersionObjectField atvof ON atvo.Id = atvof.VersionObjectId
					LEFT JOIN edw_core.tpolicy_history tph ON tph.policy_no = act.PolicyNumber
						AND tph.effective_dt = act.EffectiveDate
						AND tph.transaction_seq_no = act.policychangenumber
				WHERE 1=1
					AND act.PolicyNumber IS NOT NULL 
					AND act.[State] = 'ISSUED'
					AND p.[Name] = 'Marine Boat & Yacht'
					AND p.ProductLine = 'PersonalLines'
					AND atvo.ObjectType = 'PersonalWatercraft'
					AND atvof.Field IN ('Year', 'Make', 'Model', 'PWCId')
					AND act.IssuedDate > @last_source_extract_ts
			) as t
		PIVOT 
			(
				MAX([Value]) FOR Field IN ([Year], Make, Model, PWCId)
			) as pivottable


		-- Start Insert process
		INSERT INTO [edw_core].[tmarine_boat_yacht_watercraft]
		(
			policy_no,
			effective_dt,
			transaction_effective_dt,
			expiration_dt,
			transaction_dt,
			transaction_seq_no,
			watercraft_no,
			watercraft_unique_id,
			policy_history_sk,
			watercraft_make,
			watercraft_model,
			watercraft_year,
			watercraft_pwc_id,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT
			policy_no,
			effective_dt,
			transaction_effective_dt,
			expiration_dt,
			transaction_dt,
			transaction_seq_no,
			watercraft_no,
			watercraft_unique_id,
			policy_history_sk,
			watercraft_make,
			watercraft_model,
			watercraft_year,
			watercraft_pwc_id,
			source_system_sk,
			getdate() AS create_ts,
			getdate() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tmarine_boat_yacht_watercraft_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tmarine_boat_yacht_watercraft_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tmarine_boat_yacht_watercraft_temp1

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

