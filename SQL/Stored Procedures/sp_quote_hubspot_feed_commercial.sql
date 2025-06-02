-- =============================================================================================================================
-- Description: This procedures inserts and updates commercial quote hubspot data
------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						             |	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 06/02/25		        Yunus Mohammed				1. Created this procedure 
-- ============================================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_quote_hubspot_feed_commercial]  
 
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

		DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp0;

        --used to see if there are any changes on the broker/broker_vault
        select a.quote_no
        into edw_temp.quote_hubspot_feed_commercial_temp0
		from  [edw_integration].[quote_hubspot_feed] a
		inner join edw_commercial.tcommercial_quote q on a.quote_no = q.quote_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        left join edw_core.tbroker br on br.broker_id = q.broker_id     
		where a.broker_id <> br.broker_id		
		or isnull(a.broker_tier,'') <> isnull(br.broker_tier,'')
		or isnull(a.national_agency_in,'') <> isnull(br.national_agency_in,'')
		or isnull(a.broker_nm,'') <> isnull(br.broker_nm,'');

 		DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp01;

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
		INTO  edw_temp.quote_hubspot_feed_commercial_temp01
		FROM edw_commercial.tcommercial_daily_inforce_policy summ, edw_core.tproduct pr , edw_core.tcustomer cust 
		where inforce_dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(dd,-1,cast(getdate() as date)))
		and pr.product_sk = summ.product_sk 
		and summ.customer_sk = cust.customer_sk 
		GROUP BY ROLLUP (customer_id, pr.product_cd);
		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp1;
		
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
            null as bdm_nm,
            cust.vip_in,             
            q.quote_status,            
            h.not_taken_reason_desc as reason_quote_not_taken,            
            q.create_ts,
            q.update_ts,
            q.close_reason_desc,
            case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end 
            as monoline_in,
            br.primary_address_state_cd as broker_state,
            q.insured_nm,
            qc.retroactive_dt_desc,
            qc.prior_or_pending_dt_desc
                        

        into edw_temp.quote_hubspot_feed_commercial_temp1

        from edw_commercial.tcommercial_quote q
        left join edw_commercial.tcommercial_policy p on q.prior_term_policy_no = p.policy_no        
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        inner join edw_commercial.tcommercial_quote_history h on h.commercial_quote_sk =  q.commercial_quote_sk
        left join edw_commercial.tcommercial_quote_coverage qc on qc.commercial_quote_history_sk = h.commercial_quote_history_sk
        left join edw_core.tcustomer cust on cust.customer_id = q.customer_id
        left join edw_core.tbroker br on br.broker_id = q.broker_id        
		left join edw_temp.quote_hubspot_feed_commercial_temp01 pinf on cust.customer_id = pinf.customer_id and pr.product_cd = pinf.product_cd 
		left join edw_temp.quote_hubspot_feed_commercial_temp01 cinf on cust.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 

        where  h.latest_transaction_in = 'Y'
		and (greatest(q.create_ts,q.update_ts) > @last_source_extract_ts 
		 or exists (select 'x' from edw_temp.quote_hubspot_feed_commercial_temp0 a where a.quote_no = q.quote_no)
        )
        and q.broker_id <> '0'
        and q.effective_Dt >= '01-jun-2023'  
		and isnull(q.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%'      
		-- and q.product_cd <> 'BY'
        -- and q.forecast_quote_in = 'No'
        ;         

        --this is to pull in policies with pending non renewal = Y
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp2;
	
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
            null as bdm_nm,      
            q.policy_status, 
            cast(null as varchar) as reason_policy_not_taken, 
            q.create_ts,
            q.update_ts
            ,q.target_account
            ,'' as close_reason_desc             
            ,case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
			    end as monoline_in
            ,br.primary_address_state_cd broker_state
            ,q.insured_nm
            ,cov.retroactive_dt_desc
            ,cov.prior_or_pending_dt_desc
            ,case when cov.coverage_type = 'Excess' then tow_primary.company_nm else null end primary_carrier, 
            tow_primary.per_claim_retention_amt,
            case when cov.coverage_type = 'Excess' then tow_primary.aggregate_retention_amt else null end aggregate_retention_amt,	
			case when cov.coverage_type = 'Excess' then tow_primary.thereafter_retention_amt else null end thereafter_retention_amt,
            h.premium_amt as vault_premium_amt,
            h.commission_amt as vault_commission_amt,
            case when cov.coverage_type = 'Excess' then tower_data.company_premium_amt else null end  as total_layer_premium,
            case when cov.coverage_type = 'Excess' then tower_data.company_premium_amt else null end  as total_layer_premium_amt,
            case when tow_primary.company_nm      = 'Vault E&S Insurance Company' then tow_primary.aggregate_policy_limit_amt 	
				 when tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.tow_per_claim_policy_limit_amt 
				 when tower_data.qs_company_nm    = 'Vault E&S Insurance Company' then tower_data.qs_per_claim_policy_limit_amt
				 else null 
			end as vault_per_claim_policy_limit_amt,
        case when tow_primary.company_nm      = 'Vault E&S Insurance Company' then tow_primary.aggregate_policy_limit_amt 	
				 when tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.tow_aggregate_policy_limit_amt 
				 when tower_data.qs_company_nm    = 'Vault E&S Insurance Company' then tower_data.qs_aggregate_policy_limit_amt 
				 else null 
			end as vault_aggregate_policy_limit_amt,
        case when cov.coverage_type = 'Excess' then tower_data.tow_per_claim_policy_limit_amt 	
				 else null 
			end as total_per_claim_policy_limit_amt,
        case when cov.coverage_type = 'Excess' then tower_data.tow_aggregate_policy_limit_amt  	
				 else null 
			end as total_aggregate_policy_limit_amt,
        case when cov.coverage_type = 'Excess' and tow_primary.company_nm = 'Vault E&S Insurance Company' then tow_primary.aggregate_attachment_amt 	
				 when cov.coverage_type = 'Excess' and tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.aggregate_attachment_amt  
				 else null 
			end as total_aggregate_attachment_amt,	
			case when cov.coverage_type = 'Excess' and tow_primary.company_nm = 'Vault E&S Insurance Company' then tow_primary.per_claim_attachment_amt 	
				 when cov.coverage_type = 'Excess' and tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.per_claim_attachment_amt 
				 else null 
			end as total_per_claim_attachment_amt,
            'Commercial Lines' as quote_business_type
        into edw_temp.quote_hubspot_feed_commercial_temp2
        
        from edw_commercial.tcommercial_policy q 
		--left join edw_core.tquote q1 on q1.quote_no = q.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        inner join edw_commercial.tcommercial_policy_history h on h.commercial_policy_sk = q.commercial_policy_sk and h.latest_transaction_in = 'Y'
        left join edw_commercial.tcommercial_policy_coverage cov on h.commercial_policy_history_sk = cov.commercial_policy_history_sk

--        left join edw_core.tpolicy_insured i	on i.policy_history_sk = h.policy_history_sk and i.primary_insured_in = 'Yes'
        left join edw_core.tcustomer cust on cust.customer_id = q.customer_id
        left join edw_core.tbroker br on br.broker_id = q.broker_id    
        left join edw_temp.quote_hubspot_feed_commercial_temp01 pinf on cust.customer_id = pinf.customer_id and pr.product_cd = pinf.product_cd 
		left join edw_temp.quote_hubspot_feed_commercial_temp01 cinf on cust.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 
        left join  edw_commercial.tcommercial_policy_tower tow_primary on tow_primary.commercial_policy_history_sk = h.commercial_policy_history_sk and tow_primary.tower_type = 'primary'	
        left JOIN
        (
            select cov.policy_no, cov.effective_dt, cov.transaction_seq_no, cov.commercial_policy_coverage_sk, h.commercial_policy_history_sk,			
                cov.coverage_type, 	
                tow.tower_type, tow.company_premium_amt, 	
                tow.per_claim_retention_amt, tow.aggregate_retention_amt, tow.thereafter_retention_amt,	
                tow.per_claim_attachment_amt, tow.aggregate_attachment_amt, 	
                tow.company_nm tower_company_nm, tow.per_claim_policy_limit_amt tow_per_claim_policy_limit_amt, tow.aggregate_policy_limit_amt tow_aggregate_policy_limit_amt,	
                qs.company_nm  qs_company_nm,    qs.per_claim_policy_limit_amt  qs_per_claim_policy_limit_amt,  qs.aggregate_policy_limit_amt  qs_aggregate_policy_limit_amt	
        from edw_commercial.tcommercial_policy_history h			
        inner join edw_commercial.tcommercial_policy_coverage cov on cov.commercial_policy_history_sk = h.commercial_policy_history_sk and h.latest_transaction_in = 'Y'			
        inner join  edw_commercial.tcommercial_policy_tower tow on tow.commercial_policy_history_sk = cov.commercial_policy_history_sk			
        left join  edw_commercial.tcommercial_policy_quota_share qs on tow.commercial_policy_tower_sk = qs.commercial_policy_tower_sk			
        where (tow.company_nm = 'Vault E&S Insurance Company' or qs.company_nm = 'Vault E&S Insurance Company') 
        ) AS tower_data on tower_data.commercial_policy_history_sk = h.commercial_policy_history_sk
        where   q.broker_id <> '0'  
		and isnull(q.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%'    
		-- and pending_non_renewal_in = 'Yes'
		and q.expiration_dt between dateadd(YYYY,-1,dateadd(d,-1,cast(getdate() as date))) and dateadd(dd,90,dateadd(YYYY,-1,dateadd(d,-1,cast(getdate() as date))))
		and (isnull(non_renewal_sub_note_desc,'') like '%OTHER%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Renewal not taken%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Coverage no longer needed%' or
			 isnull(non_renewal_sub_note_desc,'') like '%Coverage placed elseware%')       
		-- and q.product_cd <> 'BY'
        and q.policy_status <> 'Cancelled'
        ;
        --and q1.quote_no is null
      
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp3;
        
        select *
        into edw_temp.quote_hubspot_feed_commercial_temp3
        FROM
        (
            select *
            from edw_temp.quote_hubspot_feed_commercial_temp1
            union ALL
            select *
            from edw_temp.quote_hubspot_feed_commercial_temp2
        ) a;
        	

        -- Start Merge process
		MERGE INTO [edw_integration].[quote_hubspot_feed] AS target
        USING [edw_temp].[quote_hubspot_feed_commercial_temp3] AS source on target.quote_no = source.quote_no
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
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(create_ts,update_ts)) FROM edw_temp.[quote_hubspot_feed_commercial_temp1]),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table 
		DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp0;
		DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp01;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp1;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp2;		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp3;
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
