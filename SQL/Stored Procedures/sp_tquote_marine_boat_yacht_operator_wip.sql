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
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_operator_wip]
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

		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_operator_wip_temp1;

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
			greatest_create_update_date
		INTO edw_temp.tquote_marine_boat_yacht_operator_wip_temp1
		FROM
			(
				SELECT
					act.PolicyNumber as quote_no,
					CAST(act.EffectiveDate AS DATE) as effective_dt,
					CAST(act.ExpirationDate AS DATE) as expiration_dt,
					0 as transaction_seq_no,
					atvo.[Index] as operator_no,
					atvo.[UniqueId] as operator_unique_id,
					tph.quote_history_sk,
					mby.quote_marine_boat_yacht_sk,
					CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END as source_system_sk,
					atvof.Field,
					atvof.[Value],
					GREATEST(act.CreatedDate,act.UpdatedDate) as greatest_create_update_date
				FROM
					(
						SELECT *
						FROM [edw_stage].[Account] AS a
						WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
						AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
						AND a.PolicyNumber IS NOT NULL
					) act
					INNER JOIN edw_stage.Product p ON p.Id = act.ProductId
					INNER JOIN edw_stage.AccountObject atvo ON act.Id = atvo.AccountId
					INNER JOIN edw_stage.AccountObjectField atvof ON atvo.Id = atvof.ObjectId
					LEFT JOIN edw_core.tquote_marine_boat_yacht mby ON mby.quote_no = act.PolicyNumber
						AND mby.effective_dt = act.EffectiveDate 
					LEFT JOIN edw_core.tquote_history tph ON tph.quote_no = act.PolicyNumber
						AND tph.effective_dt = act.EffectiveDate
						AND tph.transaction_seq_no = 0
				WHERE 1=1
					AND act.PolicyNumber IS NOT NULL 
					AND act.[Stage] IN ('QUOTE','POLICY')
					AND p.[Name] = 'Marine Boat & Yacht'
					AND p.ProductLine = 'PersonalLines'
					AND atvo.ObjectType = 'Operator'
					AND atvof.Field IN ('FirstName', 'LastName', 'License')
			) as t
		PIVOT 
			(
				MAX([Value]) FOR Field IN (FirstName, LastName, License)
			) as pivottable


		-- Start Merge process
		MERGE INTO [edw_core].[tquote_marine_boat_yacht_operator] as [Target]
		USING edw_temp.tquote_marine_boat_yacht_operator_wip_temp1 as Source
			ON Target.quote_no = Source.quote_no
			AND Target.effective_dt = Source.effective_dt
			AND Target.transaction_seq_no = Source.transaction_seq_no
			AND Target.operator_unique_id = Source.operator_unique_id
		WHEN MATCHED THEN
			UPDATE SET
				Target.expiration_dt = Source.expiration_dt,
				Target.operator_no = Source.operator_no,
				Target.operator_unique_id = Source.operator_unique_id,
				Target.quote_history_sk = Source.quote_history_sk,
				Target.quote_marine_boat_yacht_sk = Source.quote_marine_boat_yacht_sk,
				Target.first_nm = Source.first_nm,
				Target.last_nm = Source.last_nm,
				Target.license_type = Source.license_type,
				Target.source_system_sk = Source.source_system_sk,
				Target.update_ts = GETDATE(),
				Target.etl_audit_sk = @etl_audit_sk
		WHEN NOT MATCHED BY Target THEN
		INSERT (
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
		VALUES(
			Source.quote_no,
			Source.effective_dt,
			Source.expiration_dt,
			Source.transaction_seq_no,
			Source.operator_no,
			Source.operator_unique_id,
			Source.quote_history_sk,
			Source.quote_marine_boat_yacht_sk,
			Source.first_nm,
			Source.last_nm,
			Source.license_type,
			Source.source_system_sk,
			getdate(),
			getdate(),
			@etl_audit_sk
		);

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest_create_update_date) FROM edw_temp.tquote_marine_boat_yacht_operator_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_operator_wip_temp1

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

