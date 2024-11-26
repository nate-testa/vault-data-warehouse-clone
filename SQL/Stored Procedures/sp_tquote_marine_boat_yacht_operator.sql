SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2024-11-22
-- Description: This procedures insert boat yacht data
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 22/11/2024		Hernando Gonzalez Garcia	1. Create this stored procedure.
-- ===============================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_operator]
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

		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_operator_temp1;

		SELECT 
			quote_no,
			effective_dt,
			expiration_dt,
			transaction_seq_no,
			operator_no,
			operator_unique_id,
			quote_history_sk,
			quote_marine_boat_yacht_sk,
			FirstName AS first_nm,
			LastName AS last_nm,
			License AS license_type,
			source_system_sk,
			CreatedDate
		INTO edw_temp.tquote_marine_boat_yacht_operator_temp1
		FROM
			(
				SELECT
					act.PolicyNumber as quote_no,
					CAST(act.EffectiveDate AS DATE) as effective_dt,
					CAST(act.ExpirationDate AS DATE) as expiration_dt,
					act.Number as transaction_seq_no,
					atvo.[Index] as operator_no,
					atvo.[UniqueId] as operator_unique_id,
					tph.quote_history_sk,
					mby.quote_marine_boat_yacht_sk,
					CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END as source_system_sk,
					atvof.Field,
					atvof.[Value],
					act.CreatedDate
				FROM
					edw_stage.AccountTransaction act
					INNER JOIN edw_stage.Product p ON p.Id = act.ProductId
					INNER JOIN edw_stage.AccountTransactionVersion atv ON act.Id = atv.AccountTransactionId
					INNER JOIN edw_stage.AccountTransactionVersionObject atvo ON atv.Id = atvo.AccountTransactionVersionId
					INNER JOIN edw_stage.AccountTransactionVersionObjectField atvof ON atvo.Id = atvof.VersionObjectId
					LEFT JOIN edw_core.tquote_marine_boat_yacht mby ON mby.quote_no = act.PolicyNumber
					LEFT JOIN edw_core.tquote_history tph ON tph.quote_no = act.PolicyNumber
						AND tph.effective_dt = act.EffectiveDate
						AND tph.transaction_seq_no = act.Number
				WHERE 1=1
					AND act.PolicyNumber IS NOT NULL 
					AND act.[Stage] IN ('QUOTE','POLICY')
					AND p.[Name] = 'Marine Boat & Yacht'
					AND p.ProductLine = 'PersonalLines'
					AND atvo.ObjectType = 'Operator'
					AND atvof.Field IN ('FirstName', 'LastName', 'License')
					AND act.CreatedDate > @last_source_extract_ts
			) as t
		PIVOT 
			(
				MAX([Value]) FOR Field IN (FirstName, LastName, License)
			) as pivottable


		-- Start Insert process
		INSERT INTO [edw_core].[tquote_marine_boat_yacht_operator]
		(
			quote_no,
			effective_dt,
			expiration_dt,
			transaction_seq_no,
			operator_no,
			operator_unique_id,
			quote_history_sk,
			quote_marine_boat_yacht_sk,
			first_nm,
			last_nm,
			license_type,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT
			quote_no,
			effective_dt,
			expiration_dt,
			transaction_seq_no,
			operator_no,
			operator_unique_id,
			quote_history_sk,
			quote_marine_boat_yacht_sk,
			first_nm,
			last_nm,
			license_type,
			source_system_sk,
			getdate() AS create_ts,
			getdate() AS update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_temp.tquote_marine_boat_yacht_operator_temp1;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_marine_boat_yacht_operator_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_operator_temp1

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

