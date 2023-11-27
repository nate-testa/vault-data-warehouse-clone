SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-29
-- Description: This stored procedure insert and update info related to policy_ivans_auto_feed.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_ivans_auto_feed]
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

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_auto_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_transaction_temp1];

        SELECT 
            policy_sk, effective_dt_sk, transaction_seq_no, transaction_effective_dt_sk, transaction_dt_sk, customer_sk, policy_transaction_type_sk, source_system_sk,
            MAX(create_ts) as create_ts, 
            SUM(premium_amt) as premium_amt,
            SUM(annual_premium_amt) as annual_premium_amt
        INTO [edw_temp].[policy_transaction_temp1]
        FROM edw_core.tpolicy_transaction as pt
        INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
        WHERE 1=1
            AND pr.product_cd = 'AU'
            AND cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
        GROUP BY policy_sk, effective_dt_sk, transaction_seq_no, transaction_effective_dt_sk, transaction_dt_sk, customer_sk, policy_transaction_type_sk, source_system_sk
        ;



        WITH 
        loss_history AS (
            SELECT 
                policy_no, effective_dt, transaction_seq_no, max(loss_seq_no) as loss_seq_no 
            FROM 
                edw_core.tloss_history
            GROUP BY 
                policy_no, effective_dt, transaction_seq_no
        ),
        original_policy AS (
            SELECT original_policy_no, min(effective_dt) as min_effective_dt, min(expiration_dt) as min_expiration_dt, min(original_policy_effective_dt) as min_original_policy_effective_dt
                FROM edw_core.tpolicy 
            GROUP BY original_policy_no                
        ),
        json_au_coverages AS (
            SELECT ptf.policy_sk, ptf.effective_dt_sk ,ptf.transaction_seq_no,
                (
                    SELECT  
                        CASE 
                            WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Underinsured Motorist'    THEN 'umCSLPrem'
                            WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Uninsured Motorist'    THEN 'umCSLPrem'
                            ELSE ic.internal_coverage_cd
                        END AS coverageCd,
                        CASE 
                            WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Underinsured Motorist'    THEN 'umCSLPrem'
                            WHEN apc.limit_type = 'Combined' AND ic.internal_coverage_cd='Uninsured Motorist'    THEN 'umCSLPrem'
                            ELSE ic.internal_coverage_desc
                        END AS coverageDesc,
                        CASE 
                            WHEN apc.limit_type = 'Combined' then apc.combined_single_limit_amt
                            WHEN ic.internal_coverage_cd = 'Added First Party' then apc.added_first_party_limit_amt
                            WHEN ic.internal_coverage_cd = 'Bodily Injury' then apc.bodily_injury_limit_amt
                            WHEN ic.internal_coverage_cd = 'Basic First Party' then apc.combination_fpb_limit_amt
                            WHEN ic.internal_coverage_cd = 'Auto Death Disability' then apc.accidental_death_benefit_limit_amt
                            WHEN ic.internal_coverage_cd = 'Medical Payments' then apc.medical_payment_limit_amt
                            WHEN ic.internal_coverage_cd = 'Personal Injury Protection' then apc.pip_limit_amt
                            WHEN ic.internal_coverage_cd = 'Property Damage' then apc.property_damage_limit_amt
                            WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_underinsured_motorist_limit_amt
                            WHEN ic.internal_coverage_cd = 'Underinsured Motorist' AND apc.limit_type = 'Split' then apc.underinsured_motorist_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Combined' then apc.combined_uninsured_motorist_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Combined' then apc.combined_um_bi_policy_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Combined' then apc.combined_um_pd_policy_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Motorist' AND apc.limit_type = 'Split' then apc.uninsured_motorist_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Bodily Injury' AND apc.limit_type = 'Split' then apc.um_bi_policy_limit_amt
                            WHEN ic.internal_coverage_cd = 'Uninsured Property Damage' AND apc.limit_type = 'Split' then apc.um_pd_policy_limit_amt 
                            ELSE '' 
                        END 	AS limits,
                        pt.annual_premium_amt AS currentTermAmt,
                        pt.premium_amt AS netChangeAmt
                        FROM 
                            (
                                SELECT 
                                    policy_sk, effective_dt_sk, transaction_seq_no, coverage_sk, internal_coverage_sk,
                                    SUM(annual_premium_amt) AS annual_premium_amt, 
                                    SUM(premium_amt) AS premium_amt 
                                FROM edw_core.tpolicy_transaction as pt
                                INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
                                WHERE 1=1
                                    AND pr.product_cd = 'AU'
                                AND cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
                                GROUP BY policy_sk, effective_dt_sk, transaction_seq_no, coverage_sk, internal_coverage_sk
                            ) as pt 
                            INNER JOIN edw_core.tauto_policy_coverage as apc ON pt.coverage_sk = apc.auto_policy_coverage_sk
                            INNER JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
                        WHERE  1=1
                            AND pt.policy_sk = ptf.policy_sk
                            AND pt.effective_dt_sk = ptf.effective_dt_sk
                            AND pt.transaction_seq_no = ptf.transaction_seq_no
                        FOR JSON PATH
                ) AS AU_Coverages
                FROM [edw_temp].[policy_transaction_temp1] as ptf
                GROUP BY ptf.policy_sk, ptf.effective_dt_sk ,ptf.transaction_seq_no
        ),
        json_au_vehicles_sub_coverages AS (
            SELECT 
                avc.policy_no, 
                avc.effective_dt, 
                avc.transaction_seq_no, 
                avc.vehicle_no,
                CASE 
                    WHEN ic.internal_coverage_desc IN ('Underinsured Motorist','Uninsured Motorist') THEN 'um_uim_Prem'
                    ELSE ic.internal_coverage_cd
                END AS coverageCd,
                CASE 
                    WHEN ic.internal_coverage_desc = 'Collision' THEN avc.collision_deductible
                    WHEN ic.internal_coverage_desc = 'other than collision' THEN avc.otc_deductible
                    WHEN ic.internal_coverage_desc IN ('property damage','uninsured motorist') THEN avc.umpd_deductible
                END AS deductibles,
                CASE 
                    WHEN ic.internal_coverage_desc IN ('Underinsured Motorist','Uninsured Motorist') THEN 'um_uim_Prem'
                    ELSE ic.internal_coverage_desc
                END AS coverageDesc,
                pt.premium_amt as netChangeAmt,
                pt.annual_premium_amt as currentTermAmt
            FROM 
                (
                    SELECT 
                        policy_sk, effective_dt_sk, transaction_seq_no, vehicle_coverage_sk, internal_coverage_sk,
                        SUM(annual_premium_amt) AS annual_premium_amt, 
                        SUM(premium_amt) AS premium_amt 
                    FROM edw_core.tpolicy_transaction as pt
                    INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
                    WHERE 1=1
                        AND pr.product_cd = 'AU'
                    AND cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
                    GROUP BY policy_sk, effective_dt_sk, transaction_seq_no, vehicle_coverage_sk, internal_coverage_sk
                ) as pt 
                INNER JOIN edw_core.tauto_vehicle_coverage as avc ON pt.vehicle_coverage_sk = avc.auto_vehicle_coverage_sk
                INNER JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
        ),
        json_au_vehicles AS (
			SELECT avcf.policy_no, avcf.effective_dt, avcf.transaction_seq_no,
				(
					SELECT 
						av.auto_vehicle_sk as id,
						av.vehicle_vin as vin,
						av.vehicle_model as model,
						avc.symbol_cost_new_amt as costNew,
						av.vehicle_body as bodyType,
						avc.annual_miles as numUnits,
						'Vehicle' as riskType,
						(
							SELECT coverageCd, deductibles, coverageDesc, netChangeAmt, currentTermAmt
							FROM json_au_vehicles_sub_coverages AS javsc
							WHERE javsc.policy_no = avc.policy_no 
								AND javsc.effective_dt = avc.effective_dt
								AND javsc.transaction_seq_no = avc.transaction_seq_no
								AND javsc.vehicle_no = avc.vehicle_no
							FOR JSON PATH
						) AS coverages,
						av.vehicle_model_year as modelYear,
						'' as garagingCd,
						'' as purchaseDt,
						agl.garage_location_no as locationRef,
						avc.rating_territory_cd as territoryCd,
						av.vehicle_type as vehicleType,
						CASE WHEN avc.vehicle_ownership = 'leased' THEN 1 ELSE 0 END as leasedVehInd,
						av.vehicle_make as manufacturer,
						CASE 
							WHEN avc.vehicle_usage = 'pleasure' THEN 'PL' 
							WHEN avc.vehicle_usage = 'commute' THEN 'DO' 
							ELSE '' 
						END vehicleUseCd,
						'' as vehicleSymbolCd,
						CASE 
							WHEN apc.multi_car_discount_in = 'No' THEN 0 
							WHEN apc.multi_car_discount_in = 'Yes' THEN 1 
							ELSE '' 
						END as multiCarDiscount,
						(
							SELECT 
								ai.additional_interest_nm as commercialName,
								ai.address_line_1 as address1,
								ai.city_nm as city,
								ai.state_cd as stateProvCd,
								ai.zip_cd as postalCode,
								CASE WHEN ai.additional_interest_nm IS NULL THEN NULL ELSE 'US' END as countryCd,
								CASE WHEN ai.additional_interest_nm IS NULL THEN NULL ELSE 'United States' END as countryName,
								CASE 
									WHEN ai.additional_interest_nm IS NULL THEN NULL
									ELSE
										CASE ai.interest_type
											WHEN 'Additional Insured' THEN 'ADDIN'
											WHEN 'Additional Interest' THEN 'AINT'
											WHEN 'Additional Insured - Individual' THEN 'ADDIN'
											WHEN 'Additional Insured - Limited Liability' THEN 'OT'
											WHEN 'Additional Insured - Contents' THEN 'OT'
											WHEN 'Loss Payee' THEN 'LOSSP'
											WHEN 'NJ Senior Citizen Designee' THEN 'OT'
											WHEN 'Designated Additional Person to Receive Notice of Cancellation or Nonrenewal' THEN 'OT'
											WHEN 'Third Party Designee' THEN 'TP'
											ELSE 'NA' 
										END 
								END AS natureInterestCd
							FROM edw_core.tadditional_interest as ai 
							WHERE avc.policy_no = ai.policy_no AND avc.effective_dt = ai.effective_dt AND avc.transaction_seq_no = ai.transaction_seq_no
							FOR JSON PATH, INCLUDE_NULL_VALUES 
						) AS additionalInterests,
						'' as numDaysDrivenPerWeek,
						'' as principalOperatorRef,
						avc.distance_to_work as vehicleDistanceToWork
					FROM edw_core.tauto_vehicle_coverage as avc
					INNER JOIN edw_core.tauto_vehicle as av ON avc.auto_vehicle_sk = av.auto_vehicle_sk
					INNER JOIN edw_core.tauto_garage_location as agl ON avc.auto_garage_location_sk = agl.auto_garage_location_sk
					INNER JOIN edw_core.tauto_policy_coverage as apc ON avc.policy_no = apc.policy_no AND avc.effective_dt = apc.effective_dt AND avc.transaction_seq_no = apc.transaction_seq_no
					WHERE avcf.policy_no = avc.policy_no
						AND avcf.effective_dt = avc.effective_dt
						AND avcf.transaction_seq_no = avc.transaction_seq_no
					FOR JSON PATH, INCLUDE_NULL_VALUES 
				) AS AU_Vehicles
			FROM edw_core.tauto_vehicle_coverage as avcf
			GROUP BY avcf.policy_no, avcf.effective_dt, avcf.transaction_seq_no
		),
        json_au_drivers AS (
            SELECT 
                adf.policy_no, adf.effective_dt, adf.transaction_seq_no,
                (
                    SELECT 
                        ad.auto_driver_sk as id,
                        '' as city,
                        '' as addr1,
                        ad.birth_dt as birthDt,
                        '' as country,
                        ad.last_nm as surName,
                        CASE ad.gender 
                            WHEN 'Female' THEN 'F' 
                            WHEN 'Male' THEN 'M' 
                        END as genderCd,
                        '' as latitude,
                        ad.license_country_nm as countryCd,
                        ad.first_nm as givenName,
                        ad.license_year as licenseDt,
                        '' as longitude,
                        '' as addrTypeCd,
                        '' as postalCode,
                        ad.license_state_nm as stateProvCd,
                        ad.prefix as titlePrefix,
                        '' as driverTypeCd,
                        '' as licenseTypeCd,
                        '' as restrictionCd,
                        '' as otherGivenName,
                        ad.license_status as licenseStatusCd,
                        COALESCE(SUBSTRING(ad.marital_status,1,1),'NA') as martialStatusCd,
                        '' as restrictionDesc,
                        ad.license_no as licensePermitNumber,
                        (
                            COALESCE(NULLIF(ad.aaf_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.afb_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.cpa_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.maj_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.min_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.naf_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.spd_prior_ct,'null'),0) +
                            COALESCE(NULLIF(ad.aaf_with_vault_ct,'null'),0) +
                            COALESCE(NULLIF(ad.afb_with_vault_ct,'null'),0) + 
                            COALESCE(NULLIF(ad.cpa_with_vault_ct,'null'),0) +
                            COALESCE(NULLIF(ad.maj_with_vault_ct,'null'),0) +
                            COALESCE(NULLIF(ad.min_with_vault_ct,'null'),0) +
                            COALESCE(NULLIF(ad.naf_with_vault_ct,'null'),0) +
                            COALESCE(NULLIF(ad.spd_with_vault_ct,'null'),0)
                        ) as totalNumLicensePoints
                    FROM edw_core.tauto_driver AS ad
                    WHERE ad.policy_no = adf.policy_no
                        AND ad.effective_dt = adf.effective_dt
                        AND ad.transaction_seq_no = adf.transaction_seq_no
                    FOR JSON PATH
                ) AS AU_Drivers
            FROM edw_core.tauto_driver AS adf
            GROUP BY adf.policy_no, adf.effective_dt, adf.transaction_seq_no
        ),
        json_au_garaging_locations AS (
            SELECT 
                aglf.policy_no, aglf.effective_dt, aglf.transaction_seq_no,
                (
                    SELECT 
                        agl.garage_location_no as locationNo,
                        agl.garage_address_line1 as addr1,
                        agl.garage_address_city_nm as city,
                        agl.garage_address_state_cd as [state],
                        agl.garage_address_zip_code as zip,
                        '' as latitude,
                        '' as longitude,
                        agl.garage_address_county_nm as county
                    FROM edw_core.tauto_garage_location as agl
                    WHERE agl.policy_no = aglf.policy_no
                        AND agl.effective_dt = aglf.effective_dt
                        AND agl.transaction_seq_no = aglf.transaction_seq_no
                    FOR JSON PATH
                ) as AU_Garaging_Locations
            FROM edw_core.tauto_garage_location as aglf
            GROUP BY aglf.policy_no, aglf.effective_dt, aglf.transaction_seq_no
        )


		SELECT 
            'PolicyDownload' as [MsgTypeCd_001],
            CASE 
                WHEN ptt.policy_transaction_type_nm = 'New' THEN 'NBS'
                WHEN ptt.policy_transaction_type_nm = 'Endorsement' THEN 'PCH'
                WHEN ptt.policy_transaction_type_nm = 'Cancellation' THEN 'XLC'
                WHEN ptt.policy_transaction_type_nm = 'Reinstatement' THEN 'REI'
                WHEN ptt.policy_transaction_type_nm = 'Renewal' THEN 'RW'
                ELSE 'OTH'
            END as [BusinessPurposeTypeCd_002],
            d2.actual_dt as [TransactionRequestDt_003],
            d1.actual_dt as [TransactionEffectiveDt_004],
            'USD' as [CurCd_005],
            'P' as [BroadLOBCd_006],
            '2.0' as [IVANSXMLVersionCd_007],
            'EDW' as [SourceSystem_008],
            '' as [ActivityDt_009],
            p.broker_id as [ContractNumber_010],
            '' as [ProducerSubCode_011],
            c.customer_id as [InsurerId_012],
            c.last_nm as [Surname_013],
            c.first_nm as [GivenName_014],
            c.middle_nm as [OtherGivenName_015],
            pi.prefix as [TitlePrefix_016],
            CASE 
                WHEN pi.insured_type = 'Trust/LLC' THEN pi.insured_type
            END AS [CommercialName_100],
            CASE
                WHEN COALESCE(pi.mailing_address_line_1, p.mailing_address_line1) is null THEN ''
                ELSE 'MailingAddress' 
            END as [AddrTypeCd_017], 
            COALESCE(pi.mailing_address_line_1, p.mailing_address_line1) as [Addr1_018],
            COALESCE(pi.mailing_address_city_nm, p.mailing_address_city_nm) as [City_019], 
            COALESCE(pi.mailing_address_state_cd, p.mailing_address_state_cd) as [StateProvCd_020],
            COALESCE(pi.mailing_address_zip_cd, p.mailing_address_zip_cd) as [PostalCode_021],
            COALESCE(pi.mailing_address_country_nm, p.mailing_address_country_nm) as [Country_022],
            '' as [Latitude_023],
            '' as [Longitude_024],
            '' as [County_025],
            CASE
                WHEN pi.home_phone_no is not null THEN 'Home'
                WHEN pi.mobile_phone_no is not null THEN 'Mobile'
                ELSE ''
            END as [PhoneTypeCd_026],
            COALESCE(pi.home_phone_no, pi.mobile_phone_no, '') as [PhoneNumber_027],
            pi.email as [EmailAddr_028],
            'Primary' as [InsuredOrPrincipalRoleCd_029],
            'Primary' as [InsuredOrPrincipalRoleDesc_030],
            p.policy_no as [PolicyNumber_031],
            'P' as [BroadLOBCd_032],
            pr.product_nm as [LOBCd_033],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_034],
            p.effective_dt as [EffectiveDt_035],
            p.expiration_dt as [ExpirationDt_036],
            '' as [Dummy_037],
            '' as [Dummy_038],
            '****Pending****' as [BillingMethodCd_039],
            pt.premium_amt as [Amt_040],
            pt.premium_amt as [Amt_041],
            'en' as [LanguageCd_042],
            op.min_original_policy_effective_dt as [OriginalPolicyInceptionDt_043],
            '' as [Dummy_044],
            '' as [Dummy_045],
            '' as [Dummy_046],
            '' as [Dummy_047],
            '' as [Dummy_048],
            '' as [Dummy_049],
            '' as [Dummy_050],
            '' as [TotalPaidLossAmt_051],
            lh.loss_seq_no as [NumLosses_052],
            CASE
                WHEN p.prior_policy_no is not null AND p.prior_policy_no <> p.policy_no THEN 'Prior'
                ELSE ''
            END as [PolicyCd_053],
            CASE
                WHEN p.prior_policy_no is not null AND p.prior_policy_no <> p.policy_no THEN P.prior_policy_no
                ELSE ''
            END as [PolicyNumber_054],
            pr.product_nm as [LOBCd_055],
            CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [NAICCd_056],
            op.min_effective_dt as [EffectiveDt_057],
            op.min_expiration_dt as [ExpirationDt_058],
            CASE 
                WHEN ba.payment_plan = '1P' THEN 'Full Pay'
                ELSE replace(ba.payment_plan, 'P', ' Pay')
            END AS [PaymentPlanCd_059],
            '' as [MethodPaymentCd_060],
            CASE 
                WHEN ba.payment_plan = '1P' THEN 'Y'
                WHEN ba.payment_plan is null OR ba.payment_method = '' THEN ''
                ELSE 'N'
            END AS [PaidInFullInd_061],
            jac.AU_Coverages,
            jav.AU_Vehicles,
            jad.AU_Drivers,
            jagl.AU_Garaging_Locations,
            pt.transaction_seq_no,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk,
            pt.create_ts as policy_transaction_create_ts
        INTO [edw_temp].[policy_ivans_auto_feed_temp1] 
        FROM [edw_temp].[policy_transaction_temp1] AS pt
		INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
        LEFT JOIN edw_core.tpolicy_insured as pi ON p.policy_no = pi.policy_no AND p.effective_dt = pi.effective_dt AND pt.transaction_seq_no = pi.transaction_seq_no AND pi.primary_insured_in = 'Yes'
		LEFT JOIN edw_core.tdate AS d1 ON pt.transaction_effective_dt_sk = d1.date_sk
        LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_dt_sk = d2.date_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
		LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_transaction_type AS ptt ON pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
        LEFT JOIN edw_core.tbillingaccount AS ba ON p.billingaccount_sk = ba.billingaccount_sk
        LEFT JOIN loss_history AS lh ON p.policy_no = lh.policy_no AND p.effective_dt = lh.effective_dt AND pt.transaction_seq_no = lh.transaction_seq_no
        LEFT JOIN original_policy AS op ON p.original_policy_no = op.original_policy_no
        LEFT JOIN json_au_coverages AS jac
            ON pt.policy_sk = jac.policy_sk AND pt.effective_dt_sk = jac.effective_dt_sk AND pt.transaction_seq_no = jac.transaction_seq_no
        LEFT JOIN json_au_vehicles AS jav
            ON p.policy_no = jav.policy_no AND p.effective_dt = jav.effective_dt AND pt.transaction_seq_no = jav.transaction_seq_no
        LEFT JOIN json_au_garaging_locations AS jagl
            ON p.policy_no = jagl.policy_no AND p.effective_dt = jagl.effective_dt AND pt.transaction_seq_no = jagl.transaction_seq_no
        LEFT JOIN json_au_drivers AS jad
            ON p.policy_no = jad.policy_no AND p.effective_dt = jad.effective_dt AND pt.transaction_seq_no = jad.transaction_seq_no
        ;

        -- Start Insert process
        INSERT INTO [edw_integration].[policy_ivans_auto_feed](
            [MsgTypeCd_001],
            [BusinessPurposeTypeCd_002],
            [TransactionRequestDt_003],
            [TransactionEffectiveDt_004],
            [CurCd_005],
            [BroadLOBCd_006],
            [IVANSXMLVersionCd_007],
            [SourceSystem_008],
            [ActivityDt_009],
            [ContractNumber_010],
            [ProducerSubCode_011],
            [InsurerId_012],
            [Surname_013],
            [GivenName_014],
            [OtherGivenName_015],
            [TitlePrefix_016],
            [AddrTypeCd_017],
            [Addr1_018],
            [City_019],
            [StateProvCd_020],
            [PostalCode_021],
            [Country_022],
            [Latitude_023],
            [Longitude_024],
            [County_025],
            [PhoneTypeCd_026],
            [PhoneNumber_027],
            [EmailAddr_028],
            [InsuredOrPrincipalRoleCd_029],
            [InsuredOrPrincipalRoleDesc_030],
            [PolicyNumber_031],
            [BroadLOBCd_032],
            [LOBCd_033],
            [NAICCd_034],
            [EffectiveDt_035],
            [ExpirationDt_036],
            [Dummy_037],
            [Dummy_038],
            [BillingMethodCd_039],
            [Amt_040],
            [Amt_041],
            [LanguageCd_042],
            [OriginalPolicyInceptionDt_043],
            [Dummy_044],
            [Dummy_045],
            [Dummy_046],
            [Dummy_047],
            [Dummy_048],
            [Dummy_049],
            [Dummy_050],
            [TotalPaidLossAmt_051],
            [NumLosses_052],
            [PolicyCd_053],
            [PolicyNumber_054],
            [LOBCd_055],
            [NAICCd_056],
            [EffectiveDt_057],
            [ExpirationDt_058],
            [PaymentPlanCd_059],
            [MethodPaymentCd_060],
            [PaidInFullInd_061],
            [AU_Coverages],
            [AU_Vehicles],
            [AU_Drivers],
            [AU_Garaging_Locations],
            [transaction_seq_no],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        )
        SELECT 
            [MsgTypeCd_001],
            [BusinessPurposeTypeCd_002],
            [TransactionRequestDt_003],
            [TransactionEffectiveDt_004],
            [CurCd_005],
            [BroadLOBCd_006],
            [IVANSXMLVersionCd_007],
            [SourceSystem_008],
            [ActivityDt_009],
            [ContractNumber_010],
            [ProducerSubCode_011],
            [InsurerId_012],
            [Surname_013],
            [GivenName_014],
            [OtherGivenName_015],
            [TitlePrefix_016],
            [AddrTypeCd_017],
            [Addr1_018],
            [City_019],
            [StateProvCd_020],
            [PostalCode_021],
            [Country_022],
            [Latitude_023],
            [Longitude_024],
            [County_025],
            [PhoneTypeCd_026],
            [PhoneNumber_027],
            [EmailAddr_028],
            [InsuredOrPrincipalRoleCd_029],
            [InsuredOrPrincipalRoleDesc_030],
            [PolicyNumber_031],
            [BroadLOBCd_032],
            [LOBCd_033],
            [NAICCd_034],
            [EffectiveDt_035],
            [ExpirationDt_036],
            [Dummy_037],
            [Dummy_038],
            [BillingMethodCd_039],
            [Amt_040],
            [Amt_041],
            [LanguageCd_042],
            [OriginalPolicyInceptionDt_043],
            [Dummy_044],
            [Dummy_045],
            [Dummy_046],
            [Dummy_047],
            [Dummy_048],
            [Dummy_049],
            [Dummy_050],
            [TotalPaidLossAmt_051],
            [NumLosses_052],
            [PolicyCd_053],
            [PolicyNumber_054],
            [LOBCd_055],
            [NAICCd_056],
            [EffectiveDt_057],
            [ExpirationDt_058],
            [PaymentPlanCd_059],
            [MethodPaymentCd_060],
            [PaidInFullInd_061],
            [AU_Coverages],
            [AU_Vehicles],
            [AU_Drivers],
            [AU_Garaging_Locations],
            [transaction_seq_no],
            [create_ts],
            [update_ts],
            [etl_audit_sk]
        FROM [edw_temp].[policy_ivans_auto_feed_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(policy_transaction_create_ts) FROM edw_temp.[policy_ivans_auto_feed_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_auto_feed_temp1];
        DROP TABLE IF EXISTS [edw_temp].[policy_transaction_temp1];

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
