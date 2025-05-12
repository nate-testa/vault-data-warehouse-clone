-- =================================================================================================
-- Description: This procedures insert policy webhook data for snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						                |	Change Description
---------------------------------------------------------------------------------------------------
--	09-30-2024				Yunus Mohammed				1 Created procedure
-- 01-06-2025               Yunus Mohammed             2 Enabled actual phone no and email (sending actual email and phone no). 
-- 02-08-2025               Yunus Mohammed             3 Captured all policy transactions and replced claim_policy_seach_snapsheet_api table
--                                                                                              with tpolicy_transaction
-- 02-12-2025               Yunus Mohammed              4 Removed deleted vehicles form Risks object
-- 03-13-2025				Yunus Mohammed				5 - Added vault litigation policies
-- 05-07-2025               Yunus Mohammed              6 - AD9410 Added new vault litigation policy
-- ================================================================================================= 
CREATE OR ALTER   PROCEDURE [edw_core].[sp_claim_policy_webhook_snapsheet_api]
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

        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp2];
        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp3];
        DROP TABLE IF EXISTS edw_temp.policy_webhook_home_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_auto_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_auto_vehicle_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_pel_coverages        
        
        SELECT distinct
            pt.policy_history_sk, pt.policy_sk,pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, 
            pt.source_system_sk, pt.item_sk, pt.vehicle_coverage_sk, pt.create_ts
        into [edw_temp].[claim_policy_webhook_snapsheet_api_temp1]
            FROM
            (
            select
                pt. *
            from
                edw_core.tpolicy_transaction pt
            where        
                cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
                and pt.source_system_sk != 1 and pt.product_sk != 6                 
            )as pt
            INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
            LEFT JOIN edw_core.tauto_vehicle_coverage AS avc ON pt.vehicle_coverage_sk = avc.auto_vehicle_coverage_sk
            WHERE
            CASE WHEN pr.product_cd = 'AU' AND pt.item_sk = 0 THEN 0  ELSE 1 END = 1
            AND CASE WHEN pr.product_cd = 'AU' AND avc.vehicle_deleted_in = 'Yes' THEN 0  ELSE 1 END = 1        

	declare @home_sql varchar(max) = ''
        select @home_sql = @home_sql + 'select cpsa.policy_history_sk, ''' + snapsheet_coverage_nm + ''' as  [name],''' 
        + coverage_type + ''' as coverage_type,'''
        + ISNULL(snapsheet_deductible_type,'') + ''' as deductible_type,'''
        + '' + snapsheet_coverage_cd +''' as [coverageCode],'
        + ' CAST('
        + column_nm + ' AS varchar(255)) as [limits.amount],'
        + ' null as [limits.coverageLimitType]' 
        + ' from
        [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa
        -- inner join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt -- Commented on 02/08/2025
        -- inner join edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no -- Commented on 02/08/2025
        inner join edw_core.' + table_nm + ' as source on source.policy_history_sk = cpsa.policy_history_sk
        union '
        from edw_stage.coverage_mapping_snapsheet
        where product_nm = 'Home/Condo' and snapsheet_coverage_nm != 'Not needed for day 1'
        and snapsheet_coverage_cd is not null
        and column_nm not in ( 'Need to bring over from UI')

        set @home_sql = ' select * into edw_temp.policy_webhook_home_coverages from (' +   (SUBSTRING(@home_sql,1,len(@home_sql)-5)) + ' ) as a '

        exec (@home_sql)

        declare @auto_sql varchar(max) = ''
        select @auto_sql = @auto_sql + 'select cpsa.policy_history_sk ,''' + snapsheet_coverage_nm + ''' as  [name],'''
		 + coverage_type + ''' as coverage_type,'''
         + snapsheet_coverage_cd +''' as [coverageCode],'
        + ' cast('
        + column_nm + ' AS varchar(255)) as [limits.amount],'
        + ' null as [limits.coverageLimitType]'
        + ' from
        [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa
        -- inner join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt
        -- inner join edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no
        inner join edw_core.' + table_nm + ' as source on source.policy_history_sk = cpsa.policy_history_sk
        union '
        from edw_stage.coverage_mapping_snapsheet
        where product_nm = 'Auto' and snapsheet_coverage_nm != 'Not needed for day 1'
        and snapsheet_coverage_cd is not null
        and column_nm != 'Need to bring over from UI'
        and table_nm = 'tauto_policy_coverage'

        set @auto_sql = ' select * into edw_temp.policy_webhook_auto_coverages from (' +   (SUBSTRING(@auto_sql,1,len(@auto_sql)-5)) + ' ) as a '

        exec (@auto_sql);

        declare @pel_sql varchar(max) = ''
        select @pel_sql = @pel_sql + 'select cpsa.policy_history_sk, ''' + snapsheet_coverage_nm + ''' as  [name],''' 
        + coverage_type + ''' as coverage_type,'
        + '''' + snapsheet_coverage_cd +''' as [coverageCode],'
        + ' case when isnumeric('+ column_nm +') = 1 then cast('
        + column_nm + ' AS varchar(255)) end as [limits.amount],'
        + ' null as [limits.coverageLimitType]' 
        + ' from
        [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa
        -- inner join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt
        -- inner join edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no
        inner join edw_core.' + table_nm + ' as source on source.policy_history_sk = cpsa.policy_history_sk
        union '
        from edw_stage.coverage_mapping_snapsheet
        where product_nm = 'Excess' and snapsheet_coverage_nm != 'Not needed for day 1'
        and snapsheet_coverage_cd is not null
        and column_nm not in ( 'Need to bring over from UI')

        set @pel_sql = ' select * into edw_temp.policy_webhook_pel_coverages from (' +   (SUBSTRING(@pel_sql,1,len(@pel_sql)-5)) + ' ) as a '
        exec (@pel_sql);

        declare @auto_vehicle_sql varchar(max) = ''
        select @auto_vehicle_sql = @auto_vehicle_sql + 'select cpsa.policy_history_sk, source.auto_vehicle_sk, ''' + snapsheet_coverage_nm + ''' as  [name],'''
		+ coverage_type + ''' as coverage_type,'''
        + snapsheet_coverage_cd +''' as [coverageCode],'
        + ' cast('
        + column_nm + ' AS varchar(255)) as [limits.amount],'
        + ' null as [limits.coverageLimitType]'
        + ' from
        [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa
        -- inner join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt
        -- inner join edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no
        inner join edw_core.' + table_nm + ' as source on source.policy_history_sk = cpsa.policy_history_sk
        union '
        from edw_stage.coverage_mapping_snapsheet
        where product_nm = 'Auto' and snapsheet_coverage_nm != 'Not needed for day 1'
        and snapsheet_coverage_cd is not null
        and column_nm not in ( 'Need to bring over from UI')
        and table_nm = 'tauto_vehicle_coverage'

        set @auto_vehicle_sql = ' select * into edw_temp.policy_webhook_auto_vehicle_coverages from (' +   (SUBSTRING(@auto_vehicle_sql,1,len(@auto_vehicle_sql)-5)) + ' ) as a '

        exec (@auto_vehicle_sql);


	with policy_webhook as
	(
    select
            FORMAT(tp.cancellation_effective_dt, 'yyyy-MM-ddTHH:mm:ssZ') AS cancelledAt,
            tph.cancellation_reason_desc  AS cancelledReason,
            FORMAT(tp.effective_dt, 'yyyy-MM-ddTHH:mm:ssZ') as effectiveAt,
    FORMAT(tp.expiration_dt, 'yyyy-MM-ddTHH:mm:ssZ') as expirationAt,
            FORMAT(tp.original_policy_effective_dt, 'yyyy-MM-ddTHH:mm:ssZ') as inceptionAt,
            tph.policy_no as policyNumber,
            case
                when prd.product_nm = 'Auto' then 'auto'
                when prd.product_nm in ('Homeowners','Condo','Collections') then 'property'
                when prd.product_nm = 'Excess Liability' then 'general_liability'
            end as policyType,
            tp.policy_status as [status],
            -- FORMAT(cpsa.inception_date, 'yyyy-MM-ddTHH:mm:ssZ') + '-'+ FORMAT(cpsa.expiration_dt, 'yyyy-MM-ddTHH:mm:ssZ') as [version],
            tph.transaction_effective_dt  as [version],
            cpsa.transaction_seq_no,
            --underwriting  means VRE and VES
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
                    prd.product_nm as code	,
                    prd.[product_nm] as [name]
                for json path, include_null_values, without_array_wrapper
            )
            ) as product,
            null as reservation,
            json_query((
                select
                    CASE
                    WHEN tp.uw_company_nm = 'Vault Reciprocal Exchange' THEN 'vault_reciprocal_exchange' 
                    WHEN tp.uw_company_nm = 'Vault E & S Insurance Company' THEN 'vault_es_insurance_company' ELSE ''
                END account
                for json path, include_null_values, without_array_wrapper
            )) as underwriting,
            json_query((
                select
                    [role],
                    temp.name as [name],
                    json_query((
                            SELECT
                                address1,
                                address2,
                                city,
                                postalCode,
                                region,
                                country
                                for json path, include_null_values, without_array_wrapper
                    )) as [address],
                    json_query((
						select *
						from
						(
                        SELECT
            'us' as country,
                    '1' as countryCode,
--                            'true' preferredMethod,
                            'phone' as [type],
                           -- '7272901574' as [value]
							phone_no as [value]                            
						UNION
						SELECT
                            null as country,
                            null as countryCode,
--                            'true' preferredMethod,
                            'email' as [type],
							--'Farhad.Imam@Vault.Insurance' as [value]
							email as [value]                        
						) as temp
                        for json path, include_null_values
                    )) as contactMethods
                from
             (	
                    select 'mortgagee' as [role],mortgagee_nm as [name],
                    address_line_1 as address1, address_line_2 as address2, city_nm as city, zip_cd as postalCode, state_cd as region, country_nm as country
					, phone_no, email
                    from edw_core.tmortgagee tm
                    where
                        tm.policy_no = tp.policy_no
                        and tm.effective_dt = tp.effective_dt
                        and tm.transaction_seq_no = cpsa.transaction_seq_no
                    union
                    select 
                        case
                            when interest_type = 'Loss Payee' then 'loss_payee'
                            when interest_type in ('Additional Insured - Contents','Additional Insured - Individual','Additional Insured - Limited Liability') then 'additional_insured'
                        else 'Other'
                        end as [role],
                        case
                            when interest_type = 'Loss Payee' and entity_type = 'Individual' then CONCAT_WS(' ',first_nm,last_nm)
                            when interest_type = 'Loss Payee' then loss_payee_nm
                            when entity_type = 'Individual' then CONCAT_WS(' ',first_nm,last_nm)
                            else additional_interest_nm
                        end as [name],
                    address_line_1 as address1, address_line_2 as address2, city_nm as city, zip_cd as postalCode, state_cd as region, country_nm as country,
					null as phone_no,
					null as email
                    from edw_core.tadditional_interest tadi
                    where
                        tadi.policy_no = tp.policy_no
                        and tadi.effective_dt = tp.effective_dt
                        and tadi.transaction_seq_no = cpsa.transaction_seq_no
                ) as temp
                    
                for json path, include_null_values
            )) as [businesses],
            ((

                select
                    tpi.first_nm as firstName,
                    tpi.middle_nm as middleName,
                    tpi.last_nm as lastName,
                    case
                        when tpi.primary_insured_in = 'Yes' then 'policyholder'
                        else 'additional_insured'
                    end as [role],
                    -- null as providerSubjectId it can be primary_key
                    json_query((
                        SELECT
                            tpi.mailing_address_line_1 as address1,
                            tpi.mailing_address_line_2 as address2,
                            tpi.mailing_address_city_nm as city,
                            tpi.mailing_address_zip_cd as postalCode,
                            tpi.mailing_address_state_cd as region,
                            tpi.mailing_address_country_nm as country
                            for json path, include_null_values, without_array_wrapper			
                    )) as [address],
                    json_query((
                    SELECT *
                    FROM
                    (
       SELECT
                        'us' as country,
                        '1' as countryCode,
--                        'true' preferredMethod,
                        'phone' as [type],
                       --'7272901574' as [value] 
                        coalesce(home_phone_no,mobile_phone_no) as [value]
                    UNION
                     SELECT
                        null as country,
                        null as countryCode,
--                        'true' preferredMethod,
                        'email' as [type],
                       -- 'Farhad.Imam@Vault.Insurance' as [value] 
                        email as [value]
                    ) as a
                    for json path, include_null_values
                    )) as contactMethods
                from
                    edw_core.tpolicy_insured tpi
                where
                    tpi.policy_no = tp.policy_no and
                    tpi.effective_dt = tp.effective_dt and
                    tpi.transaction_seq_no = cpsa.transaction_seq_no
                for json path, include_null_values

            )) as people,
            json_query((
            case
                when prd.product_cd IN ('HO','CO') then
                json_query((
                    select
                        CAST(hl.home_location_sk AS VARCHAR(255)) as id,
                        prd.product_nm as code,
                        '1' as externalLocationIdentifier,
                        '1' as externalRiskIdentifier,
                        'home' as [type],
                        json_query((
                            select
                                hl.address_line_1 as address1, 
                                hl.address_line_2 as address2,
                                hl.city_nm  as city,
                                hl.zip_cd as postalCode,
                                hl.state_cd as region,
                                hl.country_nm as country
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
                            select *
                            from
                            (
                                select
                                    [name],
                                    [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
                                    /*case
                                    when coverage_type = 'Limit' and deductible_type = '' then 
                                        [coverage.limits.amount]
                                    end as [coverage.limits.amount],
                                    [limits.coverageLimitType],
                                    case
                                    when coverage_type = 'Deductible' and deductible_type = '' then 
                                        [coverage.limits.amount]
                                    end as [limits.deductible]
                                    */
                                    from 
                                        edw_temp.policy_webhook_home_coverages a
                                    where
                                    a.policy_history_sk = tph.policy_history_sk
									and a.coverage_type in ('Limit','Indicator')
                                    and
										(
											[limits.amount] is not null or 
											(
												coverage_type = 'Indicator'
												and  [limits.amount] ='Yes'
											)
										)
                                        /*(
                                        deductible_type != ''
                                        or (deductible_type = '' and [limits.amount] is not null)
                                        ) */                               

                                UNION

                                SELECT
                                    'HO Collections - Scheduled' as [name],
                                    'HCOSC' as [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
                                    /*
                                    sum(scheduled_limit_amt) as [coverage.limits.amount],
                                    null as [limits.coverageLimitType],
                                    null as [limits.deductible]
                                    */
                                FROM
									edw_core.tcollection_class_type tct
                                where
                                    tct.policy_history_sk = tph.policy_history_sk
                                    and [scheduled_limit_amt] is not null
                                group by tct.policy_history_sk

								UNION

                                SELECT
                                    'HO Collections - Blanket' as [name],
                                    'HCOBL' as [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
                                    /*
                                    sum(blanket_limit_amt) as [coverage.limits.amount],
                                    null as [limits.coverageLimitType],
                                    null as [limits.deductible]
                                    */
                                FROM
									edw_core.tcollection_class_type tct
                                where
                                    tct.policy_history_sk = tph.policy_history_sk
                                    and blanket_limit_amt is not null
                                group by tct.policy_history_sk

                            ) as a	for json path, include_null_values
                        )
                        ) as coverages
                    from
                        edw_core.thome_location hl
                    where
                        hl.policy_no = tp.policy_no
                        and hl.effective_dt = tp.effective_dt
                    for json path, include_null_values
                ))
            when prd.product_cd = 'AU' then
                JSON_QUERY
                ((
                select
                CAST(tav.auto_vehicle_sk AS VARCHAR(255)) as [id],
                CAST(location_identifier as varchar(255)) as [externalLocationIdentifier],
                CAST(vehicle_identifier as varchar(255)) as [externalRiskIdentifier],
                prd.product_nm as code,
                'motor' as [type],
                tav.vehicle_make as [vehicle.make],
                tav.vehicle_model as [vehicle.model],
                tav.vehicle_vin as [vehicle.vinNumber],
                tav.vehicle_model_year as [vehicle.year],
                tav.vehicle_type as [vehicle.code],
                tav.vehicle_type as [vehicle.codeDescription],	
                json_query((
                            select
                                tag.garage_address_line1 as address1, 
                                tag.garage_address_line2 as address2,
                                tag.garage_address_city_nm  as city,
                                tag.garage_address_zip_code as postalCode,
                                tag.garage_address_state_cd as region,
                                tag.garage_address_country_nm as country
                            for json path, include_null_values, without_array_wrapper
                        )) as [address],
               /* JSON_QUERY
                (

                    (
                        select
                            'registration' as locationType,
                            tag.garage_address_line1 as [address.address1], 
                            tag.garage_address_line2 as [address.address2], 
                            tag.garage_address_city_nm [address.city],
                            tag.garage_address_zip_code as [address.postalCode],
                            tag.garage_address_state_cd as [address.region], 
                            tag.garage_address_country_nm as [address.country]
                        for json path, include_null_values 

                    )
                ) as vehicleLocations,*/
                
                json_query((
                    select
                        prefix as [prefix], first_nm as [firstName], middle_nm as [middleName], last_nm as [lastName],
                        suffix as [suffix], null as [dateOfBirth], gender as [gender],license_country_nm as [licenseIssuingCountry],
      license_no as [licenseNumber]
                    from
                        edw_core.tauto_driver tad
                    where
                        tad.policy_history_sk = tph.policy_history_sk
                    for json path, include_null_values
                )) as [drivers],
                json_query
                    (
                        (
                        select 
                            [name],
                            [coverageCode],
                            [limits.amount],
                            [limits.deductible]
                        from 
                        (
                            select
                                [name],
                                [coverageCode],
                                null as [limits.amount],
                                null as [limits.deductible]
                                /*
                                [limits.amount],
                                [limits.coverageLimitType]
                                */
                            from edw_temp.policy_webhook_auto_vehicle_coverages a
                            where a.auto_vehicle_sk = tav.auto_vehicle_sk
                                and a.policy_history_sk = tph.policy_history_sk
                                and a.coverage_type in ('Limit','Indicator','Deductible')
                                and ( [limits.amount] is not null 
                                    or ( a.coverage_type = 'Indicator' and  [limits.amount] ='Yes')
                                )

                            union all

                            select
                                [name],
                                [coverageCode],
                                null as [limits.amount],
                                null as [limits.deductible]
                                /*
                                [limits.amount],
                                [limits.coverageLimitType]
                                */
                            from edw_temp.policy_webhook_auto_coverages a
                            where a.policy_history_sk = tph.policy_history_sk
                                and a.coverage_type in ('Limit','Indicator')
                                and ( [limits.amount] is not null 
                                    or ( a.coverage_type = 'Indicator' and  [limits.amount] ='Yes')
               )
                        ) as tbl
        for json path, include_null_values
                        )
                    ) as coverages
                from
                    (
                        select 
                            ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY vehicle_unique_id) AS vehicle_identifier,*
                        from
                        edw_core.tauto_vehicle 
                    ) as tav
                    inner join edw_core.tauto_vehicle_coverage as tavc on tavc.auto_vehicle_sk = tav.auto_vehicle_sk
                    and tavc.policy_history_sk = cpsa.policy_history_sk
                    left join
                        (
                            select
                                ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt, 
                            transaction_seq_no ORDER BY garage_unique_id) AS location_identifier,*
                            from
                            edw_core.tauto_garage_location
                        ) as tag ON tag.auto_garage_location_sk = tavc.auto_garage_location_sk
                where      
                 tav.policy_no = tp.policy_no
                    and tav.effective_dt = tp.effective_dt
                    and tavc.transaction_seq_no = cpsa.transaction_seq_no             
					and	exists(
										select 1 from [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa1
										where
											cpsa1.policy_history_sk = cpsa.policy_history_sk
											and cpsa1.item_sk = tav.auto_vehicle_sk
								)
              
                    
                for json path, include_null_values
    ))
            when prd.product_cd = 'PEL' then
                JSON_QUERY
                ((
                select
                CAST(pl.pel_location_sk AS VARCHAR(255)) as [id],
                cast(location_identifier as varchar(255)) as [externalLocationIdentifier],
                cast(ISNULL(vehicle_identifier,location_identifier) as varchar(255)) as [externalRiskIdentifier],
                prd.product_nm as code,
				case when tpv.pel_vehicle_sk is null then 'general_liability' else 'motor' end as [type],
                json_query
                ((
                    select
                        pl.address_line_1 as address1, 
                        pl.address_line_2 as address2,
                        pl.city_nm  as city,
                        pl.zip_cd as postalCode,
                        pl.state_cd as region,
                        pl.country_nm as country
                    for json path, include_null_values, without_array_wrapper
                )) as [address],
/*
--START - ADDED FOR TESTING - 11132024--

                        json_query((
                            select
                                'building_and_personal_property' as propertyType,
                                'policy_address' as propertyLocation
                            for json path, include_null_values, without_array_wrapper
                        )) as property,
--END - ADDED FOR TESTING - 11132024--
*/
--START - ADDED per new documentation - 11142024--

                        json_query((
                            select
                                -- 'Test' as businessName,
                                --'individual_sole_proprietor ' as businessType
							'' as businessName,
							'' as businessType
                            for json path, include_null_values, without_array_wrapper
                        )) as generalLiabilityDetails,

--END - ADDED per new documentation - 11142024--

--START - ADDED FOR TESTING - 11142024--
isnull(
                json_query((
                    select
                        tpv.vehicle_make as [make], tpv.vehicle_model as [model], tpv.vehicle_vin as [vinNumber], tpv.vehicle_year as [year]
                    WHERE
                        tpv.pel_vehicle_sk is not null
                       -- and isnull(pl.primary_location_in,'No') = 'Yes'
                    for json path, include_null_values, without_array_wrapper
                )), '{}'
            ) as [vehicle],
--START - END FOR TESTING - 11142024--

--START - COMMENTED OUT FOR TESTING - 11142024--
--                tpv.vehicle_make as [vehicle.make],
--                tpv.vehicle_model as [vehicle.model],
--                tpv.vehicle_vin as [vehicle.vinNumber],
--        tpv.vehicle_year as [vehicle.year],
--END - COMMENTED OUT FOR TESTING - 11142024--
            isnull(
                json_query((
                    select
                        prefix as [prefix], first_nm as [firstName], middle_nm as [middleName], last_nm as [lastName],
                        suffix as [suffix],null as [dateOfBirth], license_country_nm as [licenseIssuingCountry],
                        license_no as [licenseNumber]
                    from
                        edw_core.tpel_driver tpd
                    where
                        tpd.policy_no = tp.policy_no and
                        tpd.effective_dt = tp.effective_dt and
                        tpd.transaction_seq_no = cpsa.transaction_seq_no
                        and tpv.pel_vehicle_sk is not null
                       -- and isnull(pl.primary_location_in,'No') = 'Yes'
                    for json path, include_null_values
                )) , '[]'
                ) as [drivers],
                json_query
                (
                    (
                    select
                        [name],
                        [coverageCode],
                        null as [limits.amount],
                        null as [limits.deductible]
                        /*
                        case
                            when coverage_type = 'Limit' then 
                                [coverage.limits.amount]
                        end as [coverage.limits.amount],
                        [limits.coverageLimitType],
                        case
                            when coverage_type = 'Deductible' then 
                                [coverage.limits.amount]
                        end as [limits.deductible],
                        */
                    from 
                        edw_temp.policy_webhook_pel_coverages a
                    where
                        a.policy_history_sk = tph.policy_history_sk
						and a.coverage_type in ('Limit','Indicator')
                        and ( [limits.amount] is not null 
                                    or ( a.coverage_type = 'Indicator' and  [limits.amount] ='Yes')
                                )
                    for json path, include_null_values
                    )
                ) as coverages
                from
                    (
                        select ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt, transaction_seq_no ORDER BY location_no) AS location_identifier,*
                        from
                            [edw_core].[tpel_location]
                        where
                            policy_history_sk = tph.policy_history_sk	
                    )as	pl
                    left join 
                    (
                        select 
                            ROW_NUMBER() OVER(PARTITION BY pv.policy_no, pv.effective_dt,pv.transaction_seq_no ORDER BY vehicle_unique_id) AS vehicle_identifier,pv.*
                        from
                            edw_core.tpel_vehicle pv
                        WHERE
                            pv.policy_history_sk = tph.policy_history_sk
                    ) as tpv on tpv.policy_history_sk = pl.policy_history_sk
                for json path, include_null_values
                ))
            when prd.product_cd = 'LUX' then
                JSON_QUERY
                ((
                select
                CAST(cl.collection_location_sk AS VARCHAR(255)) as [id],
                '1' as [externalLocationIdentifier],
                '1' as [externalRiskIdentifier],
                prd.product_nm as code,
                'inland_marine' as [type],
                json_query
                ((
                    select
                        cl.address_line_1 as address1, 
                        cl.address_line_2 as address2,
                        cl.city_nm  as city,
                   cl.zip_cd as postalCode,
                        cl.state_cd as region,
                        cl.country_nm as country
                    for json path, include_null_values, without_array_wrapper
                )) as [address],
--START - ADDED FOR TESTING - 11132024--
                        json_query((
                            select
                                'other' as fireProtection,
                                'other' as security,
                                'other_assets' as propertyValue
                            for json path, include_null_values, without_array_wrapper
                        )) as inlandMarineDetails,
--END - ADDED FOR TESTING - 11132024--
                isnull(json_query
                    (
                        (
                            select
                            case coverageCode
                                when 'COBL' then 'Collections - Blanket Limit'
								when 'COSC' then 'Collections - Scheduled'
                            end as [name],
                            coverageCode,
                            null as [limits.amount],
                            null as [limits.deductible]
                            /*
                            (
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
                                   sum(blanket_limit_amt) as COBL,
                                   sum(scheduled_limit_amt) as COSC
                                   -- 100 as COBL,
                                   -- 100 as COSC
                                FROM
                                    edw_core.tcollection_class_type tct
                                WHERE
                                    tct.policy_history_sk = tph.policy_history_sk
                                group by tct.policy_history_sk							
                            ) as sourcetable
                        unpivot
                        (
                            Limit For coverageCode in (COBL,COSC)
                        ) as unpvt
                        WHERE 
                            isnull(limit,0) > 0
                        for json path, include_null_values
                        )
                    
                    ),'[]') as coverages
                from
                    edw_core.tcollection_location cl		
                    where
                        cl.policy_no = tp.policy_no
                        and cl.effective_dt = tp.effective_dt
                
                for json path, include_null_values
                ))
            end )) as risks,
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as endorsements,
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            ) as notes,
            json_query
            ((
            case
                when prd.product_cd IN ('HO','CO') then
                    json_query
                        (
                        (
                            select *
                            from
                            (
                                select
                                    [name],
                                    [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
  /*
                                    case
                                    when coverage_type = 'Limit' and deductible_type = '' then 
                                        [coverage.limits.amount]
                                    end as [coverage.limits.amount],
                                    [limits.coverageLimitType],
                                    case
                                    when coverage_type = 'Deductible' and deductible_type = '' then 
                                        [limits.amount]
                                    end as [coverage.limits.deductible]
                                    */
                                    from 
                                        edw_temp.policy_webhook_home_coverages a
                                    where
                                    a.policy_history_sk = tph.policy_history_sk
									and coverage_type in ('Limit','Indicator')
                                   	and
									(
										[limits.amount] is not null or 
										(
											coverage_type = 'Indicator'
											and  [limits.amount] ='Yes'
										)
									)
                                    /*(
                                        deductible_type != ''
                                        or (deductible_type = '' and [coverage.limits.amount] is not null)
                                    )*/
                                union
                               SELECT
                                    'HO Collections - Scheduled' as [name],
                                    'HCOSC' as [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
                                    /*
                                    sum(scheduled_limit_amt) as [coverage.limits.amount],
                                    null as [limits.coverageLimitType],
                                    null as [limits.deductible]
                                    */
                                FROM
									edw_core.tcollection_class_type tct
                                where
                                    tct.policy_history_sk = tph.policy_history_sk
                                    and [scheduled_limit_amt] is not null
                                group by tct.policy_history_sk

								UNION

                                SELECT
                                    'HO Collections - Blanket' as [name],
                                    'HCOBL' as [coverageCode],
                                    null as [limits.amount],
                                    null as [limits.deductible]
                                    /*
                                    sum(blanket_limit_amt) as [coverage.limits.amount],
                                    null as [limits.coverageLimitType],
                                    null as [limits.deductible]
                                    */
                                FROM
									edw_core.tcollection_class_type tct
                                where
                                    tct.policy_history_sk = tph.policy_history_sk
                                    and blanket_limit_amt is not null
                                group by tct.policy_history_sk
                            ) as a	for json path, include_null_values
                        )
                        )
                when prd.product_cd = 'AU' then
                    json_query
                    (
                        (
                            select
                                [name],
                                [coverageCode],
                                null as [limits.amount],
                                null as [limits.deductible]
                                /*
                                [coverage.limits.amount],
                              [coverage.limits.coverageLimitType]
                                */
                    from 
                                edw_temp.policy_webhook_auto_coverages a
                            where
                                a.policy_history_sk = tph.policy_history_sk
								and coverage_type in ('Limit','Indicator')
								and
								(
									[limits.amount] is not null or 
									(
										coverage_type = 'Indicator'
										and  [limits.amount] ='Yes'
									)
								)
                            for json path, include_null_values
                        )
                    )
                when prd.product_cd = 'PEL' then
                    json_query
                    (
                        (
                        select
                            [name],
                            [coverageCode],
                            null as [limits.amount],
                            null as [limits.deductible]
                /*
                            case
                                when coverage_type = 'Limit' then 
                                    [coverage.limits.amount]
                            end as [coverage.limits.amount],
                            [coverage.limits.coverageLimitType],
                            case
                                when coverage_type = 'Deductible' then 
                                    [coverage.limits.amount]
                            end as [coverage.limits.deductible],
                            */
                        from 
                            edw_temp.policy_webhook_pel_coverages a
                        where
                            a.policy_history_sk = tph.policy_history_sk
							and coverage_type in ('Limit','Indicator')
                            and
								(
									[limits.amount] is not null or 
									(
										coverage_type = 'Indicator'
										and  [limits.amount] ='Yes'
									)
								)
                            for json path, include_null_values
                        )
                    )
                when prd.product_cd = 'LUX' then
                    ISNULL(json_query
                    (
                        (
                            select
                            case coverageCode
                                when 'COBL' then 'Collections - Blanket Limit'
                                when 'COSC' then 'Collections - Scheduled'
                            end as [name],
                            coverageCode,
                            null as [limits.amount],
                            null as [limits.deductible]
                            /*
                            (
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
                                    sum(blanket_limit_amt) as COBL,
                                    sum(scheduled_limit_amt) as COSC
                                    -- 100 as COBL,
                                   -- 100 as COSC
                                FROM
                                    edw_core.tcollection_coverage as tcc
                                    inner join edw_core.tcollection_class_type tct on tct.collection_coverage_sk = tcc.collection_coverage_sk
                                WHERE
                                    tcc.policy_history_sk = tph.policy_history_sk
                                group by tcc.policy_history_sk
                        ) as sourcetable
                        unpivot
                        (
                            Limit For coverageCode in (COBL,COSC)
                     ) as unpvt
                        WHERE
                            ISNULL(Limit,0) > 0
                        for json path, include_null_values
                        )
                    ),'[]')
                end )) as coverages,
            json_query((
                select
                    tph.transaction_effective_dt as effectiveAt,
                    tph.expiration_dt as expirationAt,
                    tph.transaction_type as providerTypeDescription
                for json path, include_null_values

            )) as versions,		
            case when prd.product_cd in ('HO','CO') then
            json_query
            ((	
            select distinct
                deductible_type as deductibleType
                ,null as amount,
                null as [percent]
            from
                edw_temp.policy_webhook_home_coverages a
            WHERE
                deductible_type != ''
                and [limits.amount] is not null
                and a.policy_history_sk = tph.policy_history_sk
                and isnull([limits.amount],'0')!= '0'
            for json path, include_null_values
            )
            )
            else
            (
                select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
            )
            end as deductibles,
            ts.source_system_nm
        from
        [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] cpsa
         left join edw_core.tpolicy_history tph on tph.policy_history_sk = cpsa.policy_history_sk
         left join edw_core.tpolicy tp on tp.policy_sk = tph.policy_sk
		 left join edw_core.tsource_system ts on ts.source_system_sk = tp.source_system_sk
        -- left join edw_core.tpolicy tp on cpsa.policyNumber = tp.policy_no and tp.effective_dt = tp.effective_dt -- Commented on 02/08/2025
        -- left join edw_core.tpolicy_history tph on tph.policy_sk = tp.policy_sk and tph.transaction_seq_no = cpsa.transaction_seq_no -- Commented on 02/08/2025
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
        into edw_temp.claim_policy_webhook_snapsheet_api_temp2
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
        FROM [edw_temp].[claim_policy_webhook_snapsheet_api_temp2];  
    	
		SET @rows_affected=@@ROWCOUNT;

        --Vault litigation
        select *
        into [edw_temp].[claim_policy_webhook_snapsheet_api_temp3]
        from
        (
                select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt,'2020-01-01T00:00:00Z' as inceptionAt, 'FPP9999VES' as policyNumber, 
        'property' as policyType, 'Active' as [status], '2020-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Homeowners","name":"Homeowners"}' as [product], null as reservation,'{"account":"vault_es_insurance_litigation_co"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses, 
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"FPP9999VES","code":"Homeowners","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"home","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"property":{"propertyType":"building_and_personal_property","propertyLocation":"policy_address"},"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        '[{"deductibleType":"base","amount":null,"percent":null}]' as deductibles, 
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        union 

        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'FPP9999VRE' as policyNumber, 
        'property' as policyType,'Active' as [status], '2020-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation,
        '{"code":"Homeowners","name":"Homeowners"}' as [product], null as reservation,'{"account":"vault_reciprocal_exchange_litigation"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"FPP9999VRE","code":"Homeowners","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"home","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"property":{"propertyType":"building_and_personal_property","propertyLocation":"policy_address"},"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        '[{"deductibleType":"base","amount":null,"percent":null}]' as deductibles, 
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        union 

        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'COV9999VES' as policyNumber, 
        'general_liability' as policyType, 'Active' as [status], '2020-01-01' as [version],'0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Excess Liability","name":"Excess Liability"}' as [product],null as reservation,'{"account":"vault_es_insurance_litigation_co"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"COV9999VES","code":"Excess Liability","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"general_liability","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"generalLiabilityDetails":{"businessName":"","businessType":""},"vehicle":{},"drivers":[],"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        null as deductibles,
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        union
        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'COV9999VRE' as policyNumber, 
        'general_liability' as policyType, 'Active' as [status], '2020-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Excess Liability","name":"Excess Liability"}' as [product], null  as reservation,'{"account":"vault_reciprocal_exchange_litigation"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"COV9999VRE","code":"Excess Liability","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"general_liability","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"generalLiabilityDetails":{"businessName":"","businessType":""},"vehicle":{},"drivers":[],"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Coverage","coverageCode":"COV","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        null as deductibles,
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        union
        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'AU9999VES' as policyNumber, 
        'auto' as policyType, 'Active' as [status], '2020-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Auto","name":"Auto"}' as [product], null as reservation,'{"account":"vault_es_insurance_litigation_co"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Liability","coverageCode":"LIB","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"AU9999VES","externalLocationIdentifier":"1","externalRiskIdentifier":"1","code":"Auto","type":"motor","vehicle":{"make":"ABC","model":"ABC","vinNumber":"ABC","year":2020,"code":"Private Passenger Auto","codeDescription":"Private Passenger Auto"},"address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"drivers":[{"prefix":null,"firstName":"Vault","middleName":null,"lastName":"insurance","suffix":"","dateOfBirth":null,"gender":"","licenseIssuingCountry":"US","licenseNumber":""}],"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Liability","coverageCode":"LIB","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        null as deductibles,
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
        union
        select
        null as cancelledAt,null as cancelledReason,'2020-01-01T00:00:00Z' as effectiveAt,'2026-12-31T00:00:00Z' as expirationAt, '2020-01-01T00:00:00Z' as inceptionAt, 'AU9999VRE' as policyNumber, 
        'auto' as policyType, 'Active' as [status], '2020-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation, 
        '{"code":"Auto","name":"Auto"}' as [product],null as reservation,'{"account":"vault_reciprocal_exchange_litigation"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Liability","coverageCode":"LIB","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"AU9999VRE","externalLocationIdentifier":"1","externalRiskIdentifier":"1","code":"Auto","type":"motor","vehicle":{"make":"ABC","model":"ABC","vinNumber":"ABC","year":2020,"code":"Private Passenger Auto","codeDescription":"Private Passenger Auto"},"address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"drivers":[{"prefix":null,"firstName":"Vault","middleName":null,"lastName":"insurance","suffix":"","dateOfBirth":null,"gender":"","licenseIssuingCountry":"US","licenseNumber":""}],"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Liability","coverageCode":"LIB","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2020-01-01","expirationAt":"2026-12-31","providerTypeDescription":"New"}]' as versions, 
        null as deductibles,
        'Metal' as source_system_nm, null as [data],GETDATE() as create_ts,@etl_audit_sk as etl_audit_sk
         union
       select
        null as cancelledAt,null as cancelledReason,'2015-01-01T00:00:00Z' as effectiveAt,'2019-12-31T00:00:00Z' as expirationAt, '2015-01-01T00:00:00Z' as inceptionAt, 'FPP9998VRE' as policyNumber, 
        'property' as policyType,'Active' as [status], '2015-01-01' as [version], '0' as transaction_seq_no, 
        '{"agencyCode":"56536","agencyName":"Vault Custom Risk Solutions, LLC","agencyType":"broker","agencyAddress":{"address1":"24 West","address2":"40th Street","city":"New York","postalCode":"10018","region":"NY","country":"US"},"agencyContactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}' as agentInformation,
        '{"code":"Homeowners","name":"Homeowners"}' as [product], null as reservation,'{"account":"vault_reciprocal_exchange_litigation"}' as underwriting, 
        '[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]' as coverages, 
        '[]' as endorsements,'[]' as notes,null as businesses,
        '[{"firstName":"Vault","middleName":null,"lastName":"Insurance","role":"policyholder","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"contactMethods":[{"country":null,"countryCode":null,"type":"email","value":null},{"country":"us","countryCode":"1","type":"phone","value":null}]}]' as people, 
        '[{"id":"FPP9998VRE","code":"Homeowners","externalLocationIdentifier":"1","externalRiskIdentifier":"1","type":"home","address":{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg","postalCode":"33701","region":"FL","country":"US"},"property":{"propertyType":"building_and_personal_property","propertyLocation":"policy_address"},"coverages":[{"name":"Extra Contractual","coverageCode":"EC","limits":{"amount":null,"deductible":null}},{"name":"Dwelling","coverageCode":"COV-A","limits":{"amount":null,"deductible":null}}]}]' as risks,
        '[{"effectiveAt":"2015-01-01","expirationAt":"2019-12-31","providerTypeDescription":"New"}]' as versions, 
        '[{"deductibleType":"base","amount":null,"percent":null}]' as deductibles, 
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
        FROM [edw_temp].[claim_policy_webhook_snapsheet_api_temp3];  
		

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM [edw_temp].[claim_policy_webhook_snapsheet_api_temp1] t1),@last_source_extract_ts);
	

        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp1];
        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp2];
        DROP TABLE IF EXISTS [edw_temp].[claim_policy_webhook_snapsheet_api_temp3];
        DROP TABLE IF EXISTS edw_temp.policy_webhook_home_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_auto_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_auto_vehicle_coverages
        DROP TABLE IF EXISTS edw_temp.policy_webhook_pel_coverages
	

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