SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Description: This procedures updates claim snapsheet
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/22/2024		Alberto Almario				1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_update_tclaim_snapsheet]
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

		UPDATE cl
		SET
			cl.loss_reserve_amt = ISNULL(src.loss_reserve_amt,0),
			cl.expense_reserve_amt = ISNULL(src.expense_reserve_amt,0),
			cl.subrogation_recovery_reserve_amt = ISNULL(src.subrogation_recovery_reserve_amt,0),
			cl.salvage_recovery_reserve_amt = ISNULL(src.salvage_recovery_reserve_amt,0),
			cl.salvage_recovery_expense_reserve_amt = ISNULL(src.salvage_recovery_expense_reserve_amt,0),
			cl.subrogation_recovery_expense_reserve_amt = ISNULL(src.subrogation_recovery_expense_reserve_amt,0),
			cl.loss_paid_amt = ISNULL(src.loss_paid_amt,0),
			cl.expense_paid_amt = ISNULL(src.expense_paid_amt,0),
			cl.subrogation_recovery_amt = ISNULL(src.subrogation_recovery_amt,0),
			cl.salvage_recovery_amt = ISNULL(src.salvage_recovery_amt,0),
			cl.salvage_expense_recovery_amt = ISNULL(src.salvage_expense_recovery_amt,0),
			cl.subrogation_expense_recovery_amt = ISNULL(src.subrogation_expense_recovery_amt,0),
			cl.defense_reserve_amt = ISNULL(src.defense_reserve_amt,0),
			cl.deductible_recovery_reserve_amt = ISNULL(src.deductible_recovery_reserve_amt,0),
			cl.reinsurance_recovery_reserve_amt = ISNULL(src.reinsurance_recovery_reserve_amt,0),
			cl.overpayment_recovery_reserve_amt = ISNULL(src.overpayment_recovery_reserve_amt,0),
			cl.deductible_recovery_expense_reserve_amt = ISNULL(src.deductible_recovery_expense_reserve_amt,0),
			cl.reinsurance_recovery_expense_reserve_amt = ISNULL(src.reinsurance_recovery_expense_reserve_amt,0),
			cl.overpayment_recovery_expense_reserve_amt = ISNULL(src.overpayment_recovery_expense_reserve_amt,0),
			cl.subrogation_recovery_defense_reserve_amt = ISNULL(src.subrogation_recovery_defense_reserve_amt,0),
			cl.salvage_recovery_defense_reserve_amt = ISNULL(src.salvage_recovery_defense_reserve_amt,0),
			cl.deductible_recovery_defense_reserve_amt = ISNULL(src.deductible_recovery_defense_reserve_amt,0),
			cl.reinsurance_recovery_defense_reserve_amt = ISNULL(src.reinsurance_recovery_defense_reserve_amt,0),
			cl.overpayment_recovery_defense_reserve_amt = ISNULL(src.overpayment_recovery_defense_reserve_amt,0),
			cl.defense_paid_amt = ISNULL(src.defense_paid_amt,0),
			cl.deductible_recovery_amt = ISNULL(src.deductible_recovery_amt,0),
			cl.reinsurance_recovery_amt = ISNULL(src.reinsurance_recovery_amt,0),
			cl.overpayment_recovery_amt = ISNULL(src.overpayment_recovery_amt,0),
			cl.deductible_expense_recovery_amt = ISNULL(src.deductible_expense_recovery_amt,0),
			cl.reinsurance_expense_recovery_amt = ISNULL(src.reinsurance_expense_recovery_amt,0),
			cl.overpayment_expense_recovery_amt = ISNULL(src.overpayment_expense_recovery_amt,0),
			cl.subrogation_defense_recovery_amt = ISNULL(src.subrogation_defense_recovery_amt,0),
			cl.salvage_defense_recovery_amt = ISNULL(src.salvage_defense_recovery_amt,0),
			cl.deductible_defense_recovery_amt = ISNULL(src.deductible_defense_recovery_amt,0),
			cl.reinsurance_defense_recovery_amt = ISNULL(src.reinsurance_defense_recovery_amt,0),
			cl.overpayment_defense_recovery_amt = ISNULL(src.overpayment_defense_recovery_amt,0)
		FROM edw_core.tclaim cl
		INNER JOIN (
			SELECT
				clt.claim_sk,
				SUM(clt.loss_reserve_amt) AS loss_reserve_amt,
				SUM(clt.expense_reserve_amt) AS expense_reserve_amt,
				SUM(clt.subrogation_recovery_reserve_amt) AS subrogation_recovery_reserve_amt,
				SUM(clt.salvage_recovery_reserve_amt) AS salvage_recovery_reserve_amt,
				SUM(clt.salvage_recovery_expense_reserve_amt) AS salvage_recovery_expense_reserve_amt,
				SUM(clt.subrogation_recovery_expense_reserve_amt) AS subrogation_recovery_expense_reserve_amt,
				SUM(clt.loss_paid_amt) AS loss_paid_amt,
				SUM(clt.expense_paid_amt) AS expense_paid_amt,
				SUM(clt.subrogation_recovery_amt) AS subrogation_recovery_amt,
				SUM(clt.salvage_recovery_amt) AS salvage_recovery_amt,
				SUM(clt.salvage_expense_recovery_amt) AS salvage_expense_recovery_amt,
				SUM(clt.subrogation_expense_recovery_amt) AS subrogation_expense_recovery_amt,
				SUM(clt.defense_reserve_amt) AS defense_reserve_amt,
				SUM(clt.deductible_recovery_reserve_amt) AS deductible_recovery_reserve_amt,
				SUM(clt.reinsurance_recovery_reserve_amt) AS reinsurance_recovery_reserve_amt,
				SUM(clt.overpayment_recovery_reserve_amt) AS overpayment_recovery_reserve_amt,
				SUM(clt.deductible_recovery_expense_reserve_amt) AS deductible_recovery_expense_reserve_amt,
				SUM(clt.reinsurance_recovery_expense_reserve_amt) AS reinsurance_recovery_expense_reserve_amt,
				SUM(clt.overpayment_recovery_expense_reserve_amt) AS overpayment_recovery_expense_reserve_amt,
				SUM(clt.subrogation_recovery_defense_reserve_amt) AS subrogation_recovery_defense_reserve_amt,
				SUM(clt.salvage_recovery_defense_reserve_amt) AS salvage_recovery_defense_reserve_amt,
				SUM(clt.deductible_recovery_defense_reserve_amt) AS deductible_recovery_defense_reserve_amt,
				SUM(clt.reinsurance_recovery_defense_reserve_amt) AS reinsurance_recovery_defense_reserve_amt,
				SUM(clt.overpayment_recovery_defense_reserve_amt) AS overpayment_recovery_defense_reserve_amt,
				SUM(clt.defense_paid_amt) AS defense_paid_amt,
				SUM(clt.deductible_recovery_amt) AS deductible_recovery_amt,
				SUM(clt.reinsurance_recovery_amt) AS reinsurance_recovery_amt,
				SUM(clt.overpayment_recovery_amt) AS overpayment_recovery_amt,
				SUM(clt.deductible_expense_recovery_amt) AS deductible_expense_recovery_amt,
				SUM(clt.reinsurance_expense_recovery_amt) AS reinsurance_expense_recovery_amt,
				SUM(clt.overpayment_expense_recovery_amt) AS overpayment_expense_recovery_amt,
				SUM(clt.subrogation_defense_recovery_amt) AS subrogation_defense_recovery_amt,
				SUM(clt.salvage_defense_recovery_amt) AS salvage_defense_recovery_amt,
				SUM(clt.deductible_defense_recovery_amt) AS deductible_defense_recovery_amt,
				SUM(clt.reinsurance_defense_recovery_amt) AS reinsurance_defense_recovery_amt,
				SUM(clt.overpayment_defense_recovery_amt) AS overpayment_defense_recovery_amt
			FROM edw_core.tclaim cl
			INNER JOIN edw_core.tclaim_transaction clt ON cl.claim_sk=clt.claim_sk
			GROUP BY clt.claim_sk
		) src ON cl.claim_sk = src.claim_sk

		SET @rows_affected=@@ROWCOUNT
		

		UPDATE edw_core.tclaim
		SET 
			adjusting_other_paid_amt = CASE WHEN adjusting_other_paid_amt IS NULL THEN 0 ELSE adjusting_other_paid_amt END,
			adjusting_other_reserve_amt = CASE WHEN adjusting_other_reserve_amt IS NULL THEN 0 ELSE adjusting_other_reserve_amt END,
			refund_expense_paid_amt = CASE WHEN refund_expense_paid_amt IS NULL THEN 0 ELSE refund_expense_paid_amt END,
			refund_indemnity_paid_amt = CASE WHEN refund_indemnity_paid_amt IS NULL THEN 0 ELSE refund_indemnity_paid_amt END,
			salvage_expense_paid_amt = CASE WHEN salvage_expense_paid_amt IS NULL THEN 0 ELSE salvage_expense_paid_amt END,
			salvage_expense_reserve_amt = CASE WHEN salvage_expense_reserve_amt IS NULL THEN 0 ELSE salvage_expense_reserve_amt END,
			salvage_reserve_amt = CASE WHEN salvage_reserve_amt IS NULL THEN 0 ELSE salvage_reserve_amt END,
			subro_expense_paid_amt = CASE WHEN subro_expense_paid_amt IS NULL THEN 0 ELSE subro_expense_paid_amt END,
			subro_expense_reserve_amt = CASE WHEN subro_expense_reserve_amt IS NULL THEN 0 ELSE subro_expense_reserve_amt END,
			subro_recovery_amt = CASE WHEN subro_recovery_amt IS NULL THEN 0 ELSE subro_recovery_amt END,
			subro_reserve_amt = CASE WHEN subro_reserve_amt IS NULL THEN 0 ELSE subro_reserve_amt END
		;

		SET @rows_affected= ISNULL(@rows_affected,0) + @@ROWCOUNT;	

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(created_ts) FROM edw_temp.update_tclaim_snapsheet_temp1),@last_source_extract_ts);
		-- EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		-- DROP TABLE IF EXISTS edw_temp.update_tclaim_snapsheet_temp1

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
