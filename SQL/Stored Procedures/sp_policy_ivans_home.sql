SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-08-28
-- Description: This procedures insert and update info related to IVANS Home
-- 04/05/2024                      sandeep Gundreddy                             repush to Git Repo
-- 04/09/2024					   Rushin Shah									Update SP to identify delta based on last_source_extract_ts
-- ========================================================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_ivans_home]
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
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp1];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp2];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp3];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp4];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp5];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp6];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp7];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp8];

        SELECT 
             pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk,
            MAX(ph.transaction_ts) as transaction_ts, -- MAX(create_ts) as create_ts, RS Updated
            SUM(pt.premium_amt) as premium_amt,
            --SUM(annual_premium_amt) as annual_premium_amt,
			CASE WHEN pt.policy_transaction_type_sk = 5
				THEN
        			(SELECT SUM(subpt.premium_amt)
        			    FROM edw_core.tpolicy_transaction subpt
        			    WHERE subpt.policy_sk = pt.policy_sk
        			    AND subpt.transaction_seq_no <= pt.transaction_seq_no)
    			ELSE
    			    (SELECT SUM(subpt.annual_premium_amt)
    			        FROM edw_core.tpolicy_transaction subpt
    			        WHERE subpt.policy_sk = pt.policy_sk
    			        AND subpt.transaction_seq_no <= pt.transaction_seq_no)
    		END AS annual_premium_amt
			,coverage_sk
		INTO [edw_temp].[policy_ivans_home_temp1]
        FROM edw_core.tpolicy_transaction as pt
		INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no -- RS Added
		WHERE pt.product_sk in (1, 5) -- Home
            AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts -- RS Updated
        GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.transaction_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk
		,pt.coverage_sk

		SELECT temp3.*
		INTO [edw_temp].[policy_ivans_home_temp3]
		FROM (
			SELECT ptf.policy_sk, ptf.effective_dt_sk ,ptf.transaction_seq_no, (
				SELECT * FROM (
					SELECT
						hc.policy_no as policyNumber,
						--ic.primary_coverage_cd as coverageCd,
						ic.internal_coverage_cd as coverageCd,
						ic.internal_coverage_desc as coverageDesc,
						--ic.internal_coverage_desc as IVANS_coverage_desc,
						pt.premium_amt AS changeAmount,
						pt.annual_premium_amt AS currentAmount,
						CASE
						    WHEN ic.internal_coverage_cd = 'Systems Protection'
						        THEN CAST(hac.home_systems_protection_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Cyber Protection'
						        THEN CAST(hac.home_cyber_protection_coverage_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Earthquake Coverage Extended for Loss Assessment'
						        THEN CAST(hac.earthquake_coverage_extension_loss_assessment_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Fungi Liability Extension'
						        THEN CAST(hac.fungi_bacteria_increase_limit as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Increased Incident Business Property'
						        THEN CAST(hac.business_property_increase_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Increased Incidental Business Property'
						        THEN CAST(hac.increased_incidental_business_property_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Landscape'
						        THEN CAST(hac.landscaping_coverage_increased_aggregate_limit as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Law Ordinance Coverage Increase'
						        THEN CAST(hac.law_ordinance_coverage_increased_limit as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Loss Assessment Increase'
						        THEN CAST(hac.loss_assessment_increase_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Workers Compensation'
						        THEN CAST(hac.workercompensation_liability_occurance_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Dwelling Reconstruction Cost'
						        THEN CAST(hc.dwelling_limit_amt as NVARCHAR(255))
						    WHEN (ic.internal_coverage_cd = 'Other')
						        THEN CAST(hc.other_structures_limit_amt as NVARCHAR(255))
							WHEN (ic.internal_coverage_cd = 'Other Structures Away Residence Premises')
						        THEN CAST(hc.other_structures_limit_amt as NVARCHAR(255))
						    WHEN (ic.internal_coverage_cd = 'Contents Extended')
						        THEN CAST(hc.contents_limit_amt as NVARCHAR(255))
							WHEN (ic.internal_coverage_cd = 'Contents Off Premises Loss Exclusion')
						        THEN CAST(hc.contents_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Loss of Use'
						        THEN CAST(hc.loss_of_use_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Liability Coverage'
						        THEN CAST(hc.personal_liability_limit_amt as NVARCHAR(255))
							WHEN ic.internal_coverage_cd = 'Liability Extension'
						        THEN CAST(hc.personal_liability_limit_amt as NVARCHAR(255))
						    ELSE NULL 
						END AS [limit],
						CASE 
						    WHEN ic.internal_coverage_cd = 'AOP'
						        THEN CAST(hc.aop_deductible as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Cyber Protection'
						        THEN CAST(hac.home_cyber_protection_coverage_deductible as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Earthquake Coverage Extended for Loss Assessment'
						        THEN CAST(hac.earthquake_coverage_extension_loss_assessment_limit_amt as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Hurricane'
						        THEN CAST(hc.hurricane_deductible as NVARCHAR(255))
						    WHEN ic.internal_coverage_cd = 'Wildfire'
						        THEN CAST(hc.wildfire_deductible AS NVARCHAR(255))
						    ELSE NULL 
						END AS deductible
					FROM 
					(
						SELECT 
							pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk,
							SUM(pt.annual_premium_amt) AS annual_premium_amt, 
							SUM(pt.premium_amt) AS premium_amt 
						FROM edw_core.tpolicy_transaction as pt
						INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no -- RS Added
						WHERE pt.product_sk in (1, 5) -- Home and Condo
						AND cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts -- RS Updated
						GROUP BY pt.policy_sk, pt.effective_dt_sk, pt.transaction_seq_no, pt.coverage_sk, pt.internal_coverage_sk
					) as pt 
					LEFT JOIN edw_core.thome_coverage as hc ON pt.coverage_sk = hc.home_coverage_sk
					LEFT JOIN edw_core.thome_additional_coverage as hac ON hc.home_coverage_sk = hac.home_coverage_sk
					LEFT JOIN edw_core.tinternal_coverage as ic ON pt.internal_coverage_sk = ic.internal_coverage_sk
					WHERE  pt.policy_sk = ptf.policy_sk
						AND pt.effective_dt_sk = ptf.effective_dt_sk
						AND pt.transaction_seq_no = ptf.transaction_seq_no
					--
					UNION ALL
					SELECT DISTINCT
						hc.policy_no as policyNumber
						,'MEDPM' as coverageCd
						,'Medical' as coverageDesc
						,0.0 as changeAmount
						,0.0 as currentAmount
						,CAST(hc.medical_payments_limit_amt as NVARCHAR(255)) as [limit]
						,'0.0' as deductible
					FROM [edw_temp].[policy_ivans_home_temp1] as pt 
					INNER JOIN edw_core.thome_coverage as hc
					ON pt.coverage_sk = hc.home_coverage_sk
					WHERE  pt.policy_sk = ptf.policy_sk
						AND pt.effective_dt_sk = ptf.effective_dt_sk
						AND pt.transaction_seq_no = ptf.transaction_seq_no
				) jd FOR JSON PATH, INCLUDE_NULL_VALUES
			) AS Home_Coverages
			FROM [edw_temp].[policy_ivans_home_temp1] as ptf
		) temp3
		
		SELECT temp4.*
		INTO [edw_temp].[policy_ivans_home_temp4]
		FROM (
		SELECT
		    ptf.policy_no, ptf.effective_dt, ptf.transaction_seq_no,
		    (
				SELECT uniqueId, policyNumber, commercialName, addr1, city, [state], zip, natureInterestCd, accountNumberId
				FROM (
					SELECT
						tm.policy_no, tm.effective_dt, tm.transaction_seq_no,
						--CONCAT('M-', tm.mortgage_sk) as unique_id,
						CONCAT('M-', ROW_NUMBER() OVER (PARTITION BY tm.policy_no, tm.effective_dt, tm.transaction_seq_no ORDER BY tm.mortgage_sk ASC)) as uniqueId,
						tm.policy_no as policyNumber,
						TRIM(NULLIF(tm.mortgagee_nm, 'null')) as commercialName,
						COALESCE(tm.address_line_1, '') as addr1,
						COALESCE(tm.city_nm, '') as city,
						COALESCE(tm.state_cd, '') as [state],
						COALESCE(tm.zip_cd, '') as zip,
						-- '' as Latitude,
						-- '' as Longitude,
						-- '' as County,
						'MORTG' as natureInterestCd,
						COALESCE(tm.loan_no, '') as accountNumberId
					FROM [edw_core].[tmortgagee] tm
					INNER JOIN edw_core.tpolicy_history ph ON tm.policy_history_sk = ph.policy_history_sk
					WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
					UNION ALL
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
				) AS jdata
					WHERE  ptf.policy_no = jdata.policy_no
						AND ptf.effective_dt = jdata.effective_dt
						AND ptf.transaction_seq_no = jdata.transaction_seq_no
				FOR JSON PATH, INCLUDE_NULL_VALUES 
			) AS Additional_Interests
			FROM (SELECT tm.policy_no, tm.effective_dt, tm.transaction_seq_no FROM [edw_core].[tmortgagee] tm
					INNER JOIN edw_core.tpolicy_history ph ON tm.policy_history_sk = ph.policy_history_sk
					WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
					UNION 
				SELECT ai.policy_no, ai.effective_dt, ai.transaction_seq_no FROM edw_core.tadditional_interest ai
				INNER JOIN edw_core.tpolicy_history ph ON ai.policy_history_sk = ph.policy_history_sk
				WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts
				) as ptf
		) temp4

		SELECT temp5.*
		INTO [edw_temp].[policy_ivans_home_temp5]
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
						FROM edw_core.tcollection_scheduled_item csi
						LEFT JOIN edw_core.tcollection_class_type cct
						on csi.collection_class_type_sk = cct.collection_class_type_sk
						WHERE  ptf.policy_no = csi.policy_no
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
		INTO [edw_temp].[policy_ivans_home_temp6]
		FROM (
			SELECT
			    ptf.policy_sk, ptf.effective_dt_sk ,ptf.transaction_seq_no,
			    (
					SELECT 
						policyNumber
						,CONCAT('L', ROW_NUMBER() OVER (PARTITION BY policyNumber, transaction_seq_no ORDER BY policyNumber, transaction_seq_no, (CONCAT(address1, '-', city, '-', [state], '-', RIGHT('00000' + zip, 5), '-', county)))) as location_no
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
							,pt.premium_amt as premium
							,0 as saLimit
							,floor(tcct.scheduled_highest_value_limit_amt) as hviLimit
							,tcl.address_line_1 as address1
							,tcl.address_line_2 as address2
							,tcl.city_nm as city
							,tcl.county_nm as county
							,tcl.state_cd as [state] 
							,tcl.zip_cd as zip
							,'IMInfo' as riskType
						--FROM policy_transaction as pt
						FROM edw_core.tpolicy_transaction pt
						INNER JOIN edw_core.tpolicy tp
						on pt.policy_sk = tp.policy_sk
						LEFT JOIN edw_core.tcustomer tc
						on pt.customer_sk = tc.customer_sk
						LEFT JOIN edw_core.tcollection_coverage tcc
						ON tp.policy_no = tcc.policy_no
						AND tp.effective_dt = tcc.effective_dt
						AND pt.transaction_seq_no = tcc.transaction_seq_no
						LEFT JOIN edw_core.thome_coverage thc
						ON tp.policy_no = thc.policy_no
						AND tp.effective_dt = thc.effective_dt
						AND pt.transaction_seq_no = thc.transaction_seq_no
						LEFT JOIN edw_core.tcollection_location tcl
						on tcc.collection_location_sk = tcl.collection_location_sk
						LEFT JOIN edw_core.tcollection_class_type tcct
						on thc.home_coverage_sk = tcct.home_coverage_sk
						LEFT JOIN edw_core.tinternal_coverage as ic
						ON pt.internal_coverage_sk = ic.internal_coverage_sk
						INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no -- RS Added
						WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts -- RS Updated
						and coalesce(pt.premium_amt, 0) + coalesce(tcct.scheduled_limit_amt, 0) + coalesce(tcct.scheduled_highest_value_limit_amt, 0) <> 0 
						and ic.aslob_cd in ('090', '040') and ic.product_cd in ('HO', 'CO') and ic.internal_coverage_category_nm = 'Premium' and (ic.internal_coverage_cd like '%chedule%' or ic.internal_coverage_cd like '%lux%')
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
							,pt.premium_amt as premium
							,floor(tcct.blanket_single_article_limit_amt) as saLimit
							,floor(tcct.blanket_highest_value_limit_amt) as hviLimit
							,tcl.address_line_1 as address1
							,tcl.address_line_2 as address2
							,tcl.city_nm as city
							,tcl.county_nm as county
							,tcl.state_cd as [state]
							,tcl.zip_cd as zip
							,'IMInfo' as riskType
						--FROM policy_transaction as pt
						FROM edw_core.tpolicy_transaction pt
						INNER JOIN edw_core.tpolicy tp
						on pt.policy_sk = tp.policy_sk
						LEFT JOIN edw_core.tcustomer tc
						on pt.customer_sk = tc.customer_sk
						LEFT JOIN edw_core.tcollection_coverage tcc
						ON tp.policy_no = tcc.policy_no
						AND tp.effective_dt = tcc.effective_dt
						AND pt.transaction_seq_no = tcc.transaction_seq_no
						LEFT JOIN edw_core.thome_coverage thc
						ON tp.policy_no = thc.policy_no
						AND tp.effective_dt = thc.effective_dt
						AND pt.transaction_seq_no = thc.transaction_seq_no
						LEFT JOIN edw_core.tcollection_location tcl
						on tcc.collection_location_sk = tcl.collection_location_sk
						LEFT JOIN edw_core.tcollection_class_type tcct
						on thc.home_coverage_sk = tcct.home_coverage_sk
						LEFT JOIN edw_core.tinternal_coverage as ic
						ON pt.internal_coverage_sk = ic.internal_coverage_sk
						INNER JOIN edw_core.tpolicy_history ph ON pt.policy_sk = ph.policy_sk AND pt.transaction_seq_no = ph.transaction_seq_no -- RS Added
						WHERE cast(ph.transaction_ts as datetime2(7)) > @last_source_extract_ts -- RS Updated
						and coalesce(pt.premium_amt, 0) + coalesce(tcct.blanket_limit_amt, 0) + coalesce(tcct.blanket_single_article_limit_amt, 0) + coalesce(tcct.blanket_highest_value_limit_amt, 0) <> 0 
						and ic.aslob_cd in ('090', '040') and ic.product_cd in ('HO', 'CO') and ic.internal_coverage_category_nm = 'Premium' and (ic.internal_coverage_cd like '%lanket%' or ic.internal_coverage_cd like '%lux%')
					) ud
						WHERE  ud.policy_sk = ptf.policy_sk
                       AND ud.effective_dt_sk = ptf.effective_dt_sk
                       AND ud.transaction_seq_no = ptf.transaction_seq_no
					FOR JSON PATH, INCLUDE_NULL_VALUES 
				) Home_Collection_Coverages
			FROM [edw_temp].[policy_ivans_home_temp1] as ptf
        ) temp6

		SELECT temp7.*
		INTO [edw_temp].[policy_ivans_home_temp7]
		FROM (
            SELECT original_policy_no, min(effective_dt) as min_effective_dt, min(expiration_dt) as min_expiration_dt 
                FROM edw_core.tpolicy 
            GROUP BY original_policy_no                
		) temp7

		SELECT temp8.*
		INTO [edw_temp].[policy_ivans_home_temp8]
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
		,hl.latitude as [022_Latitude]
		,hl.longitude as [023_Longitude]
		,c.mailing_address_county_nm as [024_County]
		,'' as [025_PhoneTypeCd]
		,RIGHT(REPLACE(TRANSLATE(c.home_phone_no, '+-/()#', '      '), ' ', ''), 10) as [026_HomePhoneNumber]
		,RIGHT(REPLACE(TRANSLATE(c.mobile_phone_no, '+-/()#', '      '), ' ', ''), 10) as [026_MobilePhoneNumber]
		,c.email as [027_EmailAddr]
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
		,p.policy_sk as [062_id]
		,c.customer_id as [063_InsurerId]
		,hl.address_line_1 as [064_Addr1]
		,hl.city_nm as [065_City]
		,hl.state_cd as [066_StateProvCd]
		,hl.zip_cd as [067_PostalCode]
		,hl.latitude as [068_Latitude]
		,hl.longitude as [069_Longitude]
		,hl.county_nm as [070_County]
		,'' as [081_FireDistrict]
		,hc.distance_to_fire_station_miles as [082_FireStation]
		,'' as [083_RiskLocationCd]
		,pr.product_nm as [084_LOBCd]
		,CASE WHEN p.uw_company_nm = 'Vault Reciprocal Exchange' THEN '16186' WHEN p.uw_company_nm = 'Vault E & S Insurance Company' THEN '16237' ELSE '' END AS [085_NAICCd]
		,'' as [086_CoverageCd]
		,'' as [087_CoverageDesc]
		,'' as [088_Amt]
		,'' as [089_Amt] 
		,'DWEL' as [090_RiskType]
		,'' as [091_PrincipalUnitAtRiskInd]
		,CASE
			WHEN LOWER(hc.residence_type) = 'tenant' THEN '04'
			WHEN LOWER(hc.residence_type) = 'homeowners' THEN '05'
			WHEN LOWER(hc.residence_type) IN (
				'condominium', 'condminium', 'condo'
			) THEN '06'
			ELSE 'NA'
			END as [092_PolicyTypeCd]
		,'' as [093_PurchaseDt]
		,NULL as [094_Amt]
		,'' as [095_TerritoryCd]
		,'' as [096_WiringTypeCd]
		,hc.fire_protection as [097_FireProtectionClassCd]
		,hc.distance_to_fire_station_miles as [098_DistanceToFireStation]
		,hc.distance_to_fire_hydrant_feet as [099_DistanceToHydrant]
		,CASE
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '),  '\r', ' ')) = 'Tenant' THEN 'Tenant' 
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Rented to Others' THEN 'Rented to Others' 
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Partially Rented to Others' THEN 'Partially Rented to Others' 
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Vacant' THEN 'Vacant'
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' '))
				IN (
					'Primary', 'Seasonal', 'Seasonal with Water Leak Detection (No Alarm) or Low Temperature Monitoring Device', 
					'Seasonal/Secondary', 'Seasonal without Primary', 
					'Seasonal w/ Water Leak Detection/Shut off (No Alarm) or Temperature Monitoring Device', 
					'Seasonal with Full Time Live in Care Taker or Water Leak Detection/Shut off (Alarm)', 
					'Seasonal with Water Leak Detection/Shut off (No Alarm) or Temperature Monitoring Device', 
					'Seasonal Full Time Live In Care Taker or Water Leak Detection (Alarm)', 
					'Seasonal with Primary Insured by Vault', 
					'Seasonal with primary residence insured by Vault', 
					'Seasonal (with Vault Primary Residence)', 
					'Seasonal with Full Time Live In Care Taker', 
					'Seasonal (with no Vault Primary Residence)', 
					'Seasonal with Water Leak Detection/Shut off (No Alarm) or Low Temperature Monitoring Device', 
					'Seasonal w Water Leak(Alarm) or Full Time Live In Care Taker', 
					'Seasonal with Full Time Live In Care Taker or Water Leak Detection/Shut off (Alarm)', 
					'Seasonal with no primary residence insured by Vault', 
					'Seasonal with Full Time Live In Care Taker or Water Leak Detection (Alarm)', 
					'Seasonal w Water Leak (No Alarm) or Low Temperature Monitoring Device', 
					'Seasonal with Full Time Live in Care Taker or  Water Leak Detection Shut off (Alarm)', 
					'Seasonal w Water Leak(Alarm) or Full Time Live In Care Taker'
				)
			THEN 'Owner'
			ELSE 'NA'
		END as [100_OccupancyTypeCd]
		,''  as [101_FireExtinguiserInd]
		,COALESCE(hac.central_reporting_burglar_alarm_in, 'no')  as [102_ProtectionDeviceBurglarCd] --
		,COALESCE(hac.central_reporting_fire_alarm_in, 'no') as [103_ProtectionDeviceFireCd]
		,hc.construction_type as [104_ConstructionCd]
		,hc.built_year as [105_YearBuilt]
		,'' as [106_FoundationCd]
		,'' as [107_BldgCodeEffectivenessGradeCd]
		,'' as [108_BldgEffectivenessGradeTypeCd]
		,hc.no_of_stories as [109_NumStories]
		,'' as [110_BasementArea]
		,CASE WHEN hc.basement_type IN ('Unknown', 'No Basement') THEN 0 ELSE 1 END as [111_NumBasements]
		,hc.roof_covering as [112_RoofingMaterialCd]
		,'' as [113_ConstructionPct]
		,c.family_account_in as [114_NumFamilies]
		,'' as [115_HeatSourcePrimaryCd]
		,'' as [116_HeatSourceSupplementalCd]
		,hc.occupancy_type as [117_OccupancyCd]
		,hc.total_finished_square_feet as [118_NumUnits]
		,'' as [119_RoofingImprovementCd]
		,hc.roof_updated_year as [120_RoofingImprovementYear]
		,hc.electrical_updated_year as [121_WiringImprovementYear]
		,'' as [122_OtherImprovementDesc]
		,'' as [123_OtherImprovementCd]
		,'' as [124_OtherImprovementDt]
		,c.customer_nm as [125_CommercialName]
		,'' as [126_Addr1]
		,'' as [127_City]
		,'' as [128_StateProvCd]
		,'' as [129_PostalCode]
		,'' as [130_Country]
		,'' as [131_Latitude]
		,'' as [132_Longitude]
		,'' as [133_ResidenceTypeCd]
		,hc.built_year as [134_YearBuilt]
		,TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) as [135_DwellUseCd]
		,CASE
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Tenant' THEN 'Tenant' 
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Rented to Others' THEN 'Rented to Others'
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '),'\r', ' ')) = 'Partially Rented to Others' THEN 'Partially Rented to Others'
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) = 'Vacant' THEN 'Vacant'
			WHEN TRIM(REPLACE(REPLACE(hc.occupancy_type, '\n', ' '), '\r', ' ')) IN (
				'Primary', 'Seasonal', 'Seasonal with Water Leak Detection (No Alarm) or Low Temperature Monitoring Device', 
				'Seasonal/Secondary', 'Seasonal without Primary', 
				'Seasonal w/ Water Leak Detection/Shut off (No Alarm) or Temperature Monitoring Device', 
				'Seasonal with Full Time Live in Care Taker or Water Leak Detection/Shut off (Alarm)', 
				'Seasonal with Water Leak Detection/Shut off (No Alarm) or Temperature Monitoring Device', 
				'Seasonal Full Time Live In Care Taker or Water Leak Detection (Alarm)', 
				'Seasonal with Primary Insured by Vault', 
				'Seasonal with primary residence insured by Vault', 
				'Seasonal (with Vault Primary Residence)', 
				'Seasonal with Full Time Live In Care Taker', 
				'Seasonal (with no Vault Primary Residence)', 
				'Seasonal with Water Leak Detection/Shut off (No Alarm) or Low Temperature Monitoring Device', 
				'Seasonal w Water Leak(Alarm) or Full Time Live In Care Taker', 
				'Seasonal with Full Time Live In Care Taker or Water Leak Detection/Shut off (Alarm)', 
				'Seasonal with no primary residence insured by Vault', 
				'Seasonal with Full Time Live In Care Taker or Water Leak Detection (Alarm)', 
				'Seasonal w Water Leak (No Alarm) or Low Temperature Monitoring Device', 
				'Seasonal with Full Time Live in Care Taker or  Water Leak Detection Shut off (Alarm)', 
				'Seasonal w Water Leak(Alarm) or Full Time Live In Care Taker'
			) THEN 'Owner'
			ELSE 'NA'
		END as [136_OccupancyTypeCd]
		,'' as [137_BldgEffectivenessGradeTypeCd]
		,hc.no_of_stories as [138_NumStories]
		,'' as [139_BasementArea]
		,CASE WHEN hc.basement_type IN ('Unknown', 'No Basement') THEN 0 ELSE 1 END as [140_NumBasements]
		,hac.sinkhole_collapse_in as [141_TerritoryCd]
		,'' as [142_SeacoastOrOtherBodyWaterProximityCd]
		,hc.distance_to_coast as [143_NumUnits]
		,hc.windspeed_of_design as [144_WindPlanInd]
		,hc.dwelling_limit_amt + hc.other_Structures_limit_amt + hc.contents_limit_amt as [145_Amt] -- neds to sum?
		,hc.hvac_updated_year as [146_HeatingImprovementCd]
		,'' as [147_HeatingImprovementYear]
		,hc.plumbing_updated_year as [148_PlumbingImprovementCd]
		,'' as [149_PlumbingImprovementYear]
		,'' as [150_RoofingImprovementCd]
		,hc.roof_updated_year as [151_RoofingImprovementYear]
		,hc.electrical_updated_year as [152_WiringImprovementYear]
		,'' as [153_OtherImprovementDesc]
		,'' as [154_OtherImprovementCd]
		,'' as [155_OtherImprovementDt]
		,'' as [156_NumUnits]
		,'' as [157_AboveGroundInd]
		,'' as [158_ApprovedFenceInd]
		,'' as [159_DivingBoardInd]
		,'' as [160_SlideInd]
		,'' as [161_ModelYear]
		,'' as [162_Manufacturer]
		,'' as [163_Model]
		,'' as [164_SerialIdNumber]
		,'' as [165_PurchaseDt]
		,'' as [166_PurchasedNewInd]
		,'' as [167_Amt]
		,'' as [168_NumUnits]
		,'' as [169_NumUnits]
		,'' as [170_MobileHomeInParkInd]
		,'' as [171_PermanentConnectionToElectricInd]
		,'' as [172_PermanentConnectionToWaterInd]
		,'' as [173_PermanentConnectionToSewerInd]
		,'' as [174_DoublewideMobileHomeTrailerInd]
		,'' as [175_NumBedrooms]
		,'' as [176_MobileHomeAdditionsExtensionsInd]
		,'' as [177_AnchoringSystemCd]
		,'' as [178_AnimalTypeCd]
		,hac.canine_liability_exclusion_in as [179_BreedCd]
		,'' as [180_NumUnits]
		,hac.animal_related_liability_exclusion_in as [181_BiteHistoryInd]
		/* */
		,jhc.Home_Coverages
		,jhcc.Home_Collection_Coverages
		,jai.Additional_Interests
		,jsi.Scheduled_Items
		,pt.transaction_seq_no as [transaction_seq_no]
		--
		,pt.transaction_ts as policy_history_transaction_ts
		--
		,tprc.national_producer_no
		INTO [edw_temp].[policy_ivans_home_temp2]
		--
		FROM [edw_temp].[policy_ivans_home_temp1] pt
		INNER JOIN edw_core.tpolicy p
		ON pt.policy_sk = p.policy_sk
		INNER JOIN edw_core.tbroker b
		ON p.broker_id = b.broker_id
		LEFT JOIN edw_core.tproduct pr
		ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_insured as poi
		ON p.policy_no = poi.policy_no
		AND p.effective_dt = poi.effective_dt
		AND pt.transaction_seq_no = poi.transaction_seq_no
		AND poi.primary_insured_in = 'Yes'
		LEFT JOIN edw_core.tdate AS d1
		ON pt.transaction_effective_dt_sk = d1.date_sk
        LEFT JOIN edw_core.tdate AS d2
		ON pt.transaction_dt_sk = d2.date_sk
		LEFT JOIN [edw_core].[tpolicy_transaction_type] ptt
		on pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
		LEFT JOIN [edw_core].[tbillingaccount] ba
		on p.billingaccount_sk = ba.billingaccount_sk
		LEFT JOIN edw_core.tcustomer AS c
		ON pt.customer_sk = c.customer_sk
		LEFT JOIN [edw_core].[thome_coverage] hc
		on p.policy_no = hc.policy_no
		AND p.effective_dt = hc.effective_dt
		AND pt.transaction_seq_no = hc.transaction_seq_no
		LEFT JOIN [edw_core].[thome_additional_coverage] hac
		on hc.home_coverage_sk = hac.home_coverage_sk
		LEFT JOIN [edw_core].[thome_location] hl
		on hc.home_location_sk = hl.home_location_sk
		LEFT JOIN [edw_temp].[policy_ivans_home_temp8] lh
		on p.policy_no = lh.policy_no
		AND p.effective_dt = lh.effective_dt
		AND pt.transaction_seq_no = lh.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_home_temp7] AS op
		ON p.original_policy_no = op.original_policy_no
		LEFT JOIN [edw_temp].[policy_ivans_home_temp3] jhc
		on pt.policy_sk = jhc.policy_sk
           AND pt.effective_dt_sk = jhc.effective_dt_sk
           AND pt.transaction_seq_no = jhc.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_home_temp6] jhcc
		on pt.policy_sk = jhcc.policy_sk
           AND pt.effective_dt_sk = jhcc.effective_dt_sk
           AND pt.transaction_seq_no = jhcc.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_home_temp4] jai
		on p.policy_no = jai.policy_no
           AND p.effective_dt = jai.effective_dt
           AND pt.transaction_seq_no = jai.transaction_seq_no
		LEFT JOIN [edw_temp].[policy_ivans_home_temp5] jsi
		on p.policy_no = jsi.policy_no
           AND p.effective_dt = jsi.effective_dt
           AND pt.transaction_seq_no = jsi.transaction_seq_no
		LEFT JOIN (
				select broker_sk, broker_id, national_producer_no
				,ROW_NUMBER() OVER (PARTITION BY broker_id ORDER BY broker_sk DESC) AS rn
				from edw_core.tproducer
			) tprc
		ON p.broker_id = tprc.broker_id AND tprc.rn = 1
		WHERE cast(pt.transaction_ts as datetime2(7)) > @last_source_extract_ts
		AND b.ivans_y_account IS NOT NULL

		-- Start Insert process
		INSERT INTO [edw_integration].[policy_ivans_home_feed](
			[MsgTypeCd_001]
			,[BusinessPurposeTypeCd_002]
			,[TransactionRequestDt_003]
			,[TransactionEffectiveDt_004]
			,[CurCd_005]
			,[BroadLOBCd_006]
			,[SourceSystem_008]
			,[ContractNumber_009]
			,[ProducerSubCode_010]
			,[InsurerId_011]
			,[Surname_012]
			,[GivenName_013]
			,[OtherGivenName_014]
			,[Prefix_015]
			,[AddrTypeCd_016]
			,[Addr1_017]
			,[City_018]
			,[StateProvCd_019]
			,[PostalCode_020]
			,[Country_021]
			,[Latitude_022]
			,[Longitude_023]
			,[County_024]
			,[PhoneTypeCd_025]
			,[PhoneNumber_026]
			,[EmailAddr_027]
			,[InsuredOrPrincipalRoleCd_028]
			,[InsuredOrPrincipalRoleDesc_029]
			,[PolicyNumber_030]
			,[BroadLOBCd_031]
			,[LOBCd_032]
			,[NAICCd_033]
			,[EffectiveDt_034]
			,[ExpirationDt_035]
			,[BillingAccountNumber_036]
			,[ControllingStateProvCd_037]
			,[BillingMethodCd_038]
			,[Amt_039]
			,[Amt_040]
			,[LanguageCd_041]
			,[OriginalPolicyInceptionDt_042]
			,[PayorCd_043]
			,[RenewalBillingMethodCd_044]
			,[RenewalPayorCd_045]
			,[FormNumber_046]
			,[FormName_047]
			,[EditionDt_048]
			,[IterationNumber_049]
			,[TotalPaidLossAmt_050]
			,[NumLosses_051]
			,[PolicyCd_052]
			,[PolicyNumber_053]
			,[LOBCd_054]
			,[NAICCd_055]
			,[InsurerName_056]
			,[EffectiveDt_057]
			,[ExpirationDt_058]
			,[MethodPaymentCd_059]
			,[PaymentPlanCd_060]
			,[PaidInFullInd_061]
			,[id_062]
			,[InsurerId_063]
			,[Addr1_064]
			,[City_065]
			,[StateProvCd_066]
			,[PostalCode_067]
			,[Latitude_068]
			,[Longitude_069]
			,[County_070]
			,[Dummy_071]
			,[Dummy_072]
			,[Dummy_073]
			,[Dummy_074]
			,[Dummy_075]
			,[Dummy_076]
			,[Dummy_077]
			,[Dummy_078]
			,[Dummy_079]
			,[Dummy_080]
			,[Dummy_081]
			,[FireStation_082]
			,[RiskLocationCd_083]
			,[LOBCd_084]
			,[NAICCd_085]
			,[CoverageCd_086]
			,[CoverageDesc_087]
			,[Amt_088]
			,[Amt_089]
			,[RiskType_090]
			,[PrincipalUnitAtRiskInd_091]
			,[PolicyTypeCd_092]
			,[PurchaseDt_093]
			,[Amt_094]
			,[TerritoryCd_095]
			,[WiringTypeCd_096]
			,[FireProtectionClassCd_097]
			,[DistanceToFireStation_098]
			,[DistanceToHydrant_099]
			,[OccupancyTypeCd_100]
			,[FireExtinguiserInd_101]
			,[ProtectionDeviceBurglarCd_102]
			,[ProtectionDeviceFireCd_103]
			,[ConstructionCd_104]
			,[YearBuilt_105]
			,[FoundationCd_106]
			,[BldgCodeEffectivenessGradeCd_107]
			,[BldgEffectivenessGradeTypeCd_108]
			,[NumStories_109]
			,[BasementArea_110]
			,[NumBasements_111]
			,[RoofingMaterialCd_112]
			,[ConstructionPct_113]
			,[NumFamilies_114]
			,[HeatSourcePrimaryCd_115]
			,[HeatSourceSupplementalCd_116]
			,[OccupancyCd_117]
			,[NumUnits_118]
			,[RoofingImprovementCd_119]
			,[RoofingImprovementYear_120]
			,[WiringImprovementYear_121]
			,[OtherImprovementDesc_122]
			,[OtherImprovementCd_123]
			,[OtherImprovementDt_124]
			,[CommercialName_125]
			,[Addr1_126]
			,[City_127]
			,[StateProvCd_128]
			,[PostalCode_129]
			,[Country_130]
			,[Latitude_131]
			,[Longitude_132]
			,[ResidenceTypeCd_133]
			,[YearBuilt_134]
			,[DwellUseCd_135]
			,[OccupancyTypeCd_136]
			,[BldgEffectivenessGradeTypeCd_137]
			,[NumStories_138]
			,[BasementArea_139]
			,[NumBasements_140]
			,[TerritoryCd_141]
			,[SeacoastOrOtherBodyWaterProximityCd_142]
			,[NumUnits_143]
			,[WindPlanInd_144]
			,[Amt_145]
			,[HeatingImprovementCd_146]
			,[HeatingImprovementYear_147]
			,[PlumbingImprovementCd_148]
			,[PlumbingImprovementYear_149]
			,[RoofingImprovementCd_150]
			,[RoofingImprovementYear_151]
			,[WiringImprovementYear_152]
			,[OtherImprovementDesc_153]
			,[OtherImprovementCd_154]
			,[OtherImprovementDt_155]
			,[NumUnits_156]
			,[AboveGroundInd_157]
			,[ApprovedFenceInd_158]
			,[DivingBoardInd_159]
			,[SlideInd_160]
			,[ModelYear_161]
			,[Manufacturer_162]
			,[Model_163]
			,[SerialIdNumber_164]
			,[PurchaseDt_165]
			,[PurchasedNewInd_166]
			,[Amt_167]
			,[NumUnits_168]
			,[NumUnits_169]
			,[MobileHomeInParkInd_170]
			,[PermanentConnectionToElectricInd_171]
			,[PermanentConnectionToWaterInd_172]
			,[PermanentConnectionToSewerInd_173]
			,[DoublewideMobileHomeTrailerInd_174]
			,[NumBedrooms_175]
			,[MobileHomeAdditionsExtensionsInd_176]
			,[AnchoringSystemCd_177]
			,[AnimalTypeCd_178]
			,[BreedCd_179]
			,[NumUnits_180]
			,[BiteHistoryInd_181]
			,[Home_Coverages]
			,[Home_Collection_Coverages]
			,[Additional_Interests]
			,[Scheduled_Items]
			,[transaction_seq_no]
			,[create_ts]
			,[update_ts]
			,[etl_audit_sk]
			,[NIPRid_200]
		)
		SELECT [001_MsgTypeCd]
			,[002_BusinessPurposeTypeCd]
			,[003_TransactionRequestDt]
			,[004_TransactionEffectiveDt]
			,[005_CurCd]
			,[006_BroadLOBCd]
			--,[007_IVANSXMLVersionCd]
			,[008_SourceSystem]
			,[009_ContractNumber]
			,[010_ProducerSubCode]
			,[011_InsurerId]
			,[012_Surname]
			,CASE WHEN
	  			([015_Prefix] IS NULL OR [015_Prefix] = '') AND
      			([013_GivenName] IS NULL OR [013_GivenName] = '') AND
      			([014_OtherGivenName] IS NULL OR [014_OtherGivenName] = '') AND
      			([012_Surname] IS NULL OR [012_Surname] = '') AND
      			([056_InsurerName] IS NOT NULL AND [056_InsurerName] <> '')
			THEN [056_InsurerName]
	  		ELSE
				[013_GivenName] END as [013_GivenName]
			,[014_OtherGivenName]
			--,[182_CommercialName]
			,[015_Prefix]
			,[016_AddrTypeCd]
			,[017_Addr1]
			,[018_City]
			,[019_StateProvCd]
			,[020_PostalCode]
			,[021_Country]
			,[022_Latitude]
			,[023_Longitude]
			,[024_County]
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
			END AS [PhoneNumber_026]
			,[027_EmailAddr]
			,[028_InsuredOrPrincipalRoleCd]
			,[029_InsuredOrPrincipalRoleDesc]
			,[030_PolicyNumber]
			,[031_BroadLOBCd]
			,[032_LOBCd]
			,[033_NAICCd]
			,[034_EffectiveDt]
			,[035_ExpirationDt]
			,[036_BillingAccountNumber]
			,[037_ControllingStateProvCd]
			,[038_BillingMethodCd]
			,[039_Amt]
			,[040_Amt]
			,[041_LanguageCd]
			,[042_OriginalPolicyInceptionDt]
			,[043_PayorCd]
			,[044_RenewalBillingMethodCd]
			,[045_RenewalPayorCd]
			,[046_FormNumber]
			,[047_FormName]
			,[048_EditionDt]
			,[049_IterationNumber]
			,[050_TotalPaidLossAmt]
			,[051_NumLosses]
			,[052_PolicyCd]
			,[053_PolicyNumber]
			,[054_LOBCd]
			,[055_NAICCd]
			,[056_InsurerName]
			,[057_EffectiveDt]
			,[058_ExpirationDt]
			,[059_MethodPaymentCd]
			,[060_PaymentPlanCd]
			,[061_PaidInFullInd]
			,[062_id]
			,[063_InsurerId]
			,[064_Addr1]
			,[065_City]
			,[066_StateProvCd]
			,[067_PostalCode]
			,[068_Latitude]
			,[069_Longitude]
			,[070_County]
			,'' as [Dummy_071]
			,'' as [Dummy_072]
			,'' as [Dummy_073]
			,'' as [Dummy_074]
			,'' as [Dummy_075]
			,'' as [Dummy_076]
			,'' as [Dummy_077]
			,'' as [Dummy_078]
			,'' as [Dummy_079]
			,'' as [Dummy_080]
			,'' as [Dummy_081]
			--,[081_FireDistrict]
			,[082_FireStation]
			,[083_RiskLocationCd]
			,[084_LOBCd]
			,[085_NAICCd]
			,[086_CoverageCd]
			,[087_CoverageDesc]
			,[088_Amt]
			,[089_Amt]
			,[090_RiskType]
			,[091_PrincipalUnitAtRiskInd]
			,[092_PolicyTypeCd]
			,[093_PurchaseDt]
			,[094_Amt]
			,[095_TerritoryCd]
			,[096_WiringTypeCd]
			,[097_FireProtectionClassCd]
			,[098_DistanceToFireStation]
			,[099_DistanceToHydrant]
			,[100_OccupancyTypeCd]
			,[101_FireExtinguiserInd]
			,[102_ProtectionDeviceBurglarCd]
			,[103_ProtectionDeviceFireCd]
			,[104_ConstructionCd]
			,[105_YearBuilt]
			,[106_FoundationCd]
			,[107_BldgCodeEffectivenessGradeCd]
			,[108_BldgEffectivenessGradeTypeCd]
			,[109_NumStories]
			,[110_BasementArea]
			,[111_NumBasements]
			,[112_RoofingMaterialCd]
			,[113_ConstructionPct]
			,[114_NumFamilies]
			,[115_HeatSourcePrimaryCd]
			,[116_HeatSourceSupplementalCd]
			,[117_OccupancyCd]
			,[118_NumUnits]
			,[119_RoofingImprovementCd]
			,[120_RoofingImprovementYear]
			,[121_WiringImprovementYear]
			,[122_OtherImprovementDesc]
			,[123_OtherImprovementCd]
			,[124_OtherImprovementDt]
			,[125_CommercialName]
			,[126_Addr1]
			,[127_City]
			,[128_StateProvCd]
			,[129_PostalCode]
			,[130_Country]
			,[131_Latitude]
			,[132_Longitude]
			,[133_ResidenceTypeCd]
			,[134_YearBuilt]
			,[135_DwellUseCd]
			,[136_OccupancyTypeCd]
			,[137_BldgEffectivenessGradeTypeCd]
			,[138_NumStories]
			,[139_BasementArea]
			,[140_NumBasements]
			,[141_TerritoryCd]
			,[142_SeacoastOrOtherBodyWaterProximityCd]
			,[143_NumUnits]
			,[144_WindPlanInd]
			,[145_Amt]
			,[146_HeatingImprovementCd]
			,[147_HeatingImprovementYear]
			,[148_PlumbingImprovementCd]
			,[149_PlumbingImprovementYear]
			,[150_RoofingImprovementCd]
			,[151_RoofingImprovementYear]
			,[152_WiringImprovementYear]
			,[153_OtherImprovementDesc]
			,[154_OtherImprovementCd]
			,[155_OtherImprovementDt]
			,[156_NumUnits]
			,[157_AboveGroundInd]
			,[158_ApprovedFenceInd]
			,[159_DivingBoardInd]
			,[160_SlideInd]
			,[161_ModelYear]
			,[162_Manufacturer]
			,[163_Model]
			,[164_SerialIdNumber]
			,[165_PurchaseDt]
			,[166_PurchasedNewInd]
			,[167_Amt]
			,[168_NumUnits]
			,[169_NumUnits]
			,[170_MobileHomeInParkInd]
			,[171_PermanentConnectionToElectricInd]
			,[172_PermanentConnectionToWaterInd]
			,[173_PermanentConnectionToSewerInd]
			,[174_DoublewideMobileHomeTrailerInd]
			,[175_NumBedrooms]
			,[176_MobileHomeAdditionsExtensionsInd]
			,[177_AnchoringSystemCd]
			,[178_AnimalTypeCd]
			,[179_BreedCd]
			,[180_NumUnits]
			,[181_BiteHistoryInd]
			,[Home_Coverages]
			,[Home_Collection_Coverages]
			,[Additional_Interests]
			,[Scheduled_Items]
			,[transaction_seq_no]
			,getdate()
			,getdate()
		    ,@etl_audit_sk
			,[national_producer_no]
		FROM [edw_temp].[policy_ivans_home_temp2]
		WHERE [053_PolicyNumber] IS NOT NULL;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_history_transaction_ts) FROM [edw_temp].[policy_ivans_home_temp2] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp1];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp2];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp3];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp4];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp5];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp6];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp7];
		DROP TABLE IF EXISTS [edw_temp].[policy_ivans_home_temp8];
		
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