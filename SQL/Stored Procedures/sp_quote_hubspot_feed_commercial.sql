-- =============================================================================================================================
-- Description: This procedures inserts and updates commercial quote hubspot data
------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						             |	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 06/02/25		        Yunus Mohammed				1. Created this procedure 
-- 06/09/25		        Architha Gudimalla			2. Updated after intial run to fix errors
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
		
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp1;

        with quote_tower_data as
        (
            select  cov.quote_no, cov.effective_dt, cov.transaction_seq_no, cov.commercial_quote_coverage_sk, h.commercial_quote_history_sk,
				rank() over (partition by  cov.quote_no, cov.effective_dt order by tow.commercial_quote_tower_sk, qs.commercial_quote_quota_share_sk) rnk,			
                cov.coverage_type,
                tow.tower_type, tow.company_premium_amt, 	
                tow.per_claim_retention_amt, tow.aggregate_retention_amt,tow.thereafter_retention_amt,	
                tow.per_claim_attachment_amt, tow.aggregate_attachment_amt, 	
                tow.company_nm tower_company_nm, tow.per_claim_policy_limit_amt tow_per_claim_policy_limit_amt, tow.aggregate_policy_limit_amt tow_aggregate_policy_limit_amt,	
                case when tow.company_nm = 'Vault E&S Insurance Company' then  null else qs.commercial_quote_quota_share_sk end commercial_quote_quota_share_sk,  
				case when tow.company_nm = 'Vault E&S Insurance Company' then  null else qs.company_nm end qs_company_nm,  
				case when tow.company_nm = 'Vault E&S Insurance Company' then  null else qs.per_claim_policy_limit_amt end qs_per_claim_policy_limit_amt,  
				case when tow.company_nm = 'Vault E&S Insurance Company' then  null else  qs.aggregate_policy_limit_amt end qs_aggregate_policy_limit_amt
        from edw_commercial.tcommercial_quote_history h			
        inner join edw_commercial.tcommercial_quote_coverage cov on cov.commercial_quote_history_sk = h.commercial_quote_history_sk and h.latest_transaction_in = 'Y'			
        inner join edw_commercial.tcommercial_quote_tower tow on tow.commercial_quote_history_sk = cov.commercial_quote_history_sk			
        left join edw_commercial.tcommercial_quote_quota_share qs on tow.commercial_quote_tower_sk = qs.commercial_quote_tower_sk			
        where (tow.company_nm = 'Vault E&S Insurance Company' or qs.company_nm = 'Vault E&S Insurance Company') 
        ) 

        select
            q.quote_no,q.effective_dt,q.expiration_dt,h.transaction_type,h.producer_nm,
            q.customer_id,
            br.broker_id, br.broker_nm, br.broker_tier, br.national_agency_in,
            cust.vip_in,
            q.quote_status,         
            h.not_taken_reason_desc as reason_quote_not_taken,            
            q.create_ts,
            q.update_ts,
            q.close_reason_desc,
            null as monoline_in,
            br.primary_address_state_cd as broker_state,
            q.insured_nm,
            cov.retroactive_dt_desc,
            cov.prior_or_pending_dt_desc,
			case when cov.coverage_type = 'Excess' then tow_primary.company_nm else null end primary_carrier_nm,
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
			case when tow_primary.company_nm  = 'Vault E&S Insurance Company' then tow_primary.aggregate_policy_limit_amt 	
					 when tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.tow_aggregate_policy_limit_amt 
					 when tower_data.qs_company_nm    = 'Vault E&S Insurance Company' then tower_data.qs_aggregate_policy_limit_amt 
					 else null 
				end as vault_aggregate_policy_limit_amt,
			case when cov.coverage_type = 'Excess' then tower_data.tow_per_claim_policy_limit_amt 	
					 else null 
				end as total_layer_per_claim_policy_limit_amt,
			case when cov.coverage_type = 'Excess' then tower_data.tow_aggregate_policy_limit_amt  	
					 else null 
				end as total_layer_aggregate_policy_limit_amt,
			case when cov.coverage_type = 'Excess' and tow_primary.company_nm = 'Vault E&S Insurance Company' then tow_primary.aggregate_attachment_amt 	
					 when cov.coverage_type = 'Excess' and tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.aggregate_attachment_amt  
					 else null 
				end as total_aggregate_attachment_amt,	
			case when cov.coverage_type = 'Excess' and tow_primary.company_nm = 'Vault E&S Insurance Company' then tow_primary.per_claim_attachment_amt 	
					when cov.coverage_type = 'Excess' and tower_data.tower_company_nm = 'Vault E&S Insurance Company' then tower_data.per_claim_attachment_amt 
					else null 
			end as total_per_claim_attachment_amt,
            'Commercial Lines' as quote_business_type
        into edw_temp.quote_hubspot_feed_commercial_temp1

        from edw_commercial.tcommercial_quote q
        left join edw_commercial.tcommercial_policy p on q.prior_term_policy_no = p.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        inner join edw_commercial.tcommercial_quote_history h on h.commercial_quote_sk =  q.commercial_quote_sk
        left join edw_commercial.tcommercial_quote_coverage cov on cov.commercial_quote_history_sk = h.commercial_quote_history_sk
        left join edw_core.tcustomer cust on cust.customer_id = q.customer_id
        left join edw_core.tbroker br on br.broker_id = q.broker_id 
		left join edw_commercial.tcommercial_quote_tower tow_primary on tow_primary.commercial_quote_history_sk = h.commercial_quote_history_sk 
			and tow_primary.tower_type = 'primary'
		left join quote_tower_data AS tower_data on tower_data.rnk =1 and tower_data.commercial_quote_history_sk = h.commercial_quote_history_sk
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
      
        DROP TABLE IF exists edw_temp.quote_hubspot_feed_commercial_temp3;
        
        select *
        into edw_temp.quote_hubspot_feed_commercial_temp3
        FROM
        (
            select *
            from edw_temp.quote_hubspot_feed_commercial_temp1 
        ) a;
        	

        -- Start Merge process
		MERGE INTO [edw_integration].[quote_hubspot_feed] AS target
        USING [edw_temp].[quote_hubspot_feed_commercial_temp3] AS source on target.quote_no = source.quote_no
        WHEN NOT MATCHED BY Target THEN
        INSERT
        (
            quote_no , effective_dt ,expiration_dt , transaction_type , broker_id , broker_nm ,broker_tier ,national_agency_in,  
            vip_in, quote_status , reason_quote_not_taken, producer_nm,
            create_ts, update_ts ,etl_audit_sk
            ,customer_id,close_reason_desc,monoline_in,broker_state,
            insured_nm,retroactive_dt_desc,prior_or_pending_dt_desc,primary_carrier_nm,
            per_claim_retention_amt,aggregate_retention_amt,thereafter_retention,vault_premium_amt,
            vault_commission_amt,total_layer_premium_amt,vault_per_claim_policy_limit_amt,vault_aggregate_policy_limit_amt,
            total_layer_per_claim_policy_limit_amt,total_layer_aggregate_policy_limit_amt,total_aggregate_attachment_amt,
            total_per_claim_attachment_amt,quote_business_type
        )
        VALUES
        (
         quote_no , effective_dt ,expiration_dt , transaction_type , broker_id , broker_nm ,broker_tier ,national_agency_in,  
            vip_in, quote_status ,reason_quote_not_taken, producer_nm,
            getdate(), getdate(), @etl_audit_sk 
            ,customer_id,close_reason_desc,monoline_in,broker_state,
            insured_nm,retroactive_dt_desc,prior_or_pending_dt_desc,primary_carrier_nm,
            per_claim_retention_amt,aggregate_retention_amt,thereafter_retention_amt,vault_premium_amt,
            vault_commission_amt,total_layer_premium_amt,vault_per_claim_policy_limit_amt,vault_aggregate_policy_limit_amt,
            total_layer_per_claim_policy_limit_amt,total_layer_aggregate_policy_limit_amt,total_aggregate_attachment_amt,
            total_per_claim_attachment_amt,quote_business_type
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
            [target].vip_in	=	[source].vip_in,          
            [target].quote_status	=	[source].quote_status,
            [target].reason_quote_not_taken	=	[source].reason_quote_not_taken,            
            [target].producer_nm =   [source].producer_nm,
            [target].update_ts	=	GETDATE(),
            [target].etl_audit_sk	=	@etl_audit_sk,
            [target].customer_id	=	[source].customer_id,
            [target].close_reason_desc	                =	[source].close_reason_desc ,  
            [target].monoline_in	                    =	[source].monoline_in ,  
            [target].broker_state	                    =	[source].broker_state ,
           [target]. insured_nm = [target]. insured_nm,
           [target].retroactive_dt_desc = [source].retroactive_dt_desc,
           [target].prior_or_pending_dt_desc = [source].prior_or_pending_dt_desc,
           [target].primary_carrier_nm = [source].primary_carrier_nm,
            [target].per_claim_retention_amt= [source].per_claim_retention_amt,
            [target].aggregate_retention_amt= [source].aggregate_retention_amt,
            [target].thereafter_retention= [source].thereafter_retention_amt,
            [target].vault_premium_amt = [source].vault_premium_amt,
            [target].vault_commission_amt = [source].vault_commission_amt,
            [target].total_layer_premium_amt = [source].total_layer_premium_amt,
            [target].vault_per_claim_policy_limit_amt= [source].vault_per_claim_policy_limit_amt,
            [target].vault_aggregate_policy_limit_amt= [source].vault_aggregate_policy_limit_amt,
            [target].total_layer_per_claim_policy_limit_amt=[source]. total_layer_per_claim_policy_limit_amt,
            [target].total_layer_aggregate_policy_limit_amt= [source].total_layer_aggregate_policy_limit_amt,
            [target].total_aggregate_attachment_amt= [source].total_aggregate_attachment_amt,
            [target].total_per_claim_attachment_amt= [source].total_per_claim_attachment_amt,
            [target].quote_business_type= [source].quote_business_type
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
