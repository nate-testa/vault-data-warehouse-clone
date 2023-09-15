/****** Object:  StoredProcedure [edw_core].[sp_update_tclaim_feature]    Script Date: 15-09-2023 20:44:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 09/13/2023
-- Description: This procedures updated tclaim features tables amount columns

CREATE OR ALTER PROCEDURE [edw_core].[sp_update_tclaim_feature]

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
		-- update claim feature table's payment columns
		UPDATE cf
		SET
			cf.loss_reserve_amt=ISNULL(src.loss_reserve_amt,0),
			cf.expense_reserve_amt=ISNULL(src.expense_reserve_amt,0),
			cf.adjusting_other_reserve_amt=ISNULL(src.adjusting_other_reserve_amt,0),
			cf.subro_reserve_amt=ISNULL(src.subro_reserve_amt,0),
			cf.salvage_reserve_amt=ISNULL(src.salvage_reserve_amt,0),
			cf.salvage_expense_reserve_amt=ISNULL(src.salvage_expense_reserve_amt,0),
			cf.subro_expense_reserve_amt=ISNULL(src.subro_expense_reserve_amt,0),
			cf.loss_paid_amt=ISNULL(src.loss_paid_amt,0),
			cf.expense_paid_amt=ISNULL(src.expense_paid_amt,0),
			cf.adjusting_other_paid_amt=ISNULL(src.adjusting_other_paid_amt,0),
			cf.subro_recovery_amt=ISNULL(src.subro_recovery_amt,0),
			cf.salvage_recovery_amt=ISNULL(src.salvage_recovery_amt,0),
			cf.salvage_expense_paid_amt=ISNULL(src.salvage_expense_paid_amt,0),
			cf.subro_expense_paid_amt=ISNULL(src.subro_expense_paid_amt,0),
			cf.refund_indemnity_paid_amt=ISNULL(src.refund_indemnity_paid_amt,0),
			cf.refund_expense_paid_amt=ISNULL(src.refund_expense_paid_amt,0)
		FROM
		tclaim_feature cf
		INNER JOIN 
		(
			SELECT
				clt.claim_feature_sk,
				SUM(clt.loss_reserve_amt) AS loss_reserve_amt,
				SUM(clt.expense_reserve_amt) AS expense_reserve_amt,
				SUM(clt.adjusting_other_reserve_amt) AS adjusting_other_reserve_amt,
				SUM(clt.subro_reserve_amt) AS subro_reserve_amt,
				SUM(clt.salvage_reserve_amt) AS salvage_reserve_amt,
				SUM(clt.salvage_expense_reserve_amt) AS salvage_expense_reserve_amt,
				SUM(clt.subro_expense_reserve_amt) AS subro_expense_reserve_amt,
				SUM(clt.loss_paid_amt) AS loss_paid_amt,
				SUM(clt.expense_paid_amt) AS expense_paid_amt,
				SUM(clt.adjusting_other_paid_amt) AS adjusting_other_paid_amt,
				SUM(clt.subro_recovery_amt) AS subro_recovery_amt,
				SUM(clt.salvage_recovery_amt) AS salvage_recovery_amt,
				SUM(clt.salvage_expense_paid_amt) AS salvage_expense_paid_amt,
				SUM(clt.subro_expense_paid_amt) AS subro_expense_paid_amt,
				SUM(clt.refund_indemnity_paid_amt) AS refund_indemnity_paid_amt,
				SUM(clt.refund_expense_paid_amt) AS refund_expense_paid_amt
			FROM
			tclaim_feature cf
			INNER JOIN tclaim_transaction clt ON cf.claim_feature_sk=clt.claim_feature_sk
			GROUP BY clt.claim_feature_sk
		) src ON cf.claim_feature_sk=src.claim_feature_sk;

	
		SET @rows_affected=@@ROWCOUNT
	
		UPDATE edw_core.tclaim_feature
		SET 
		adjusting_other_paid_amt=CASE WHEN adjusting_other_paid_amt IS NULL THEN 0 ELSE adjusting_other_paid_amt END,
		adjusting_other_reserve_amt=CASE WHEN adjusting_other_reserve_amt IS NULL THEN 0 ELSE adjusting_other_reserve_amt END,
		expense_paid_amt=CASE WHEN expense_paid_amt IS NULL THEN 0 ELSE expense_paid_amt END,
		expense_reserve_amt=CASE WHEN expense_reserve_amt IS NULL THEN 0 ELSE expense_reserve_amt END,
		loss_paid_amt=CASE WHEN loss_paid_amt IS NULL THEN 0 ELSE loss_paid_amt END,
		loss_reserve_amt=CASE WHEN loss_reserve_amt IS NULL THEN 0 ELSE loss_reserve_amt END,
		refund_expense_paid_amt=CASE WHEN refund_expense_paid_amt IS NULL THEN 0 ELSE refund_expense_paid_amt END,
		refund_indemnity_paid_amt=CASE WHEN refund_indemnity_paid_amt IS NULL THEN 0 ELSE refund_indemnity_paid_amt END,
		salvage_expense_paid_amt=CASE WHEN salvage_expense_paid_amt IS NULL THEN 0 ELSE salvage_expense_paid_amt END,
		salvage_expense_reserve_amt=CASE WHEN salvage_expense_reserve_amt IS NULL THEN 0 ELSE salvage_expense_reserve_amt END,
		salvage_recovery_amt=CASE WHEN salvage_recovery_amt IS NULL THEN 0 ELSE salvage_recovery_amt END,
		salvage_reserve_amt=CASE WHEN salvage_reserve_amt IS NULL THEN 0 ELSE salvage_reserve_amt END,
		subro_expense_paid_amt=CASE WHEN subro_expense_paid_amt IS NULL THEN 0 ELSE subro_expense_paid_amt END,
		subro_expense_reserve_amt=CASE WHEN subro_expense_reserve_amt IS NULL THEN 0 ELSE subro_expense_reserve_amt END,
		subro_recovery_amt=CASE WHEN subro_recovery_amt IS NULL THEN 0 ELSE subro_recovery_amt END,
		subro_reserve_amt=CASE WHEN subro_reserve_amt IS NULL THEN 0 ELSE subro_reserve_amt END;

		SET @rows_affected= ISNULL(@rows_affected,0) + @@ROWCOUNT;	


		-- Update control table
		-- commented as we are not doing incremental insert
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tclaim_temp1),@last_source_extract_ts)
		-- EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
	END CATCH
END
