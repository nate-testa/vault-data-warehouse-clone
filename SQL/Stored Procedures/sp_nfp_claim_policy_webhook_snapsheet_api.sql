-- =================================================================================================
-- Description: This procedures insert policy webhook data for snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	09-30-2024				Yunus Mohammed				Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_nfp_claim_policy_webhook_snapsheet_api]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    
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
		
		DROP TABLE IF EXISTS [edw_temp].[nfp_claim_policy_webhook_snapsheet_api_temp1];
        with policy_webhook as
        (
            select		
                null cancelledAt,
                null AS cancelledReason,
                FORMAT(cpsa.inceptionDate, 'yyyy-MM-ddTHH:mm:ssZ') as effectiveAt,
                FORMAT(cpsa.expiration_dt, 'yyyy-MM-ddTHH:mm:ssZ') as expirationAt,
                FORMAT(cpsa.inceptionDate, 'yyyy-MM-ddTHH:mm:ssZ') as inceptionAt,
                cpsa.policyNumber,
                'general_liability' as policyType,
                cpsa.[status] as [status],    
                cpsa.transaction_effective_dt  as [version],
                cpsa.transaction_seq_no,
                json_query((
                    select
                        null as agencyCode,
                        nfp.group_name as agencyName,
                        'broker' as agencyType,
                        null as agencyAddress,
                        json_query((
                            SELECT
                                'us' as country,
                                '1' as countryCode,
                                'true' preferredMethod,
                                'phone' as [type],
                                '7272900434'as [value] --  put it from claim.
                            for json path, include_null_values
                        )) as agencyContactMethods
                    for json path, include_null_values, without_array_wrapper
                )) AS agentInformation,
            JSON_QUERY
            ((
                select
                    'PEL' as code,
                    'general_liability' as [name]
                for json path, include_null_values, without_array_wrapper
            )
            ) as product,
            null as reservation,
            json_query((
            select
                'vault_es_insurance_company' as account,
                null as contact,
                null as team
            for json path, include_null_values, without_array_wrapper
            )) as underwriting,
            json_query
            (
                (
                    select
                    case coverageCode
                        when 'GEXL' then 'Excess Liability'
                        when 'EXLUM' then 'UM/UIM Motorist Liability'
                        when 'EXLEPL' then 'Employment Practices Liability'
                    end as [name],
                    coverageCode,
                    null as [limits.amount],
                    null as [limits.deductible]
                    /*(
                        select
                            Limit as amount,
                            null as coverageLimitType
                            -- incident aggregate per_person
                        for json path, include_null_values
                    ) as [limits]
                    */
                from
                (
                        SELECT
                            CAST(NULLIF(nfp.group_excess_liability_coverage,0) AS VARCHAR(255)) as GEXL,
                            CAST(NULLIF(nfp.uninsured_motorist_liability_coverage,0) AS VARCHAR(255)) as EXLUM,
                            CAST(NULLIF(NULLIF(CAST(nfp.employment_practises_liability_coverage AS VARCHAR(MAX)),''),'0') AS VARCHAR(255)) as EXLEPL
                        FROM
                            edw_stage.nfp_policy nfp
                        where
                            nfp.insured_cert_no = cpsa.policyNumber
                    ) as sourcetable
                unpivot
                (
                    Limit For coverageCode in (GEXL,EXLUM,EXLEPL)
                ) as unpvt
                for json path, include_null_values
                )
            ) as coverages,
            null as [businesses],
            ((

                select
                    nfp.insured_first_name as firstName,
                    null as middleName,
                    nfp.insured_last_name as lastName,
                'policyholder' as [role],
                    -- null as providerSubjectId it can be primary_key
                    json_query((
                        SELECT
                            nfp.address1 as address1,
                            nfp.address2 as address2,
                            nfp.city as city,
                            nfp.zip as postalCode,
                            nfp.[state] as region,
                            'us' as country
                            for json path, include_null_values, without_array_wrapper			
                    )) as [address],
                    json_query((
                    SELECT
                        'us' as country,
                        '1' as countryCode,
                        'true' preferredMethod,
                        'phone' as [type],
                        '7272900434'as [value] --  put it from claim.
                    for json path, include_null_values
                    )) as contactMethods   
                for json path, include_null_values
            )) as people,
            json_query((
            select
                 cast(cpsa.policyNumber as varchar(255)) + '-' + cast(cpsa.transaction_seq_no  as varchar(255)) as id,
                'pel' as coverageCode,
                '1' as externalLocationIdentifier,
                '1' as externalRiskIdentifier,
                'general_liability' as [type],
                json_query((
                    select
                        nfp.address1 as address1, 
                        nfp.address2 as address2,
                        nfp.city  as city,
                        nfp.zip as postalCode,
                        nfp.[state] as region,
                        'us' as country
                    for json path, include_null_values, without_array_wrapper
                )) as [address],
                json_query((
                    select
                        'building_and_personal_property' as propertyType,
                        'policy_address' as propertyLocation
                    for json path, include_null_values, without_array_wrapper
                )) as property,
                json_query
            (
                (
                    select
                    case coverageCode
                        when 'GEXL' then 'Excess Liability'
                        when 'EXLUM' then 'UM/UIM Motorist Liability'
                        when 'EXLEPL' then 'Employment Practices Liability'
                    end as [name],
                    coverageCode,
                    null as [limits.amount],
                    null as [limits.deductible]
                    /*(
                        select
                            Limit as amount,
                            null as coverageLimitType
                            -- incident aggregate per_person
                        for json path, include_null_values
                    ) as [limits]
                    */
                from
                (
                        SELECT
                            CAST(NULLIF(nfp.group_excess_liability_coverage,0) AS VARCHAR(255)) as GEXL,
                            CAST(NULLIF(nfp.uninsured_motorist_liability_coverage,0) AS VARCHAR(255)) as EXLUM,
                            CAST(NULLIF(NULLIF(CAST(nfp.employment_practises_liability_coverage AS VARCHAR(MAX)),''),'0') AS VARCHAR(255)) as EXLEPL
                        FROM
                            edw_stage.nfp_policy nfp
                        where
                            nfp.insured_cert_no = cpsa.policyNumber
                    ) as sourcetable
                unpivot
                (
                    Limit For coverageCode in (GEXL,EXLUM,EXLEPL)
                ) as unpvt
                for json path, include_null_values
                )
            ) as coverages

            for json path, include_null_values
            )) as risks,	
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as endorsements,
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as notes,
            json_query((
                select
                    cpsa.transaction_effective_dt as effectiveAt,
                    cpsa.expiration_dt as expirationAt,
                    cpsa.transaction_type as providerTypeDescription
                for json path, include_null_values

            )) as versions,
            (select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')) as deductibles,
            source_system_nm,
            cpsa.create_ts
            from
            [edw_integration].[claim_policy_search_snapsheet_api] cpsa
            inner join 
            (
                SELECT
                    group_name,insured_first_name,insured_last_name, policy_no,effective_dt,expiration_dt,transaction_effective_dt,transaction_seq_no,policy_status,
                    insured_nm,insured_type,uw_company_nm,product_nm,transaction_type,risk_item,address1,address2,city,[state],zip,
                    row_number()over(partition by  policy_no, effective_dt, transaction_seq_no, cast(risk_item as varchar(max))
                    order by policy_no,effective_dt,transaction_seq_no) as rn		
                FROM
                (
                SELECT group_name, insured_cert_no as policy_no,effective_date as effective_dt,expiration_date as expiration_dt,
                transaction_date as transaction_effective_dt,null as policy_status,CONCAT_WS(' ' , insured_first_name,insured_last_name) insured_nm,
                ROW_NUMBER()OVER(partition by policy_no, insured_cert_no order by transaction_date, reporting_month) as transaction_seq_no,
                null as insured_type,'Vault E&S Insurance Company' as uw_company_nm,'PEL' as product_nm,transaction_type, insured_first_name,insured_last_name,
                risk_group as risk_item,address1,address2,city,[state],zip
                
                FROM
                    edw_stage.nfp_policy
                WHERE
                    insured_cert_no is not null
                    
                ) as temp
            ) as nfp on cpsa.policyNumber = nfp.policy_no and cpsa.inceptionDate = nfp.effective_dt and cpsa.transaction_seq_no = nfp.transaction_seq_no

            where
                nfp.rn = 1
                and cpsa.source_system_nm = 'NFP'
                and cpsa.create_ts > @last_source_extract_ts
        )

        select *,
        json_query
            ( 
            (
                
                select
                    cancelledAt, cancelledReason, effectiveAt, expirationAt, inceptionAt, policyNumber,
            policyType, [status], [version], agentInformation, product, reservation, underwriting,
            businesses,	people,	risks, coverages, endorsements, notes, versions,deductibles
                    for json path, include_null_values, without_array_wrapper
            )
        ) as [data]
        into edw_temp.nfp_claim_policy_webhook_snapsheet_api_temp1
        from 
        policy_webhook


		-- Start Insert process
		INSERT INTO edw_integration.claim_policy_webhook_snapsheet_api
		(			
	        cancelledAt, cancelledReason, effectiveAt, expirationAt, inceptionAt, policyNumber,
			policyType, [status], [version], transaction_seq_no, agentInformation, product, underwriting,
			businesses,	people,	risks, coverages, versions, deductibles,[data] ,source_system_nm, create_ts, etl_audit_sk
		)
		SELECT distinct
			 cancelledAt, cancelledReason,	effectiveAt, expirationAt, inceptionAt, policyNumber,
			policyType, [status], [version], transaction_seq_no, agentInformation, product, underwriting,
			businesses,	people,	risks, coverages,versions,deductibles,[data] ,source_system_nm,
			getdate() as create_ts, @etl_audit_sk as etl_audit_sk
		FROM [edw_temp].[nfp_claim_policy_webhook_snapsheet_api_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM [edw_temp].[nfp_claim_policy_webhook_snapsheet_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[nfp_claim_policy_webhook_snapsheet_api_temp1];
		
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