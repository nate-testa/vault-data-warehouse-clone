-- =================================================================================================
-- Description: This procedures insert policy webhook data for snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						                |	Change Description
---------------------------------------------------------------------------------------------------
--	06/25/2025			  Yunus Mohammed				1 Created procedure
--	07/03/2025			  Dinesh Bobbili				2 Commented out vehicle and drivers and replaced with CVG7777VES
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_commercial_policy_webhook_snapsheet_api]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));

        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp2];
        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp3];
        
        SELECT distinct
            pt.commercial_policy_history_sk, pt.commercial_policy_sk,pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.customer_sk, 
			pt.policy_transaction_type_sk, 
            pt.source_system_sk, pt.create_ts
        into [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp1]
            FROM
            (
            select
                pt. *
            from
                edw_commercial.tcommercial_policy_transaction pt
            where        
                cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
            )as pt
            INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk ;        
-- E&O CoverageName and code
-- 
	with policy_webhook as
	(
    select
            FORMAT(tp.cancellation_effective_dt, 'yyyy-MM-ddTHH:mm:ssZ') AS cancelledAt,
            tph.cancellation_reason_desc  AS cancelledReason,
            FORMAT(tp.effective_dt, 'yyyy-MM-ddTHH:mm:ssZ') as effectiveAt,
			FORMAT(tp.expiration_dt, 'yyyy-MM-ddTHH:mm:ssZ') as expirationAt,
			-- take minimum policy effective date
			FORMAT((select min(effective_dt) from edw_commercial.tcommercial_policy p1
			where p1.policy_no = tp.policy_no), 'yyyy-MM-ddTHH:mm:ssZ') as inceptionAt,
            tph.policy_no as policyNumber,
            'professional_liability'  as policyType,
            tp.policy_status as [status],
            -- FORMAT(cpsa.inception_date, 'yyyy-MM-ddTHH:mm:ssZ') + '-'+ FORMAT(cpsa.expiration_dt, 'yyyy-MM-ddTHH:mm:ssZ') as [version],
            tph.transaction_effective_dt  as [version],
            cpsa.transaction_seq_no,
            json_query((
                select
                    tbrk.broker_id as agencyCode,
                    tbrk.broker_nm as agencyName,
                    'broker' as agencyType,
                    json_query((
                        SELECT
                            tbrk.primary_address_line_1 as address1,
                            tbrk.primary_address_line_2 as address2,
                            tbrk.primary_address_city_nm as city,
                            tbrk.primary_address_zip_cd as postalCode,
                            tbrk.primary_address_state_cd as region,
                            tbrk.primary_address_country_nm as country
                        for json path, include_null_values, without_array_wrapper
                    )) as agencyAddress,
                    json_query((
						select *
						from
						(
                        SELECT
                            'us' as country,
                            '1' as countryCode,
--                            'true' preferredMethod,
                            'phone' as [type],
							--'7272901574' as [value]
							tbrk.broker_phone_no as [value]
						UNION
						SELECT
                            null as country,
                           null as countryCode,
--                            'true' preferredMethod,
                            'email' as [type],
							--'Farhad.Imam@Vault.Insurance' as [value]
							tbrk.broker_email as [value]
						) as a
                        for json path, include_null_values
                    )) as agencyContactMethods
                for json path, include_null_values, without_array_wrapper
            )) AS agentInformation
            ,
            JSON_QUERY
            ((
                select
                    prd.product_cd as code,
                    prd.[product_nm] as [name]
                for json path, include_null_values, without_array_wrapper
            )
            ) as product,
            null as reservation,
            json_query((
                select 'vault_es_insurance_company' AS account
                for json path, include_null_values, without_array_wrapper
            )) as underwriting,
			json_query((
					select 'Other' as [role],
					tp.insured_nm as [name],
					json_query((
                            SELECT
                                tp.mailing_address_line1 as address1,
                                tp.mailing_address_line2 as address2,
                                tp.mailing_address_city_nm as city,
                                tp.mailing_address_zip_cd as postalCode,
                                tp.mailing_address_state_cd as region,
                                'US' as country
                                for json path, include_null_values, without_array_wrapper
                    )) as [address],
					json_query((
						select *
						from
						(
                        SELECT
							'us' as country,
							'1' as countryCode,
--                           'true' preferredMethod,
                            'phone' as [type],
                           -- '7272901574' as [value]
							c.home_phone_no as [value]
						UNION
						SELECT
                            null as country,
                            null as countryCode,
--                          'true' preferredMethod,
                            'email' as [type],
							--'Farhad.Imam@Vault.Insurance' as [value]
							c.email as [value]                        
						) as temp
                        for json path, include_null_values
                    )) as contactMethods
			where
				c.insured_type = 'Entity'
			for json path, include_null_values
			))
             as [businesses],
            json_Query((
                select
                    c.first_nm as firstName,
                    c.middle_nm as middleName,
                    c.last_nm as lastName,
                    'policyholder' as [role],
                    -- null as providerSubjectId it can be primary_key
                    json_query((
                        SELECT
                            tp.mailing_address_line1 as address1,
                            tp.mailing_address_line2 as address2,
                            tp.mailing_address_city_nm as city,
                            tp.mailing_address_zip_cd as postalCode,
                            tp.mailing_address_state_cd as region,
                            'US' as country
                            for json path, include_null_values, without_array_wrapper			
                    )) as [address],
                    json_query((
                    SELECT *
                    FROM
                    (
					   SELECT
							'us' as country,
							'1' as countryCode,
							-- 'true' preferredMethod,
							'phone' as [type],
							--'7272901574' as [value] 							
							coalesce(c.home_phone_no,c.mobile_phone_no) as [value]
					UNION
						SELECT
						null as country,
						null as countryCode,
--                        'true' preferredMethod,
						'email' as [type],
						-- 'Farhad.Imam@Vault.Insurance' as [value] 
						c.email as [value]
					) as a
					for json path, include_null_values
					)) as contactMethods
				where
					[c].Insured_type = 'Individual'
				for json path, include_null_values
			)) as people,
            json_query((
           
                JSON_QUERY
                ((
                select
                CAST(tph.commercial_policy_history_sk AS VARCHAR(255)) as [id], -- commercial coverage sk
                cast(1 as varchar(255)) as [externalLocationIdentifier], -- send 1
                cast(1 as varchar(255)) as [externalRiskIdentifier], -- send 1
                prd.product_nm as code,
				'general_liability' as [type],
				-- send insured address
                json_query
                ((
                    select
						tp.mailing_address_line1 as address1,
                        tp.mailing_address_line2 as address2,
                        tp.mailing_address_city_nm as city,
                        tp.mailing_address_zip_cd as postalCode,
                        tp.mailing_address_state_cd as region,
                        'US' as country
                    for json path, include_null_values, without_array_wrapper
                )) as [address],
                json_query((
                    select
                        -- 'Test' as businessName,
                        --'individual_sole_proprietor ' as businessType
					'' as businessName,
					'' as businessType
                    for json path, include_null_values, without_array_wrapper
                )) as generalLiabilityDetails,
			--'{}' as [vehicle],
             --'[]' as [drivers],
                json_query
                (
                    (
						select
                        'Errors and Omissions' as [name],
                        'E&O' as [coverageCode],
                        null as [limits.amount],
                        null as [limits.deductible]
                     
                    for json path, include_null_values
					)                    
                ) as coverages                
                for json path, include_null_values
                ))
            )) as risks,
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as endorsements,
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as notes,            
            json_query
            (
                (
                select
                    'Errors and Omissions' as [name],
                    'E&O'as [coverageCode],
                    null as [limits.amount],
                    null as [limits.deductible]
                    for json path, include_null_values
                )
            )
            as coverages,
            json_query((
                select
                    tph.transaction_effective_dt as effectiveAt,
                    tph.expiration_dt as expirationAt,
                    tph.transaction_type as providerTypeDescription
                for json path, include_null_values

            )) as versions,            
            json_query            
            (
				(
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
				)
            ) as deductibles,
            ts.source_system_nm
        from
        [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp1] cpsa
         left join edw_commercial.tcommercial_policy_history tph on tph.commercial_policy_history_sk = cpsa.commercial_policy_history_sk
         left join edw_commercial.tcommercial_policy tp on tp.commercial_policy_sk = tph.commercial_policy_sk
		 left join edw_core.tcustomer AS c ON cpsa.customer_sk = c.customer_sk
		 left join edw_core.tsource_system ts on ts.source_system_sk = tp.source_system_sk
        -- left join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt -- Commented on 02/08/2025
        -- left join edw_core.tpolicy_history tph on tph.commercial_policy_sk = tp.commercial_policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no -- Commented on 02/08/2025
        left join edw_core.tproduct prd on prd.product_sk = tph.product_sk
        left join edw_core.tbroker tbrk on tph.broker_id = tbrk.broker_id		
		
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
        into edw_temp.claim_commercial_policy_webhook_snapsheet_api_temp2
        from
        policy_webhook

        INSERT INTO edw_integration.claim_policy_webhook_snapsheet_api
        (
            cancelledAt, cancelledReason, effectiveAt, expirationAt, inceptionAt, policyNumber,
            policyType, [status], [version], transaction_seq_no, agentInformation, product, reservation, underwriting,
            businesses,	people,	risks, coverages, endorsements, notes, versions,deductibles, [data] ,source_system_nm, create_ts, etl_audit_sk
        )	
	
        SELECT distinct
                cancelledAt, cancelledReason,	effectiveAt, expirationAt, inceptionAt, policyNumber,
            policyType, [status], [version], transaction_seq_no, agentInformation, product,reservation, underwriting,
            businesses,	people,	risks, coverages, endorsements, notes, versions, deductibles, [data] ,source_system_nm,
            getdate() as create_ts , @etl_audit_sk as etl_audit_sk
        FROM [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp2];  
    	
		SET @rows_affected=@@ROWCOUNT;

        --Vault litigation
        select *
        into [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp3]
        from
        (
          
        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2030-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'CVG7777VES' as policyNumber, 
        'general_liability' as policyType, 'Active' as [status], '2020-01-01' as [version],'0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Excess Liability","name":"Excess Liability"}' as [product],null as reservation,'{"account":"vault_es_insurance_litigation_co"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"CVG7777VES","code":"Excess Liability","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"general_liability","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"generalLiabilityDetails":{"businessName":"","businessType":""},"vehicle":{},"drivers":[],"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2030-12-31","providerTypeDescription":"New"}]' as versions, 
        null as deductibles,
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        
    ) as a
    where
        not exists(select 1 from   
        edw_integration.claim_policy_webhook_snapsheet_api cpw
        where
        cpw.policyNumber =a.policyNumber and cpw.effectiveAt= a.effectiveAt and cpw.transaction_seq_no= a.transaction_seq_no
        )
         INSERT INTO edw_integration.claim_policy_webhook_snapsheet_api
        (
            cancelledAt, cancelledReason, effectiveAt, expirationAt, inceptionAt, policyNumber,
            policyType, [status], [version], transaction_seq_no, agentInformation, product, reservation, underwriting,
            businesses,	people,	risks, coverages, endorsements, notes, versions,deductibles, [data] ,source_system_nm, create_ts, etl_audit_sk
        )	
	
        SELECT distinct
                cancelledAt, cancelledReason,	effectiveAt, expirationAt, inceptionAt, policyNumber,
            policyType, [status], [version], transaction_seq_no, agentInformation, product,reservation, underwriting,
            businesses,	people,	risks, coverages, endorsements, notes, versions, deductibles, [data] ,source_system_nm,
           create_ts ,  etl_audit_sk
        FROM [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp3];  
		

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp1] t1),@last_source_extract_ts);
	

        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp2];
        DROP TABLE IF EXISTS [edw_temp].[claim_commercial_policy_webhook_snapsheet_api_temp3];
       

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