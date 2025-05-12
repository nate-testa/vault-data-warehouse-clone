-- =================================================================================================
-- Description: This procedures update column payment_status in claim payment table
-----------------------------------------------------------------------------------------------------------
-- Change date |	Author					|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 01/29/25		Alberto Almario			1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_payment_ebao_payment_status_update]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.tclaim_payment_ebao_payment_status_update_temp1

		
		SELECT	c.claim_number as claim_no,
				tf.claim_feature_sk,
				fpi.financial_transaction_id AS payment_no,
				1 AS payment_sequence_no,
				fpi.cost_type AS claim_type_cd,
				fpi.cost_category,
				ft.stage AS payment_status,
				ft.remote_identifier,
				ft.updated_at

		INTO 	edw_temp.tclaim_payment_ebao_payment_status_update_temp1 

		FROM 		edw_stage_snapsheet.claims c
		INNER JOIN 	edw_core.tclaim tc ON tc.claim_no=c.claim_number
		INNER JOIN 	edw_core.tclaim_feature tf ON tf.claim_no = tc.claim_no
		INNER JOIN  edw_stage_snapsheet.exposures e on c.id = e.claim_id and tf.claim_coverage_cd=e.id
		INNER JOIN 	edw_stage_snapsheet.financial_payment_items fpi on fpi.claim_id = c.id and e.id = fpi.exposure_id
		INNER JOIN 	edw_stage_snapsheet.financial_transactions ft on ft.id = fpi.financial_transaction_id
		WHERE ft.is_historical = 'true'
		AND ft.stage in ('stopped','cleared')
		AND ft.updated_at > @last_source_extract_ts
		;   

		MERGE edw_core.tclaim_payment  AS Target
		USING edw_temp.tclaim_payment_ebao_payment_status_update_temp1 AS Source
			ON  Source.claim_feature_sk=Target.claim_feature_sk 
			AND Source.remote_identifier=Target.settle_payee_id
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			Target.payment_status=Source.payment_status,
			Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(updated_at) FROM edw_temp.tclaim_payment_ebao_payment_status_update_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_payment_ebao_payment_status_update_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END