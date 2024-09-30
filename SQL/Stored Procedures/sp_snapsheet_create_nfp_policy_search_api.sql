SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Description: This procedures insert NFP policies to Claim Policy Search API for snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	09-30-2024				Yunus Mohammed				Created procedure
-- ================================================================================================= 
create or ALTER   PROCEDURE [edw_core].[sp_snapsheet_create_nfp_policy_search_api]
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
		
		DROP TABLE IF EXISTS [edw_temp].[snapsheet_create_nfp_policy_search_api_temp1];
		SELECT
        policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
        insured_first_name,insured_last_name,product_nm,transaction_type,
        source_system_nm,address1,address2,city,[state],zip,country,
        row_number()over(partition by policy_no, effective_dt, transaction_seq_no
        order by policy_no,effective_dt,transaction_seq_no) as rn,update_ts
        INTO edw_temp.snapsheet_create_nfp_policy_search_api_temp1
        FROM
        (
        SELECT insured_cert_no as policy_no,effective_date as effective_dt,expiration_date as expiration_dt,
        transaction_date as transaction_effective_dt,null as policy_status,
        insured_first_name,insured_last_name,
        ROW_NUMBER()OVER(partition by policy_no, insured_cert_no order by transaction_date, reporting_month) as transaction_seq_no,
        'PEL' as product_nm,transaction_type,
        address1,address2,city,[state],zip,'us' as country,
        'NFP' as source_system_nm,update_ts
                
        FROM
            edw_stage.nfp_policy
        WHERE
            insured_cert_no is not null
        ) as temp
        WHERE
            update_ts > @last_source_extract_ts


		-- Start Insert process
		INSERT INTO [edw_integration].[snapsheet_create_policy_search_api]
		(			
			policy_no,
			policy_type,
			[status],
			product_code,
			inception_date,			
			expiration_dt,
			transaction_effective_dt,
			transaction_seq_no,
			transaction_type,
            policy_entities,
			source_system_nm,			
			api_status,			
			create_ts,
			update_ts,
			etl_audit_sk
		)
		select
            policy_no,
            'professional_liability' as policy_type,
            'Active' as [status],
            'Excess Liability' as product_code,
            effective_dt as inception_date,
            expiration_dt,
            transaction_effective_dt,
            transaction_seq_no,
            transaction_type,
            JSON_QUERY
            (
            (
                select
                    null as [policyEntities.name],
                    insured_first_name [policyEntities.firstName],
                    insured_last_name as [policyEntities.lastName],
                    'Person' as [policyEntities.entityType],
                    address1 as [policyEntities.address.address1],
                    address2 as [policyEntities.address.address2],
                    city as [policyEntities.address.city],
                    state as [policyEntities.address.region],
                    zip as [policyEntities.address.postalCode],
                    'us' as [policyEntities.address.country],
                    -- as addresses,
                    '[]' as contactMethods
                    for json path, include_null_values
            )
            ) as policyEntities
            ,source_system_nm
            ,'pending' as api_status,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk
            from
            edw_temp.snapsheet_create_nfp_policy_search_api_temp1

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_transaction_create_ts) FROM [edw_temp].[snapsheet_create_nfp_policy_search_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[snapsheet_create_nfp_policy_search_api_temp1];
		
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