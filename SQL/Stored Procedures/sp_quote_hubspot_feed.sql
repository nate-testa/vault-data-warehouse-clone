-- =============================================================================================================================
-- Description: This procedures inserts and updates quote hubspot data
------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 07/17/24		        Yunus Mohammed				1. Created this procedure
-- 07/29/24		        Architha Gudimalla			2. Excluded quotes with broker_id = 0
-- 08/08/24		        Architha Gudimalla			3. Added Customer id
-- 08/09/24		        Architha Gudimalla			4. Only include quotes with eff dt >= 20230601
-- 08/09/24		        Architha Gudimalla			5. Excluded test quotes
-- 08/16/24		        Architha Gudimalla			6. Added Recampaign indicator
-- 08/23/24		        Architha Gudimalla			7. Updated Recampaign indicator
-- 09/12/24		        Architha Gudimalla			8. Added Primary home fields
-- 09/21/24		        Architha Gudimalla			9. Added cast to null cols
-- 10/02/24		        Archtha Gudimalla			10. Add mailing address country
-- 10/07/24		        Archtha Gudimalla			11. Added Contruction
-- 10/16/24		        Archtha Gudimalla			12. Excluded cancelled pols in pending_non_renewal recampaign
-- 10/25/24		        Archtha Gudimalla			13. Added isnull to code when checking names for test quotes
-- 12/30/24		        Alberto Almario				14. VI35256 - Insured name update for entity/trust LLC
-- 01/13/25		        Alberto Almario				15. AD8013 - Included yacht data
-- 01/15/25		        Archtha Gudimalla			16. VI35258/AD8009 - Added new cols
-- 03/06/25		        Archtha Gudimalla			17. AD8781 - Send latest broker info
-- 03/28/25		        Archtha Gudimalla			18. VI36790/AD8898 - Added Target account
-- 03/28/25		        Archtha Gudimalla			19. VI36066/AD8907 - Added close_reason_desc
-- 04/05/25             Sandeep Gundreddy           20. Replaced Null with '' close_reason_desc in temp2 tp fix batch issue
-- 04/17/25		        Archtha Gudimalla			21. VI37310/AD9213 - Added monoline   
-- 05/12/25		        Archtha Gudimalla			22. AD9494 - Excluded forecast quotes  
-- 05/22/25		        Archtha Gudimalla			23. VI37383/AD9512 - Added broker state 
-- ============================================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_quote_hubspot_feed] 

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
		DECLARE @current_date DATETIME2(7)=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp0;

        --used to see if there are any changes on the broker/broker_vault
        select a.quote_no
        into edw_temp.quote_hubspot_feed_temp0
		from  [edw_integration].[quote_hubspot_feed] a
		inner join edw_core.tquote q on a.quote_no = q.quote_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        left join edw_core.tbroker br on br.broker_id = q.broker_id
        left join edw_core.tbroker_vault_team bvt on br.broker_id = bvt.broker_id and bvt.product_nm = pr.product_nm
                                                    and bvt.team_member_type = 'BusinessDevelopmentManager' and q.program_type = bvt.program_type
                                                    and  isnull(bvt.state_cd,q.risk_state_cd)=q.risk_state_cd
		where a.broker_id <> br.broker_id
		or isnull(a.bdm_nm,'') <> isnull(bvt.team_member_nm,'')
		or isnull(a.broker_tier,'') <> isnull(br.broker_tier,'')
		or isnull(a.national_agency_in,'') <> isnull(br.national_agency_in,'')
		or isnull(a.broker_nm,'') <> isnull(br.broker_nm,'');

 		DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp01;

		--get customer inforce counts
		SELECT customer_id = CASE 
								WHEN customer_id IS NULL THEN 
									'[Grand Total]' 
								ELSE customer_id 
							END
				, product_cd = CASE 
								WHEN pr.product_cd IS NULL THEN 
									'[Total' + case when customer_id is null then '- Overall' else '' end + ']' COLLATE SQL_Latin1_General_CP1_CI_AS 
								ELSE pr.product_cd 
								END
				, inforce_ct = COUNT(*)   
		into  edw_temp.quote_hubspot_feed_temp01
		FROM edw_core.tdaily_inforce_policy summ, edw_core.tproduct pr , edw_core.tcustomer cust 
		where inforce_dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(dd,-1,cast(getdate() as date)))
		and pr.product_sk = summ.product_sk 
		and summ.customer_sk = cust.customer_sk 
		GROUP BY ROLLUP (customer_id, pr.product_cd);
		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp1;
		
        with quote_collection_class_type as
        (
            select  quote_history_sk,
                    sum(blanket_limit_amt) as total_blanket_limit_amt,
                    sum(scheduled_limit_amt) as total_scheduled_limit_amt
            from
            edw_core.tquote_collection_class_type
            group by quote_history_sk
        )

        select
            q.quote_no,q.effective_dt,q.expiration_dt,h.transaction_type,h.producer_nm,
            q.customer_id,
            br.broker_id, br.broker_nm, br.broker_tier, br.national_agency_in,
            bvt.team_member_nm as bdm_nm,cust.vip_in,i.first_nm as insured_first_nm, 
            case when i.insured_type = 'Entity' then i.insured_nm  else i.last_nm end as insured_last_nm,
            h.underwriter_nm, q.uw_company_nm,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.address_line_1
            WHEN pr.product_cd = 'LUX'  THEN tqcl.address_line_1
            WHEN pr.product_cd = 'PEL' THEN tqpl.address_line_1
            END AS [risk_address_line_1], 
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.address_line_2
            WHEN pr.product_cd = 'LUX'  THEN tqcl.address_line_2
            WHEN pr.product_cd = 'PEL' THEN tqpl.address_line_2
            END as [risk_address_line_2], 
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.city_nm
            WHEN pr.product_cd = 'LUX'  THEN tqcl.city_nm
            WHEN pr.product_cd = 'PEL' THEN tqpl.city_nm
            END as risk_city_nm,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.state_cd
            WHEN pr.product_cd = 'LUX'  THEN tqcl.state_cd
            WHEN pr.product_cd = 'PEL' THEN tqpl.state_cd
            END as risk_state_cd,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.zip_cd
            WHEN pr.product_cd = 'LUX'  THEN tqcl.zip_cd
            WHEN pr.product_cd = 'PEL' THEN tqpl.zip_cd
            END [risk_zip_cd],
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.country_nm
            WHEN pr.product_cd = 'LUX'  THEN tqcl.country_nm
            WHEN pr.product_cd = 'PEL' THEN tqpl.country_nm
            END [risk_country_nm],
            h.premium_amt,
            q.quote_status,
            (ISNULL(tqhc.prior_nonwater_claim_ct,0) + ISNULL(tqhc.prior_water_claim_ct,0)) as claim_ct,
            (select top 1 note_desc from edw_core.tnote tn where tn.policy_no = q.quote_no order by coalesce(note_updated_ts,note_created_ts) desc) as note_desc,
            case when DATEDIFF("d",cast(getdate() as date),q.expiration_dt) between 0 and 90 and q.quote_status  in ('Not taken by Insured')
					 then 'Y' 
					 else 'N' 
				end AS recampaign_in,
            NULL AS rol_on_lost_business,
            NULL AS lost_company,
            h.not_taken_reason_desc as reason_quote_not_taken,
             CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhc.construction_type
            else cast(null as varchar)
            END AS construction,
            tqhc.[dwelling_limit_amt],
            tqhc.[contents_limit_amt], 
            tqhc.[other_structures_limit_amt],
            tqhc.[loss_of_use_limit_amt],
            tqhc.total_insured_value_amt,
            tqhc.[roof_covering],
            tqhc.[roof_updated_year],
            CASE WHEN q.product_cd in ('HO','CO') then h.insurance_score ELSE NULL END AS insurance_score,
            tqapc.bodily_injury_limit_amt as auto_liability_limit_amt,
            tqpc.pel_limit_amt,
            case when total_blanket_limit_amt > 0 and total_scheduled_limit_amt > 0 then 'Both'
            when total_blanket_limit_amt > 0 then 'Blanket'
            when total_scheduled_limit_amt > 0 then 'Scheduled'
            end as collections_coverage_type,
            tcct.total_blanket_limit_amt,
            tcct.total_scheduled_limit_amt,
            q.create_ts,
            q.update_ts,
			tqhac.primary_home_risk_address, 
			tqhac.primary_home_policy_effective_dt, 
			tqhac.primary_home_policy_expiration_dt, 
			tqhac.primary_home_carrier_nm, 
			tqhac.primary_home_coverage_a_threshold
            --added below on 1/15/25
            ,tqhc.occupancy_type
            ,tqhc.new_client_for_agency_in
            ,tqhc.current_underlying_company_nm
            ,q.target_account
            ,q.close_reason_desc
            ,case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end as monoline_in
            ,br.primary_address_state_cd broker_state
        into edw_temp.quote_hubspot_feed_temp1

        from edw_core.tquote q
        left join edw_core.tpolicy p on q.prior_term_policy_no = p.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        inner join edw_core.tquote_history h on h.quote_sk = q.quote_sk
        left join edw_core.tquote_insured i	on i.quote_history_sk = h.quote_history_sk and i.primary_insured_in = 'Yes'
        left join edw_core.tcustomer cust on cust.customer_id = q.customer_id
        left join edw_core.tbroker br on br.broker_id = q.broker_id
        left join edw_core.tbroker_vault_team bvt on br.broker_id = bvt.broker_id and bvt.product_nm = pr.product_nm
                                                    and bvt.team_member_type = 'BusinessDevelopmentManager' and q.program_type = bvt.program_type
                                                    and  isnull(bvt.state_cd,q.risk_state_cd)=q.risk_state_cd
        left join edw_core.tquote_home_location tqhl on tqhl.quote_no = q.quote_no
        left join edw_core.tquote_collection_location tqcl on tqcl.quote_no = q.quote_no
        left join edw_core.tquote_pel_location tqpl on tqpl.quote_history_sk = h.quote_history_sk and tqpl.primary_location_in = 'Yes'
        left join edw_core.tquote_home_coverage tqhc on tqhc.quote_history_sk=h.quote_history_sk
        left JOIN edw_core.tquote_home_additional_coverage AS tqhac ON tqhc.quote_home_coverage_sk = tqhac.quote_home_coverage_sk	
        left join edw_core.tquote_auto_policy_coverage tqapc on tqapc.quote_history_sk=h.quote_history_sk
        left join edw_core.tquote_pel_coverage tqpc on tqpc.quote_history_sk=h.quote_history_sk
        left join quote_collection_class_type as tcct on tcct.quote_history_sk = h.quote_history_sk 
		left join edw_temp.quote_hubspot_feed_temp01 pinf on cust.customer_id = pinf.customer_id and pr.product_cd = pinf.product_cd 
		left join edw_temp.quote_hubspot_feed_temp01 cinf on cust.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 

        where  h.latest_transaction_in = 'Y'
		and (greatest(q.create_ts,q.update_ts) > @last_source_extract_ts 
		 or exists (select 'x' from edw_temp.quote_hubspot_feed_temp0 a where a.quote_no = q.quote_no)
        )
        and q.broker_id <> '0'
        and q.effective_Dt >= '01-jun-2023'  
		and isnull(q.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%'      
		-- and q.product_cd <> 'BY'
        and q.forecast_quote_in = 'No'
        ;         

        --this is to pull in policies with pending non renewal = Y
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp2;
	
         with policy_collection_class_type as
        (
            select  policy_history_sk,
                    sum(blanket_limit_amt) as total_blanket_limit_amt,
                    sum(scheduled_limit_amt) as total_scheduled_limit_amt
            from
            edw_core.tcollection_class_type
            group by policy_history_sk
        )
        select
            q.policy_no,q.effective_dt,q.expiration_dt,h.transaction_type,h.producer_nm,
            q.customer_id,
            br.broker_id, br.broker_nm, br.broker_tier, br.national_agency_in,
            bvt.team_member_nm as bdm_nm,cust.vip_in,i.first_nm as insured_first_nm, 
            case when i.insured_type = 'Entity' then i.insured_nm  else i.last_nm end as insured_last_nm,
            h.underwriter_nm, q.uw_company_nm,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.address_line_1
            WHEN pr.product_cd = 'LUX'  THEN tqcl.address_line_1
            WHEN pr.product_cd = 'PEL' THEN tqpl.address_line_1
            END AS [risk_address_line_1], 
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.address_line_2
            WHEN pr.product_cd = 'LUX'  THEN tqcl.address_line_2
            WHEN pr.product_cd = 'PEL' THEN tqpl.address_line_2
            END as [risk_address_line_2], 
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.city_nm
            WHEN pr.product_cd = 'LUX'  THEN tqcl.city_nm
            WHEN pr.product_cd = 'PEL' THEN tqpl.city_nm
            END as risk_city_nm,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.state_cd
            WHEN pr.product_cd = 'LUX'  THEN tqcl.state_cd
            WHEN pr.product_cd = 'PEL' THEN tqpl.state_cd
            END as risk_state_cd,
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.zip_cd
            WHEN pr.product_cd = 'LUX'  THEN tqcl.zip_cd
            WHEN pr.product_cd = 'PEL' THEN tqpl.zip_cd
            END [risk_zip_cd],
            CASE
            WHEN pr.product_cd IN ('HO','CO') THEN tqhl.country_nm
            WHEN pr.product_cd = 'LUX'  THEN tqcl.country_nm
            WHEN pr.product_cd = 'PEL' THEN tqpl.country_nm
            END [risk_country_nm],
            h.premium_amt,
            q.policy_status,
            (ISNULL(tqhc.prior_nonwater_claim_ct,0) + ISNULL(tqhc.prior_water_claim_ct,0)) as claim_ct,
            (select top 1 note_desc from edw_core.tnote tn where tn.policy_no = q.policy_no order by coalesce(note_updated_ts,note_created_ts) desc) as note_desc,
            'Y' AS recampaign_in,
            cast(null as varchar) AS rol_on_lost_business,
            cast(null as varchar) AS lost_company,
            cast(null as varchar) as reason_policy_not_taken, 
            case
            WHEN pr.product_cd IN ('HO','CO') THEN tqhc.construction_type
            else cast(null as varchar)
            END AS construction,
            tqhc.[dwelling_limit_amt],
            tqhc.[contents_limit_amt], 
            tqhc.[other_structures_limit_amt],
            tqhc.[loss_of_use_limit_amt],
            tqhc.total_insured_value_amt,
            tqhc.[roof_covering],
            tqhc.[roof_updated_year],
            CASE WHEN q.product_cd in ('HO','CO') then h.insurance_score ELSE NULL END AS insurance_score,
            tqapc.bodily_injury_limit_amt as auto_liability_limit_amt,
            tqpc.pel_limit_amt,
            case when total_blanket_limit_amt > 0 and total_scheduled_limit_amt > 0 then 'Both'
            when total_blanket_limit_amt > 0 then 'Blanket'
            when total_scheduled_limit_amt > 0 then 'Scheduled'
            end as collections_coverage_type,
            tcct.total_blanket_limit_amt,
            tcct.total_scheduled_limit_amt,
            q.create_ts,
            q.update_ts,
			tqhac.primary_home_risk_address, 
			tqhac.primary_home_policy_effective_dt, 
			tqhac.primary_home_policy_expiration_dt, 
			tqhac.primary_home_carrier_nm, 
			tqhac.primary_home_coverage_a_threshold
            --added below on 1/15/25
            ,tqhc.occupancy_type
            ,tqhc.new_client_for_agency_in
            ,tqhc.current_underlying_company_nm
            ,q.target_account
            ,'' as close_reason_desc 
            ,case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end as monoline_in
            ,br.primary_address_state_cd broker_state
        into edw_temp.quote_hubspot_feed_temp2
        
        from edw_core.tpolicy q 
		--left join edw_core.tquote q1 on q1.quote_no = q.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        inner join edw_core.tpolicy_history h on h.policy_sk = q.policy_sk and h.latest_transaction_in = 'Y'
        left join edw_core.tpolicy_insured i	on i.policy_history_sk = h.policy_history_sk and i.primary_insured_in = 'Yes'
        left join edw_core.tcustomer cust on cust.customer_id = q.customer_id
        left join edw_core.tbroker br on br.broker_id = q.broker_id
        left join edw_core.tbroker_vault_team bvt on br.broker_id = bvt.broker_id and bvt.product_nm = pr.product_nm
                                                    and bvt.team_member_type = 'BusinessDevelopmentManager' and q.program_type = bvt.program_type
                                                    and  isnull(bvt.state_cd,q.risk_state_cd)=q.risk_state_cd
        left join edw_core.thome_location tqhl on tqhl.policy_no = q.policy_no
        left join edw_core.tcollection_location tqcl on tqcl.policy_no = q.policy_no
        left join edw_core.tpel_location tqpl on tqpl.policy_history_sk = h.policy_history_sk and tqpl.primary_location_in = 'Yes'
        left join edw_core.thome_coverage tqhc on tqhc.policy_history_sk=h.policy_history_sk
        left JOIN edw_core.thome_additional_coverage AS tqhac ON tqhc.home_coverage_sk = tqhac.home_coverage_sk	
        left join edw_core.tauto_policy_coverage tqapc on tqapc.policy_history_sk=h.policy_history_sk
        left join edw_core.tpel_coverage tqpc on tqpc.policy_history_sk=h.policy_history_sk
        left join policy_collection_class_type as tcct on tcct.policy_history_sk = h.policy_history_sk
		left join edw_temp.quote_hubspot_feed_temp01 pinf on cust.customer_id = pinf.customer_id and pr.product_cd = pinf.product_cd 
		left join edw_temp.quote_hubspot_feed_temp01 cinf on cust.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 

        where   q.broker_id <> '0'  
		and isnull(q.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%'    
		and pending_non_renewal_in = 'Yes'
		and q.expiration_dt between dateadd(YYYY,-1,dateadd(d,-1,cast(getdate() as date))) and dateadd(dd,90,dateadd(YYYY,-1,dateadd(d,-1,cast(getdate() as date))))
		and (isnull(non_renewal_sub_note_desc,'') like '%OTHER%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Renewal not taken%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Coverage no longer needed%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Coverage placed elseware%')       
		-- and q.product_cd <> 'BY'
        and q.policy_status <> 'Cancelled'
        ;
        --and q1.quote_no is null
      
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp3;
        
        select *
        into edw_temp.quote_hubspot_feed_temp3
        FROM
        (
            select *
            from edw_temp.quote_hubspot_feed_temp1
            union ALL
            select *
            from edw_temp.quote_hubspot_feed_temp2
        ) a;
        	

        -- Start Merge process
		MERGE INTO [edw_integration].[quote_hubspot_feed] AS target
        USING [edw_temp].[quote_hubspot_feed_temp3] AS source on target.quote_no = source.quote_no
        WHEN NOT MATCHED BY Target THEN
        INSERT
        (
            quote_no , effective_dt ,expiration_dt , transaction_type , broker_id , broker_nm ,broker_tier ,national_agency_in, bdm_nm, 
            vip_in, insured_first_nm, insured_last_nm, underwriter_nm, uw_company_nm ,risk_address_line_1 , risk_address_line_2 ,risk_city_nm ,
            risk_state_cd ,risk_zip_cd , 
            risk_country_nm,
            premium_amt, quote_status , claim_ct , note_desc , recampaign_in , rol_on_lost_business, 
            lost_company , reason_quote_not_taken, construction , dwelling_limit_amt ,contents_limit_amt , other_structures_limit_amt , 
            loss_of_use_limit_amt, total_insured_value_amt ,roof_covering , roof_updated_year , insurance_score , 
            auto_liability_limit_amt, pel_limit_amt, collections_coverage_type, total_blanket_limit_amt , total_scheduled_limit_amt ,producer_nm,
            create_ts, update_ts ,etl_audit_sk
            ,customer_id 
            ,primary_home_risk_address
			,primary_home_policy_effective_dt
			,primary_home_policy_expiration_dt 
			,primary_home_carrier_nm
			,primary_home_coverage_a_threshold
            --added below on 1/15/25
            ,occupancy_type
            ,new_client_for_agency_in
            ,current_underlying_company_nm
            ,target_account
            ,close_reason_desc
            ,monoline_in
            ,broker_state
        )
        VALUES
        (
         quote_no , effective_dt ,expiration_dt , transaction_type , broker_id , broker_nm ,broker_tier ,national_agency_in, bdm_nm, 
            vip_in, insured_first_nm, insured_last_nm, underwriter_nm, uw_company_nm ,risk_address_line_1 , risk_address_line_2 ,risk_city_nm ,
            risk_state_cd ,risk_zip_cd , 
            risk_country_nm,
            premium_amt, quote_status , claim_ct , note_desc , recampaign_in , rol_on_lost_business, 
            lost_company , reason_quote_not_taken, construction , dwelling_limit_amt ,contents_limit_amt , other_structures_limit_amt , 
            loss_of_use_limit_amt, total_insured_value_amt ,roof_covering , roof_updated_year , insurance_score , 
            auto_liability_limit_amt, pel_limit_amt, collections_coverage_type, total_blanket_limit_amt , total_scheduled_limit_amt ,producer_nm,
            getdate(), getdate(), @etl_audit_sk 
            ,customer_id 
            ,primary_home_risk_address
			,primary_home_policy_effective_dt
			,primary_home_policy_expiration_dt 
			,primary_home_carrier_nm
			,primary_home_coverage_a_threshold
            ,occupancy_type
            ,new_client_for_agency_in
            ,current_underlying_company_nm
            ,target_account
            ,close_reason_desc
            ,monoline_in
            ,broker_state
        )
        WHEN MATCHED THEN UPDATE
        SET        
            [target].effective_dt	=	[source].effective_dt,
            [target].expiration_dt	=	[source].expiration_dt,
            [target].transaction_type	=	[source].transaction_type,
            [target].broker_id	=	[source].broker_id,
            [target].broker_nm	=	[source].broker_nm,
            [target].broker_tier	=	[source].broker_tier,
            [target].national_agency_in	=	[source].national_agency_in,
            [target].bdm_nm	=	[source].bdm_nm,
            [target].vip_in	=	[source].vip_in,
            [target].insured_first_nm	=	[source].insured_first_nm,
            [target].insured_last_nm	=	[source].insured_last_nm,
            [target].underwriter_nm	=	[source].underwriter_nm,
            [target].uw_company_nm	=	[source].uw_company_nm,
            [target].risk_address_line_1	=	[source].risk_address_line_1,
            [target].risk_address_line_2	=	[source].risk_address_line_2,
            [target].risk_city_nm	=	[source].risk_city_nm,
            [target].risk_state_cd	=	[source].risk_state_cd,
            [target].risk_zip_cd	=	[source].risk_zip_cd,
            [target].risk_country_nm	=	[source].risk_country_nm,
            [target].premium_amt	=	[source].premium_amt,
            [target].quote_status	=	[source].quote_status,
            [target].claim_ct	=	[source].claim_ct,
            [target].note_desc	=	[source].note_desc,
            [target].recampaign_in	=	[source].recampaign_in,
            [target].rol_on_lost_business	=	[source].rol_on_lost_business,
            [target].lost_company	=	[source].lost_company,
            [target].reason_quote_not_taken	=	[source].reason_quote_not_taken,
            [target].construction	=	[source].construction,
            [target].dwelling_limit_amt	=	[source].dwelling_limit_amt,
            [target].contents_limit_amt	=	[source].contents_limit_amt,
            [target].other_structures_limit_amt	=	[source].other_structures_limit_amt,
            [target].loss_of_use_limit_amt	=	[source].loss_of_use_limit_amt,
            [target].total_insured_value_amt	=	[source].total_insured_value_amt,
            [target].roof_covering	=	[source].roof_covering,
            [target].roof_updated_year	=	[source].roof_updated_year,
            [target].insurance_score	=	[source].insurance_score,
            [target].auto_liability_limit_amt	=	[source].auto_liability_limit_amt,
            [target].pel_limit_amt	=	[source].pel_limit_amt,
            [target].collections_coverage_type	=	[source].collections_coverage_type,
            [target].total_blanket_limit_amt	=	[source].total_blanket_limit_amt,
            [target].total_scheduled_limit_amt	=	[source].total_scheduled_limit_amt,
            [target].producer_nm =   [source].producer_nm,
            [target].update_ts	=	GETDATE(),
            [target].etl_audit_sk	=	@etl_audit_sk,
            [target].customer_id	=	[source].customer_id,
            [target].primary_home_risk_address	        =	[source].primary_home_risk_address,
            [target].primary_home_policy_effective_dt	=	[source].primary_home_policy_effective_dt,
            [target].primary_home_policy_expiration_dt	=	[source].primary_home_policy_expiration_dt,
            [target].primary_home_carrier_nm	        =	[source].primary_home_carrier_nm,
            [target].primary_home_coverage_a_threshold	=	[source].primary_home_coverage_a_threshold,
            [target].occupancy_type	                    =	[source].occupancy_type,
            [target].new_client_for_agency_in	        =	[source].new_client_for_agency_in,
            [target].current_underlying_company_nm	    =	[source].current_underlying_company_nm,  
            [target].target_account	                    =	[source].target_account  ,  
            [target].close_reason_desc	                =	[source].close_reason_desc ,  
            [target].monoline_in	                    =	[source].monoline_in ,  
            [target].broker_state	                    =	[source].broker_state   
            ;
        
        SET @rows_affected=@@ROWCOUNT;

        -- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(create_ts,update_ts)) FROM edw_temp.[quote_hubspot_feed_temp1]),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table 
		DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp0;
		DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp01;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp1;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp2;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_temp3;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
