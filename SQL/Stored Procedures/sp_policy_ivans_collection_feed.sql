-- ========================================================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert info related to IVANS Collection policy feed
---------------------------------------------------------------------------------------------------
-- Change date			|Author										|	Change Description
---------------------------------------------------------------------------------------------------
-- 05/06/25				Yunus Mohammed				1. Created this procedure
-- 09/02/25				Alberto Almario				2. Add new columns Addr1_063,City_064,StateProvCd_065,PostalCode_066,Latitude_067,Longitude_068,County_069,Country_070
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_ivans_collection_feed]
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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp1];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp2];		
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp3];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp4];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp5];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp6];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp7];

        SELECT 
             pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, 
			 pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk,
            MAX(ph.transaction_ts) as transaction_ts,
            SUM(pt.premium_amt) as premium_amt,
			CASE WHEN pt.policy_transaction_type_sk = 5
				THEN
        			(
						SELECT SUM(subpt.premium_amt)
        			    FROM edw_core.tpolicy_transaction subpt
        			    WHERE subpt.policy_sk = pt.policy_sk
        			    AND subpt.transaction_seq_no <= pt.transaction_seq_no
					)
    			ELSE
    			    (
						SELECT SUM(subpt.annual_premium_amt)
    			        FROM edw_core.tpolicy_transaction subpt
    			        WHERE subpt.policy_sk = pt.policy_sk
    			        AND subpt.transaction_seq_no <= pt.transaction_seq_no
					)
    		END AS annual_premium_amt
			,coverage_sk
		INTO [edw_temp].[policy_ivans_collection_temp1]
        FROM edw_core.tpolicy_transaction as pt	
		INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no
		WHERE
			pt.product_sk = 2			
            AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
        GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, 
		pt.transaction_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk,pt.coverage_sk
		
		SELECT temp4.*
		INTO [edw_temp].[policy_ivans_collection_temp3]
		FROM (
		SELECT
		    ptf.policy_no, ptf.effective_dt, ptf.transaction_seq_no,
		    (
				SELECT uniqueId, policyNumber, commercialName, addr1, city, [state], zip, natureInterestCd, accountNumberId
				FROM (
					
					SELECT
						ai.policy_no, ai.effective_dt, ai.transaction_seq_no,
						--CONCAT('AI-', ai.additional_interest_sk) as unique_id,
						CONCAT('AI-', ROW_NUMBER() OVER (PARTITION BY ai.policy_no, ai.effective_dt, ai.transaction_seq_no ORDER BY ai.additional_interest_sk ASC)) as uniqueId,
						ai.policy_no as policyNumber,
						COALESCE(
    						ai.additional_interest_nm,
    						ai.entity_nm,
    						CONCAT(ISNULL(ai.first_nm, ''), ' ', ISNULL(ai.last_nm, ''))
						) AS commercialName,
						COALESCE(ai.address_line_1, '') as addr1,
						COALESCE(ai.city_nm, '') as city,
						COALESCE(ai.state_cd, '') as [state],
						COALESCE(ai.zip_cd, '') as zip,
						-- '' as Latitude,
						-- '' as Longitude,
						-- '' as County,
						CASE
							WHEN ai.interest_type = 'Additional Insured' THEN 'ADDIN'
							WHEN ai.interest_type = 'Additional Interest' THEN 'AINT'
							WHEN ai.interest_type = 'Additional Insured - Individual' THEN 'ADDIN'
							WHEN ai.interest_type = 'Additional Insured - Limited Liability' THEN 'OT'
							WHEN ai.interest_type = 'Additional Insured - Contents' THEN 'OT'
							WHEN ai.interest_type = 'Loss Payee' THEN 'LOSSP'
							WHEN ai.interest_type = 'NJ Senior Citizen Designee' THEN 'OT'
							WHEN ai.interest_type = 'Designated Additional Person to Receive Notice of Cancellation or Nonrenewal' THEN 'OT'
							WHEN ai.interest_type = 'Third Party Designee' THEN 'TP'
							ELSE 'NA'
						END as natureInterestCd,
						COALESCE(tp.customer_id, '') as accountNumberId
					FROM edw_core.tadditional_interest as ai
					INNER JOIN edw_core.tpolicy_history ph ON ai.policy_history_sk = ph.policy_history_sk
					INNER JOIN edw_core.tpolicy tp ON ai.policy_no = tp.policy_no AND ai.effective_dt = tp.effective_dt
					WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
					and ai.product_cd = 'LUX'
				) AS jdata
					WHERE  ptf.policy_no = jdata.policy_no
						AND ptf.effective_dt = jdata.effective_dt
						AND ptf.transaction_seq_no = jdata.transaction_seq_no
				FOR JSON PATH, INCLUDE_NULL_VALUES 
			) AS Additional_Interests
			FROM 
			(				
				SELECT ai.policy_no, ai.effective_dt, ai.transaction_seq_no
				FROM
					edw_core.tadditional_interest ai
					INNER JOIN edw_core.tpolicy_history ph ON ai.policy_history_sk = ph.policy_history_sk
				WHERE
					cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
			) as ptf
		) temp4

		SELECT temp5.*
		INTO [edw_temp].[policy_ivans_collection_temp4]
		FROM (
			SELECT
			    ptf.policy_no, ptf.effective_dt, ptf.transaction_seq_no,
			    (
					SELECT
						--csi.item_no as itemNumber
						csi.scheduled_item_no as itemNumber
						,csi.item_desc as itemDesc
						,csi.coverage_limit_amt as itemLimit
						,csi.collector_car_in as collectorCarInd
						,COALESCE(csi.schedule_on_file_in, '') as onFile
						,cct.class_type as classtype
						FROM
							edw_core.tcollection_scheduled_item csi
							INNER JOIN edw_core.tpolicy_history ph ON csi.policy_history_sk = ph.policy_history_sk
									AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
								LEFT JOIN edw_core.tcollection_class_type cct on csi.collection_class_type_sk = cct.collection_class_type_sk
						WHERE
							ptf.policy_no = csi.policy_no
							AND ptf.effective_dt = csi.effective_dt
							AND ptf.transaction_seq_no = csi.transaction_seq_no
					FOR JSON PATH, INCLUDE_NULL_VALUES 
				) AS Scheduled_Items
				FROM edw_core.tcollection_scheduled_item as ptf
				INNER JOIN edw_core.tpolicy_history ph ON ptf.policy_history_sk = ph.policy_history_sk
				WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
				group by ptf.policy_no, ptf.effective_dt, ptf.transaction_seq_no
		) temp5

		SELECT temp6.*
		INTO [edw_temp].[policy_ivans_collection_temp5]
		FROM (
			SELECT
			    ptf.policy_sk, ptf.effective_dt_sk ,ptf.transaction_seq_no,
			    (
					SELECT 
						policyNumber
						,'L1' as location_no
						,coverageType, coverageCd, coverageTypeDesc, scheduledInd, inVaultInd, classType, [limit], premium, saLimit, hviLimit, address1, address2, city, county, [state], zip, riskType
					FROM
					(
						SELECT 
							tp.policy_no as policyNumber
							--
							,pt.transaction_seq_no
							,pt.effective_dt_sk
							,pt.policy_sk
							-- 
							--,CONCAT('L', ROW_NUMBER() OVER (PARTITION BY tcc.policy_no ORDER BY tcc.policy_no, tcc.transaction_seq_no, (CONCAT(tcl.address_line_1, '-', tcl.city_nm, '-', tcl.state_cd, '-', RIGHT('00000' + tcl.zip_cd, 5), '-', tcl.county_nm)))) as location_no
							,'SPP' as coverageType
							,case when tcct.class_type = 'Coins' then 'SCHCOINS'
								when tcct.class_type = 'Collectibles' then 'SCHCLTBLS'
								when tcct.class_type = 'Fine Arts' then 'SCHFA'
								when tcct.class_type = 'Furs' then 'SCHFURS'
								when tcct.class_type = 'Guns' then 'SCHGUNS'
								when tcct.class_type = 'Jewelry' or tcct.class_type = 'Worldwide Jewelry' then 'SCHJWLRY'
								when tcct.class_type = 'Bank Vaulted Jewelry' then 'SCHVLTJWRY'
								when tcct.class_type = 'Miscellaneous' then 'SCHMISC'
								when tcct.class_type = 'Musical Instruments' then 'SCHMUSIC'
								when tcct.class_type = 'Silver' then 'SCHSLVR'
								when tcct.class_type = 'Wearable Collectibles' then 'SCHWCLTBLS'
								when tcct.class_type = 'Wine' then 'SCHWINE'
								when tcct.class_type = 'Stamps' then 'SCHSTMPS'
								else ''
							end as coverageCd
							,'Scheduled Personal Property' as coverageTypeDesc
							,1 as scheduledInd
							,CASE WHEN tcct.class_type = 'Bank Vaulted Jewelry' THEN 1 ELSE 0 END AS inVaultInd
							,tcct.class_type as classType
							,floor(tcct.scheduled_limit_amt) as [limit]
							--,pt.premium_amt as premium
							,(
                            	SELECT SUM(subpt.annual_premium_amt)
                            	FROM edw_core.tpolicy_transaction subpt
                            	WHERE subpt.policy_sk = pt.policy_sk
                            	AND subpt.effective_dt_sk = pt.effective_dt_sk
                            	AND subpt.internal_coverage_sk = pt.internal_coverage_sk
                            	AND subpt.transaction_seq_no <= pt.transaction_seq_no
                        	) AS premium
							,0 as saLimit
							,floor(tcct.scheduled_highest_value_limit_amt) as hviLimit
							,tcl.address_line_1 as address1
							,tcl.address_line_2 as address2
							,tcl.city_nm as city
							,tcl.county_nm as county
							,tcl.state_cd as [state] 
							,tcl.zip_cd as zip
							,'IMInfo' as riskType
						FROM edw_core.tpolicy_transaction pt
						INNER JOIN edw_core.tpolicy tp on pt.policy_sk = tp.policy_sk
						LEFT JOIN edw_core.tcustomer tc on pt.customer_sk = tc.customer_sk
						LEFT JOIN edw_core.tcollection_coverage tcc ON tp.policy_no = tcc.policy_no AND tp.effective_dt = tcc.effective_dt
									AND pt.transaction_seq_no = tcc.transaction_seq_no						
						LEFT JOIN edw_core.tcollection_location tcl	on tcc.collection_location_sk = tcl.collection_location_sk
						INNER JOIN edw_core.tcollection_class_type tcct on tcc.collection_coverage_sk = tcct.collection_coverage_sk
								and pt.collection_class_type_sk = tcct.collection_class_type_sk
						LEFT JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
						INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no -- RS Added
						WHERE
							--cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts and-- RS Updated
							coalesce(pt.premium_amt, 0) + coalesce(tcct.scheduled_limit_amt, 0) + coalesce(tcct.scheduled_highest_value_limit_amt, 0) <> 0 
							and ic.aslob_cd in ('091') and ic.product_cd = 'LUX' 
							and ic.internal_coverage_category_nm = 'Premium' 
							and (ic.internal_coverage_cd like '%chedule%' or ic.internal_coverage_cd like '%lux%')
						--
						UNION ALL
						--
						SELECT 
							tp.policy_no as policyNumber
							--
							,pt.transaction_seq_no
							,pt.effective_dt_sk
							,pt.policy_sk
							--
							--,CONCAT('L', ROW_NUMBER() OVER (PARTITION BY tcc.policy_no ORDER BY tcc.policy_no, tcc.transaction_seq_no, (CONCAT(tcl.address_line_1, '-', tcl.city_nm, '-', tcl.state_cd, '-', RIGHT('00000' + tcl.zip_cd, 5), '-', tcl.county_nm)))) as location_no
							,'BPP' as coverageType
							,case when tcct.class_type = 'Coins' then 'SCHCOINS'
								when tcct.class_type = 'Collectibles' then 'SCHCLTBLS'
								when tcct.class_type = 'Fine Arts' then 'SCHFA'
								when tcct.class_type = 'Furs' then 'SCHFURS'
								when tcct.class_type = 'Guns' then 'SCHGUNS'
								when tcct.class_type = 'Jewelry' or tcct.class_type = 'Worldwide Jewelry' then 'SCHJWLRY'
								--when tcct.class_type = 'Bank Vaulted Jewelry' then 'SCHVLTJWRY'
								--when tcct.class_type = 'Miscellaneous' then 'SCHMISC'
								when tcct.class_type = 'Musical Instruments' then 'SCHMUSIC'
								when tcct.class_type = 'Silver' then 'SCHSLVR'
								--when tcct.class_type = 'Wearable Collectibles' then 'SCHWCLTBLS'
								when tcct.class_type = 'Wine' then 'SCHWINE'
								when tcct.class_type = 'Stamps' then 'SCHSTMPS'
								else ''
							end as coverageCd
							,'Blanket Personal Property' as coverageTypeDesc
							,0 as scheduledInd
							,0 as inVaultInd
							,tcct.class_type as classType
							,floor(tcct.blanket_limit_amt) as [limit]
							--,pt.premium_amt as premium
							,(
                            	SELECT SUM(subpt.annual_premium_amt)
                            	FROM edw_core.tpolicy_transaction subpt
                            	WHERE subpt.policy_sk = pt.policy_sk
                            	AND subpt.effective_dt_sk = pt.effective_dt_sk
                            	AND subpt.internal_coverage_sk = pt.internal_coverage_sk
                            	AND subpt.transaction_seq_no <= pt.transaction_seq_no
                        	) AS premium
							,floor(tcct.blanket_single_article_limit_amt) as saLimit
							,floor(tcct.blanket_highest_value_limit_amt) as hviLimit
							,tcl.address_line_1 as address1
							,tcl.address_line_2 as address2
							,tcl.city_nm as city
							,tcl.county_nm as county
							,tcl.state_cd as [state]
							,tcl.zip_cd as zip
							,'IMInfo' as riskType
						FROM
							edw_core.tpolicy_transaction pt
							INNER JOIN edw_core.tpolicy tp on pt.policy_sk = tp.policy_sk
							LEFT JOIN edw_core.tcustomer tc on pt.customer_sk = tc.customer_sk
							LEFT JOIN edw_core.tcollection_coverage tcc ON tp.policy_no = tcc.policy_no	AND tp.effective_dt = tcc.effective_dt
									AND pt.transaction_seq_no = tcc.transaction_seq_no							
							LEFT JOIN edw_core.tcollection_location tcl on tcc.collection_location_sk = tcl.collection_location_sk
							INNER JOIN edw_core.tcollection_class_type tcct on tcct.policy_history_sk = pt.policy_history_sk
								AND pt.collection_class_type_sk = tcct.collection_class_type_sk
							LEFT JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
							INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk
								AND pt.transaction_seq_no = ph.transaction_seq_no
						WHERE --cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts and-- RS Updated
						 coalesce(pt.premium_amt, 0) + coalesce(tcct.blanket_limit_amt, 0) + coalesce(tcct.blanket_single_article_limit_amt, 0) + coalesce(tcct.blanket_highest_value_limit_amt, 0) <> 0 
						and ic.aslob_cd in ('091') and ic.product_cd = 'LUX' 
						and ic.internal_coverage_category_nm = 'Premium' 
						and (ic.internal_coverage_cd like '%lanket%' or ic.internal_coverage_cd like '%lux%')
					) ud
						WHERE  ud.policy_sk = ptf.policy_sk
                       AND ud.effective_dt_sk = ptf.effective_dt_sk
                       AND ud.transaction_seq_no = ptf.transaction_seq_no
					FOR JSON PATH, INCLUDE_NULL_VALUES 
				) Collection_Coverages
			FROM [edw_temp].[policy_ivans_collection_temp1] as ptf
        ) temp6

		SELECT temp7.*
		INTO [edw_temp].[policy_ivans_collection_temp6]
		FROM (
            SELECT original_policy_no, min(effective_dt) as min_effective_dt, min(expiration_dt) as min_expiration_dt 
                FROM edw_core.tpolicy
            GROUP BY original_policy_no
		) temp7

		SELECT temp8.*
		INTO [edw_temp].[policy_ivans_collection_temp7]
		FROM (
            SELECT 
                policy_no, effective_dt, transaction_seq_no, max(loss_seq_no) as loss_seq_no 
            FROM 
                edw_core.tloss_history
            GROUP BY 
                policy_no, effective_dt, transaction_seq_no
        ) temp8

		/* */

		SELECT 
		'PolicyDownload' as [001_MsgTypeCd]
		,CASE 
			WHEN ptt.policy_transaction_type_nm = 'New' THEN 'NBS'
		    WHEN ptt.policy_transaction_type_nm = 'Cancellation' THEN 'XLC'
			WHEN ptt.policy_transaction_type_nm = 'Reinstatement' THEN 'REI'
			WHEN ptt.policy_transaction_type_nm = 'Renewal' THEN 'RW'
			WHEN ptt.policy_transaction_type_nm = 'Rescind Non-Renewal' THEN 'RNR'
			WHEN ptt.policy_transaction_type_nm = 'Endorsement' THEN 'PCH'
			WHEN ptt.policy_transaction_type_nm = 'Non-Renewal' THEN 'NR'
			WHEN ptt.policy_transaction_type_nm = 'Rollback' THEN 'RBK'
			ELSE 'OTH'
		END AS [002_BusinessPurposeTypeCd]
		,d2.actual_dt as [003_TransactionRequestDt]
        ,d1.actual_dt as [004_TransactionEffectiveDt]
		,'USD' as [005_CurCd]
		,'P' as [006_BroadLOBCd]
		,'' as [007_IVANSXMLVersionCd]
		,'EDW' as [008_SourceSystem]
		,p.broker_id as [009_ContractNumber]
		,'' as [010_ProducerSubCode]
		,c.customer_id as [011_InsurerId]
		,c.last_nm AS [012_Surname]
		,COALESCE(c.first_nm, c.customer_nm) AS [013_GivenName]
		,c.middle_nm as [014_OtherGivenName]
		,CASE WHEN c.Insured_type = 'Trust/LLC'  THEN 'Entity' END as [182_CommercialName]
		,c.prefix AS [015_Prefix]
		,CASE WHEN c.mailing_Address_line1 IS NOT NULL THEN 'MailingAddress' ELSE 'LocationAddress' END as [016_AddrTypeCd]
		,c.mailing_address_line1 as [017_Addr1]
		,c.mailing_address_city_nm as [018_City]
		,c.mailing_address_state_cd as [019_StateProvCd]
		,c.mailing_address_zip_cd as [020_PostalCode]
		,c.mailing_address_country_nm as [021_Country]
		,cl.latitude as [022_Latitude]
		,cl.longitude as [023_Longitude]
		,c.mailing_address_county_nm as [024_County]
		,'' as [025_PhoneTypeCd]
		,RIGHT(REPLACE(TRANSLATE(c.home_phone_no, '+-/()#', '      '), ' ', ''), 10) as [026_HomePhoneNumber]
		,RIGHT(REPLACE(TRANSLATE(c.mobile_phone_no, '+-/()#', '      '), ' ', ''), 10) as [026_MobilePhoneNumber]
		,COALESCE(c.email, poi.email) as [027_EmailAddr]
		,CASE WHEN poi.primary_insured_in = 'Yes' then 'Primary' ELSE 'Secondary' END as [028_InsuredOrPrincipalRoleCd]
		,CASE WHEN poi.primary_insured_in = 'Yes' then 'Primary' ELSE 'Secondary' END as [029_InsuredOrPrincipalRoleDesc]
		,p.policy_no as [030_PolicyNumber]
		,'P' as [031_BroadLOBCd]
		, pr.product_nm as [032_LOBCd] -- pr.product_nm edw_core.tproduct ON p.product_cd = pr.product_cd
		,CASE 
                WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' 
                WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' 
                ELSE '' 
            END as [033_NAICCd]
		,p.effective_dt as [034_EffectiveDt]
		,p.expiration_dt as [035_ExpirationDt]
		,'' as [036_BillingAccountNumber]
		,'' as [037_ControllingStateProvCd]
		,CASE WHEN ba.bill_type = 'Insured' or ba.bill_type = 'Mortgagee' THEN 'Direct' ELSE 'Not Direct' END AS [038_BillingMethodCd]
		,COALESCE(pt.annual_premium_amt, 0) as [039_Amt] -- Need to validate this
		,COALESCE(pt.premium_amt, 0)  as [040_Amt]
		,'en' as [041_LanguageCd]
		,p.original_policy_effective_dt as [042_OriginalPolicyInceptionDt]
		,'' as [043_PayorCd] 
		,'' as [044_RenewalBillingMethodCd]
		,'' as [045_RenewalPayorCd]
		,'' as [046_FormNumber]
		,'' as [047_FormName]
		,'' as [048_EditionDt]
		,'' as [049_IterationNumber]
		,'' as [050_TotalPaidLossAmt]
		,lh.loss_seq_no as [051_NumLosses]
		--,'numberLosses' as [051_NumLosses]
		,CASE WHEN p.prior_term_policy_no IS NOT NULL AND p.prior_term_policy_no <> p.policy_no THEN 'Prior' ELSE '' END as [052_PolicyCd]
		,p.original_policy_no as [053_PolicyNumber]
		,pr.product_nm as [054_LOBCd]
		,CASE WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' ELSE '' END AS [055_NAICCd]
		,poi.insured_nm as [056_InsurerName]
		,op.min_effective_dt as [057_EffectiveDt]
        ,op.min_expiration_dt as [058_ExpirationDt]
		,'' as [059_MethodPaymentCd]
		,CASE 
                WHEN ba.payment_plan = '1P' THEN 'Full Pay'
                ELSE replace(ba.payment_plan, 'P', ' Pay')
            END AS [060_PaymentPlanCd]
		,CASE 
                WHEN ba.payment_plan = '1P' THEN 'Y'
                WHEN ba.payment_plan is null OR ba.payment_method = '' THEN ''
                ELSE 'N'
            END AS [061_PaidInFullInd]
		,tprc.national_producer_no as [062_NIPRid]
		,cl.address_line_1 AS [063_Addr1]
		,cl.city_nm AS [064_City]
		,cl.state_cd AS [065_StateProvCd]
		,cl.zip_cd AS [066_PostalCode]
		,cl.latitude AS [067_Latitude]
		,cl.longitude AS [068_Longitude]
		,cl.county_nm AS [069_County]
		,cl.country_nm AS [070_Country]
		,jhcc.Collection_Coverages
		,jai.Additional_Interests
		,jsi.Scheduled_Items
		,pt.transaction_seq_no as [transaction_seq_no]		
		,pt.transaction_ts as policy_history_transaction_ts
		INTO [edw_temp].[policy_ivans_collection_temp2]		
		FROM [edw_temp].[policy_ivans_collection_temp1] pt
		INNER JOIN edw_core.tpolicy p ON pt.policy_sk = p.policy_sk
		INNER JOIN edw_core.tbroker b ON p.broker_id = b.broker_id
		LEFT JOIN edw_core.tproduct pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_insured as poi ON p.policy_no = poi.policy_no
		AND p.effective_dt = poi.effective_dt AND pt.transaction_seq_no = poi.transaction_seq_no
		AND poi.primary_insured_in = 'Yes'
		LEFT JOIN edw_core.tdate AS d1 ON pt.transaction_effective_dt_sk = d1.date_sk
        LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_dt_sk = d2.date_sk
		LEFT JOIN [edw_core].[tpolicy_transaction_type] ptt on pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
		LEFT JOIN [edw_core].[tbillingaccount] ba on p.billingaccount_sk = ba.billingaccount_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
		LEFT JOIN edw_core.tcollection_location cl on cl.policy_no = p.policy_no and cl.effective_dt = p.effective_dt
		LEFT JOIN [edw_temp].[policy_ivans_collection_temp7] lh on p.policy_no = lh.policy_no
				AND p.effective_dt = lh.effective_dt AND pt.transaction_seq_no = lh.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_collection_temp6] AS op ON p.original_policy_no = op.original_policy_no 		
		LEFT JOIN [edw_temp].[policy_ivans_collection_temp5] jhcc on pt.policy_sk = jhcc.policy_sk AND pt.effective_dt_sk = jhcc.effective_dt_sk
           AND pt.transaction_seq_no = jhcc.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_collection_temp3] jai on p.policy_no = jai.policy_no AND p.effective_dt = jai.effective_dt
           AND pt.transaction_seq_no = jai.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_collection_temp4] jsi on p.policy_no = jsi.policy_no AND p.effective_dt = jsi.effective_dt
           AND pt.transaction_seq_no = jsi.transaction_seq_no
		LEFT JOIN (
				select broker_sk, broker_id, national_producer_no
				    ,ROW_NUMBER() OVER (PARTITION BY broker_id ORDER BY producer_sk DESC) AS rn
				from edw_core.tproducer
			) tprc
		ON p.broker_id = tprc.broker_id AND tprc.rn = 1
		WHERE cast(pt.transaction_ts as datetime2(7)) > @last_source_extract_ts
		AND b.ivans_y_account IS NOT NULL

		-- Start Insert process
		INSERT INTO edw_integration.policy_ivans_collections_feed
        (
            MsgTypeCd_001,BusinessPurposeTypeCd_002,TransactionRequestDt_003,TransactionEffectiveDt_004
            ,CurCd_005,BroadLOBCd_006,SourceSystem_008,ContractNumber_009,ProducerSubCode_010
            ,InsurerId_011,Surname_012,GivenName_013,OtherGivenName_014,Prefix_015,AddrTypeCd_016
            ,Addr1_017,City_018,StateProvCd_019,PostalCode_020,Country_021,Latitude_022,Longitude_023,County_024
            ,PhoneTypeCd_025,PhoneNumber_026,EmailAddr_027,InsuredOrPrincipalRoleCd_028,InsuredOrPrincipalRoleDesc_029
            ,PolicyNumber_030,BroadLOBCd_031,LOBCd_032,NAICCd_033,EffectiveDt_034,ExpirationDt_035
            ,BillingAccountNumber_036,ControllingStateProvCd_037,BillingMethodCd_038,Amt_039
            ,Amt_040,LanguageCd_041,OriginalPolicyInceptionDt_042,PayorCd_043,RenewalBillingMethodCd_044
            ,RenewalPayorCd_045,FormNumber_046,FormName_047,EditionDt_048,IterationNumber_049,TotalPaidLossAmt_050
            ,NumLosses_051,PolicyCd_052,PolicyNumber_053,LOBCd_054,NAICCd_055,InsurerName_056
            ,EffectiveDt_057,ExpirationDt_058,MethodPaymentCd_059,PaymentPlanCd_060,PaidInFullInd_061,NIPRid_062
			,Addr1_063,City_064,StateProvCd_065,PostalCode_066,Latitude_067,Longitude_068,County_069,Country_070
            ,Collection_Coverages,Additional_Interests,Scheduled_Items
            ,transaction_seq_no,create_ts,update_ts,etl_audit_sk
    )
    SELECT
    [001_MsgTypeCd],[002_BusinessPurposeTypeCd],[003_TransactionRequestDt],[004_TransactionEffectiveDt]
    ,[005_CurCd],[006_BroadLOBCd],[008_SourceSystem],[009_ContractNumber],[010_ProducerSubCode],[011_InsurerId],[012_Surname],
    CASE WHEN
    ([015_Prefix] IS NULL OR [015_Prefix] = '') AND
    ([013_GivenName] IS NULL OR [013_GivenName] = '') AND
    ([014_OtherGivenName] IS NULL OR [014_OtherGivenName] = '') AND
    ([012_Surname] IS NULL OR [012_Surname] = '') AND
    ([056_InsurerName] IS NOT NULL AND [056_InsurerName] <> '')
    THEN [056_InsurerName]
    ELSE
    [013_GivenName] END as [013_GivenName]
    ,[014_OtherGivenName],[015_Prefix],[016_AddrTypeCd],[017_Addr1],[018_City],[019_StateProvCd],[020_PostalCode]
    ,[021_Country],[022_Latitude],[023_Longitude],[024_County]
    ,CASE
    WHEN [026_HomePhoneNumber] IS NOT NULL
        AND LEN([026_HomePhoneNumber]) = 10
        AND LEFT([026_HomePhoneNumber], 1) NOT IN ('0', '1')
        THEN 'Home'
    WHEN [026_MobilePhoneNumber] IS NOT NULL
        AND LEN([026_MobilePhoneNumber]) = 10
        AND LEFT([026_MobilePhoneNumber], 1) NOT IN ('0', '1')
        THEN 'Mobile'
    ELSE ''
    END AS [025_PhoneTypeCd]
    ,CASE
    WHEN [026_HomePhoneNumber] IS NOT NULL
        AND LEN([026_HomePhoneNumber]) = 10
        AND LEFT([026_HomePhoneNumber], 1) NOT IN ('0', '1')
        THEN [026_HomePhoneNumber]
    WHEN [026_MobilePhoneNumber] IS NOT NULL
        AND LEN([026_MobilePhoneNumber]) = 10
        AND LEFT([026_MobilePhoneNumber], 1) NOT IN ('0', '1')
        THEN [026_MobilePhoneNumber]
    ELSE ''
    END AS PhoneNumber_026
    ,[027_EmailAddr],[028_InsuredOrPrincipalRoleCd],[029_InsuredOrPrincipalRoleDesc],[030_PolicyNumber],[031_BroadLOBCd]
    ,[032_LOBCd],[033_NAICCd],[034_EffectiveDt],[035_ExpirationDt],[036_BillingAccountNumber],[037_ControllingStateProvCd]
    ,[038_BillingMethodCd],[039_Amt],[040_Amt],[041_LanguageCd],[042_OriginalPolicyInceptionDt],[043_PayorCd]
    ,[044_RenewalBillingMethodCd],[045_RenewalPayorCd],[046_FormNumber],[047_FormName],[048_EditionDt]
    ,[049_IterationNumber],[050_TotalPaidLossAmt],[051_NumLosses],[052_PolicyCd],[053_PolicyNumber],[054_LOBCd]
    ,[055_NAICCd],[056_InsurerName],[057_EffectiveDt],[058_ExpirationDt],[059_MethodPaymentCd],[060_PaymentPlanCd]
    ,[061_PaidInFullInd],[062_NIPRid],[063_Addr1],[064_City],[065_StateProvCd],[066_PostalCode],[067_Latitude],[068_Longitude],[069_County],[070_Country]
	,Collection_Coverages,Additional_Interests,Scheduled_Items,transaction_seq_no
    ,getdate(),getdate(),@etl_audit_sk
    FROM edw_temp.policy_ivans_collection_temp2
    WHERE [053_PolicyNumber] IS NOT NULL;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_history_transaction_ts) FROM [edw_temp].[policy_ivans_collection_temp2] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp1];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp2];		
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp3];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp4];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp5];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp6];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_collection_temp7];
		
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
GO