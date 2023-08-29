
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario Valbuena
-- Create Date: 2023-08-25
-- Description: This procedures insert and update info related to claim symbility api
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_symbility_api]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tclaim_symbility_api_temp1];
		SELECT ph.policy_no,
            ph.effective_dt,
            ph.expiration_dt,
            ph.transaction_effective_dt,
            ph.transaction_seq_no,
            pi.insured_type,
            CASE WHEN pi.insured_type = 'Individual' THEN  pi.first_nm END as first_nm,
            CASE WHEN pi.insured_type = 'Individual' THEN  pi.last_nm END as last_nm,
            CASE WHEN pi.insured_type = 'Entity' THEN  pi.insured_nm END as business_nm,
            pi.home_phone_no,
            pi.mobile_phone_no,
            pi.email,
            hc.aop_deductible,
            hc.dwelling_limit_amt,
            hc.built_year,
            ss.source_system_nm,
            --pr.product_nm,
            ph.create_ts as policy_history_create_ts
		INTO [edw_temp].[tclaim_symbility_api_temp1] 
		FROM edw_core.tpolicy_history AS ph
        LEFT JOIN edw_core.thome_coverage AS hc ON ph.policy_history_sk = hc.policy_history_sk
        LEFT JOIN edw_core.tpolicy_insured AS pi ON ph.policy_history_sk = pi.policy_history_sk AND ph.transaction_effective_dt = pi.transaction_effective_dt AND pi.primary_insured_in = 'Yes'
        LEFT JOIN edw_core.tsource_system AS ss ON ph.source_system_sk = ss.source_system_sk
        --LEFT JOIN edw_core.tpolicy AS p ON ph.policy_sk = p.policy_sk AND ph.effective_dt = p.effective_dt
		--LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
        WHERE cast(ph.create_ts as datetime2(7)) > @last_source_extract_ts;


		-- Start Insert process
		INSERT INTO [edw_integration].[claim_symbility_api](
            policy_no,
            effective_dt,
            expiration_dt,
            transaction_effective_dt,
            transaction_seq_no,
            insured_type,
            first_nm,
            last_nm,
            business_nm,
            home_phone_no,
            mobile_phone_no,
            email,
            aop_deductible,
            dwelling_limit_amt,
            built_year,
            source_system_nm,
            create_ts,
            update_ts,
            etl_audit_sk
		)
		SELECT policy_no,
            effective_dt,
            expiration_dt,
            transaction_effective_dt,
            transaction_seq_no,
            insured_type,
            first_nm,
            last_nm,
            business_nm,
            home_phone_no,
            mobile_phone_no,
            email,
            aop_deductible,
            dwelling_limit_amt,
            built_year,
            source_system_nm,
			getdate(),
			getdate(),
		    @etl_audit_sk
		FROM [edw_temp].[tclaim_symbility_api_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_history_create_ts) FROM [edw_temp].[tclaim_symbility_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tclaim_symbility_api_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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
