SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Description: This procedures updates claim feature snapsheet
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/22/2024		Alberto Almario				1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_update_tclaim_feature_snapsheet]
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

		UPDATE clf
		SET
			clf.loss_reserve_amt = ISNULL(src.loss_reserve_amt,0),
			clf.expense_reserve_amt = ISNULL(src.expense_reserve_amt,0),
			clf.subrogation_recovery_reserve_amt = ISNULL(src.subrogation_recovery_reserve_amt,0),
			clf.salvage_recovery_reserve_amt = ISNULL(src.salvage_recovery_reserve_amt,0),
			clf.salvage_recovery_expense_reserve_amt = ISNULL(src.salvage_recovery_expense_reserve_amt,0),
			clf.subrogation_recovery_expense_reserve_amt = ISNULL(src.subrogation_recovery_expense_reserve_amt,0),
			clf.loss_paid_amt = ISNULL(src.loss_paid_amt,0),
			clf.expense_paid_amt = ISNULL(src.expense_paid_amt,0),
			clf.subrogation_recovery_amt = ISNULL(src.subrogation_recovery_amt,0),
			clf.salvage_recovery_amt = ISNULL(src.salvage_recovery_amt,0),
			clf.salvage_expense_recovery_amt = ISNULL(src.salvage_expense_recovery_amt,0),
			clf.subrogation_expense_recovery_amt = ISNULL(src.subrogation_expense_recovery_amt,0),
			clf.defense_reserve_amt = ISNULL(src.defense_reserve_amt,0),
			clf.deductible_recovery_reserve_amt = ISNULL(src.deductible_recovery_reserve_amt,0),
			clf.reinsurance_recovery_reserve_amt = ISNULL(src.reinsurance_recovery_reserve_amt,0),
			clf.overpayment_recovery_reserve_amt = ISNULL(src.overpayment_recovery_reserve_amt,0),
			clf.deductible_recovery_expense_reserve_amt = ISNULL(src.deductible_recovery_expense_reserve_amt,0),
			clf.reinsurance_recovery_expense_reserve_amt = ISNULL(src.reinsurance_recovery_expense_reserve_amt,0),
			clf.overpayment_recovery_expense_reserve_amt = ISNULL(src.overpayment_recovery_expense_reserve_amt,0),
			clf.subrogation_recovery_defense_reserve_amt = ISNULL(src.subrogation_recovery_defense_reserve_amt,0),
			clf.salvage_recovery_defense_reserve_amt = ISNULL(src.salvage_recovery_defense_reserve_amt,0),
			clf.deductible_recovery_defense_reserve_amt = ISNULL(src.deductible_recovery_defense_reserve_amt,0),
			clf.reinsurance_recovery_defense_reserve_amt = ISNULL(src.reinsurance_recovery_defense_reserve_amt,0),
			clf.overpayment_recovery_defense_reserve_amt = ISNULL(src.overpayment_recovery_defense_reserve_amt,0),
			clf.defense_paid_amt = ISNULL(src.defense_paid_amt,0),
			clf.deductible_recovery_amt = ISNULL(src.deductible_recovery_amt,0),
			clf.reinsurance_recovery_amt = ISNULL(src.reinsurance_recovery_amt,0),
			clf.overpayment_recovery_amt = ISNULL(src.overpayment_recovery_amt,0),
			clf.deductible_expense_recovery_amt = ISNULL(src.deductible_expense_recovery_amt,0),
			clf.reinsurance_expense_recovery_amt = ISNULL(src.reinsurance_expense_recovery_amt,0),
			clf.overpayment_expense_recovery_amt = ISNULL(src.overpayment_expense_recovery_amt,0),
			clf.subrogation_defense_recovery_amt = ISNULL(src.subrogation_defense_recovery_amt,0),
			clf.salvage_defense_recovery_amt = ISNULL(src.salvage_defense_recovery_amt,0),
			clf.deductible_defense_recovery_amt = ISNULL(src.deductible_defense_recovery_amt,0),
			clf.reinsurance_defense_recovery_amt = ISNULL(src.reinsurance_defense_recovery_amt,0),
			clf.overpayment_defense_recovery_amt = ISNULL(src.overpayment_defense_recovery_amt,0)

		FROM edw_core.tclaim_feature clf
		INNER JOIN (
			SELECT
				clt.claim_feature_sk,
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
			FROM edw_core.tclaim_feature clf
			INNER JOIN edw_core.tclaim_transaction clt ON clf.claim_feature_sk=clt.claim_feature_sk
			GROUP BY clt.claim_feature_sk
		) src ON clf.claim_feature_sk = src.claim_feature_sk

		SET @rows_affected=@@ROWCOUNT
		
		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		-- SET @new_last_source_extract_ts=COALESCE((SELECT MAX(created_ts) FROM edw_temp.update_tclaim_feature_snapsheet_temp1),@last_source_extract_ts);
		-- EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		-- DROP TABLE IF EXISTS edw_temp.update_tclaim_feature_snapsheet_temp1

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
