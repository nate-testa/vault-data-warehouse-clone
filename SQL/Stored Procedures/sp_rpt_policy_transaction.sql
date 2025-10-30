-- ==============================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-10-22
-- Description: This stored procedure insert info related to rpt_policy_transaction.
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------
-- 10/22/25		Alberto Almario			    1. Created this procedure
-- ==============================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_rpt_policy_transaction]
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

		-- Drop temp table if exists
		DROP TABLE IF EXISTS [edw_temp].[rpt_policy_transaction_temp1];

		-- Create temp table with initial extraction
		SELECT 
            a.policy_no,
            a.effective_dt,
            a.expiration_dt,
            a.transaction_effective_dt,
            a.transaction_seq_no,
            CAST(a.transaction_ts AS DATE) AS transaction_dt,
            c.product_nm,
            d.broker_id,
            d.broker_nm,
            e.customer_id,
            e.customer_nm,
            f.risk_state_cd,
            f.uw_company_nm,
            a.transaction_type,
            a.transaction_desc,
            a.cancellation_reason_desc,
            a.cancellation_sub_reason_desc,
            ISNULL(a.premium_amt, 0) AS premium_amt,
            ISNULL(a.commission_amt, 0) AS commission_amt,
            ISNULL(a.net_premium_amt, 0) AS net_premium_amt,
            ISNULL(a.annual_premium_amt, 0) AS annual_premium_amt,
            ISNULL(a.tax_fee_surcharge_amt, 0) AS tax_fee_surcharge_amt,
            transaction_ts,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        INTO [edw_temp].[rpt_policy_transaction_temp1]
        FROM edw_core.tpolicy_history a
        INNER JOIN edw_core.tproduct c ON a.product_sk = c.product_sk
        INNER JOIN edw_core.tbroker d ON a.broker_sk = d.broker_sk
        INNER JOIN edw_core.tcustomer e ON a.customer_sk = e.customer_sk
        INNER JOIN edw_core.tpolicy f ON a.policy_sk = f.policy_sk
        WHERE a.transaction_ts > @last_source_extract_ts;

		-- Start Insert process
		INSERT INTO [edw_insights_ai].[rpt_policy_transaction]
        (
            policy_no,
            effective_dt,
            expiration_dt,
            transaction_effective_dt,
            transaction_seq_no,
            transaction_dt,
            product_nm,
            broker_id,
            broker_nm,
            customer_id,
            customer_nm,
            risk_state_cd,
            uw_company_nm,
            transaction_type,
            transaction_desc,
            cancellation_reason_desc,
            cancellation_sub_reason_desc,
            premium_amt,
            commission_amt,
            net_premium_amt,
            annual_premium_amt,
            tax_fee_surcharge_amt,
            create_ts,
            update_ts,
            etl_audit_sk
		)
        SELECT 
            policy_no,
            effective_dt,
            expiration_dt,
            transaction_effective_dt,
            transaction_seq_no,
            transaction_dt,
            product_nm,
            broker_id,
            broker_nm,
            customer_id,
            customer_nm,
            risk_state_cd,
            uw_company_nm,
            transaction_type,
            transaction_desc,
            cancellation_reason_desc,
            cancellation_sub_reason_desc,
            premium_amt,
            commission_amt,
            net_premium_amt,
            annual_premium_amt,
            tax_fee_surcharge_amt,
            create_ts,
            update_ts,
            etl_audit_sk
        FROM [edw_temp].[rpt_policy_transaction_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_ts) FROM [edw_temp].[rpt_policy_transaction_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS [edw_temp].[rpt_policy_transaction_temp1];

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
