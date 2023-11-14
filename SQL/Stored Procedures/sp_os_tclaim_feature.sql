-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShied claim into tclaim table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tclaim_feature]

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

		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_temp1

		SELECT
		tc.claim_sk,tc.claim_no,subclaim_type_nm,
		RIGHT('000' + cast(ROW_NUMBER()OVER(PARTITION BY ttcf.claim_no ORDER BY ttcf.claim_sk,ttcf.claim_coverage_cd)as varchar(100)),3) AS subclaim_seq_no,
		claim_coverage_cd,ttcf.claim_coverage_desc,claimant_nm,damage_severity,damage_type,possible_subrogation_in,
		possible_salvage_in,total_loss_in,litigation_in,ttcf.product_sk,ttcf.CASE_STATUS AS claim_feature_status,NULL AS aslob_sk,
		claim_adjuster_nm,NULL AS risk_item,
		ROUND(ttcf.loss_reserve_amt,2) AS loss_reserve_amt,ROUND(ttcf.expense_reserve_amt,2) AS expense_reserve_amt,
		ROUND(ttcf.adjusting_other_reserve_amt,2) AS adjusting_other_reserve_amt,ROUND(ttcf.subro_reserve_amt,2) AS subro_reserve_amt,
		ROUND(ttcf.salvage_reserve_amt,2) AS salvage_reserve_amt,ROUND(ttcf.salvage_expense_reserve_amt,2) AS salvage_expense_reserve_amt,
		ROUND(ttcf.subro_expense_reserve_amt,2) AS subro_expense_reserve_amt,ROUND(ttcf.loss_paid_amt,2) AS loss_paid_amt,
		ROUND(ttcf.expense_paid_amt,2) AS expense_paid_amt,ROUND(ttcf.adjusting_other_paid_amt,2) AS adjusting_other_paid_amt,
		ROUND(ttcf.subro_recovery_amt,2) AS subro_recovery_amt,ROUND(ttcf.salvage_recovery_amt,2) AS salvage_recovery_amt,
		ROUND(ttcf.salvage_expense_paid_amt,2) AS salvage_expense_paid_amt,ROUND(ttcf.subro_expense_paid_amt,2) AS subro_expense_paid_amt,
		ROUND(ttcf.refund_indemnity_paid_amt,2) AS refund_indemnity_paid_amt,
		ROUND(ttcf.refund_expense_paid_amt,2) AS refund_expense_paid_amt,
		ttcf.source_system_sk
		INTO edw_temp.os_tclaim_feature_temp1
		FROM
		edw_stage.dragon_feature_os ttcf
		INNER JOIN edw_core.tclaim tc ON ttcf.claim_no=tc.claim_no
		WHERE
		tc.source_system_sk=1


		INSERT INTO edw_core.tclaim_feature
		(
			claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
			subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,
			subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,adjusting_other_paid_amt,
			subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
			refund_indemnity_paid_amt,refund_expense_paid_amt,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
			subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,
			subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,adjusting_other_paid_amt,
			subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
			refund_indemnity_paid_amt,refund_expense_paid_amt,
			source_system_sk,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tclaim_feature_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_temp1
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