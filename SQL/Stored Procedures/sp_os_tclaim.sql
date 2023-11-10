-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShied claim into tclaim table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tclaim]

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

		DROP TABLE IF EXISTS edw_temp.os_tclaim_temp1

		SELECT
		claim_no,loss_dt,report_dt,policy_no,policy_effective_dt,policy_sk,tcl.cause_of_loss_sk,
		loss_desc,claim_status,source_claim_status,cat.catastrophe_sk,product_sk,underwriting_company_nm,
		loss_address,loss_city_nm,loss_state_nm,loss_zip_cd,loss_country_nm,NULL AS agencyid,contact_nm,
		contact_type,contact_phone,contact_person_email,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,
		expense_paid_amt,adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,
		subro_expense_paid_amt,refund_indemnity_paid_amt,refund_expense_paid_amt,
		tc.source_system_sk
		INTO edw_temp.os_tclaim_temp1
		FROM
		edw_stage.dragon_claim_os tc
		LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_desc=REPLACE(tc.cause_of_loss_sk,'*','') AND tcl.source_system_sk=1
		LEFT JOIN edw_core.tcatastrophe cat ON
		(
		SUBSTRING(tc.catastrophe_sk,CHARINDEX(tc.catastrophe_sk,'CAT-')+5,4) = cat.catastrophe_cd
		OR tc.catastrophe_sk=cat.catastrophe_cd
		)

		INSERT INTO edw_core.tclaim
		(
		claim_no,loss_dt,report_dt,policy_no,policy_effective_dt,policy_sk,cause_of_loss_sk,
		loss_desc,claim_status,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,
		loss_address,loss_city_nm,loss_state_cd,loss_zip_cd,loss_country_nm,contact_nm,
		contact_type,contact_phone,contact_person_email,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,
		expense_paid_amt,adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,
		subro_expense_paid_amt,refund_indemnity_paid_amt,refund_expense_paid_amt,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT claim_no,loss_dt,report_dt,policy_no,policy_effective_dt,policy_sk,cause_of_loss_sk,
		loss_desc,claim_status,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,
		loss_address,loss_city_nm,loss_state_nm,loss_zip_cd,loss_country_nm,contact_nm,
		contact_type,contact_phone,contact_person_email,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,
		expense_paid_amt,adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,
		subro_expense_paid_amt,refund_indemnity_paid_amt,refund_expense_paid_amt,source_system_sk,
		GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tclaim_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tbroker_temp1
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