-- ===============================================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates broker hubspot data
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 07/29/24		        Yunus Mohammed				1. Created this procedure
-- 08/09/24		        Archtha Gudimalla			2. Excluded test brokers
-- 08/22/24		        Archtha Gudimalla			3. Added open submission ct
-- 09/25/24		        Archtha Gudimalla			4. Added commission tier and hit ratio
-- 09/30/24		        Archtha Gudimalla			5. Updated broker summary join to left 
--                                                     (to show all brokers and not just the ones that have submission and quote)
-- 10/02/24		        Archtha Gudimalla			6. Add mailing address country
-- 10/02/24		        Archtha Gudimalla			7. Updated logic for commisson tier
-- 10/02/24		        Archtha Gudimalla			8. Excluded Yacht
-- ================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_broker_hubspot_feed]

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

		DROP TABLE IF exists edw_temp.broker_hubspot_feed_temp1;

        with br_vauk_team as
        (
        select broker_id, 
                max(case when team_member_type = 'BusinessDevelopmentManager' then team_member_nm end) [bdm], 
                max(case when program_type = 'Admitted' and team_member_type = 'Underwriter' then team_member_nm end) [VRE_Underwriter], 
                max(case when program_type = 'Non-Admitted' and team_member_type = 'Underwriter' then team_member_nm end) [VES_Underwriter]
        from edw_core.tbroker_vault_team bvt
        group by broker_id 
        ),
        br_summ as
        (
            SELECT
            broker_sk,	
            sum(round(100*one_year_non_cat_loss_incurred_amt/nullif(one_year_non_cat_earned_net_premium_amt,0),2)) as one_year_actual_non_cat_loss_ratio,
            sum(round(100*three_year_loss_incurred_amt/nullif(three_year_earned_net_premium_amt,0),2)) as two_year_ultimate_non_cat_loss_ratio,
            sum(round(100*five_year_non_cat_loss_incurred_amt/nullif(five_year_non_cat_earned_net_premium_amt,0),2)) as five_year_non_cat_loss_ratio,
            sum(ytd_bind_ct) AS ytd_bind_ct,
            sum(open_submission_ct) as open_submissions_ct,
            sum(ytd_submission_ct) as ytd_submission_ct,
            sum(last30_days_submission_ct) as last30_days_submission_ct,
            sum(policy_renewal_offered_ct) as offered_renewal_ct,
            sum(policy_renewal_offered_over_50k_ct) as offered_renewal_over50k_ct,
            sum(inforce_ct) as inforce_ct,
            sum(tbs.inforce_net_premium_amt) as inforce_premium_amt,
            sum(tbs.ytd_new_business_ct) as ytd_new_business_ct,
            sum(tbs.ytd_quote_ct) as ytd_quote_ct
            FROM
            edw_core.tbroker_summary tbs
            where
                month_sk = (select date_sk from edw_core.tdate where actual_dt =EOMONTH(GETDATE()))
            and product_sk <> 6
            group by broker_sk
        ),
        comm_tier AS
        (
            select broker_id, 
                    replace(replace(replace(replace(replace(replace(min(case when rnk = '999' then broker_tier else rnk end)
                        ,'1_Platinum','Platinum')
                        ,'2_Gold','Gold')
                        ,'3_National','National')
                        ,'4_Wholesaler','Wholesaler')
                        ,'5_A&WINS','A&WINS')
                        ,'6_Burns','Burns') as
                        c_tier
            from
            (
                select  broker_id, max(broker_tier) broker_tier, 
                        case when broker_tier like '%Platinum%' then '1_Platinum' 
                            when broker_tier like '%Gold%' then '2_Gold' 
                            when broker_tier like '%National%' then '3_National'
                            when broker_tier like '%Wholesaler%' then '4_Wholesaler' 
                            when broker_tier like '%WINS%' then '5_A&WINS' 
                            when broker_tier like '%Burns%' then '6_Burns' 
                            else '999'
                        end rnk  
                from edw_core.tbroker_commission 
                group by broker_id, 
                        case when broker_tier like '%Platinum%' then '1_Platinum' 
                            when broker_tier like '%Gold%' then '2_Gold' 
                            when broker_tier like '%National%' then '3_National'
                            when broker_tier like '%Wholesaler%' then '4_Wholesaler' 
                            when broker_tier like '%WINS%' then '5_A&WINS' 
                            when broker_tier like '%Burns%' then '6_Burns' 
                            else '999'
                        end
            ) a
            group by broker_id 
        )
        SELECT
        tb.broker_id,
        tb.broker_nm,
        tb.mailing_address_line_1,
        tb.mailing_address_line_2,
        tb.mailing_address_city_nm,
        tb.mailing_address_state_cd,
        tb.mailing_address_zip_cd, 
        tb.mailing_address_country_nm,
        tb.broker_tier,
        case
        when tb.broker_tier = 1 then 'Elite'
        when tb.broker_tier in (2,4) then 'Signature'
        When tb.broker_tier = 5 then 'Terminated'
        end as broker_tier_nm,
        tb.national_agency_in,
        tb.broker_type,
        tb.broker_status,
        tb.contract_dt,
        tb.primary_contact_nm,
        tb.broker_email,
        tb.broker_phone_no,
        bvtm.[bdm] as bdm_nm,
        null as bdm_email,
        bvtm.[VRE_Underwriter] new_business_uw_nm,
        bvtm.[VES_Underwriter] as renewal_uw_nm, 
        bs.open_submissions_ct,
        bs.one_year_actual_non_cat_loss_ratio,
        bs.two_year_ultimate_non_cat_loss_ratio,
        bs.five_year_non_cat_loss_ratio,
        bs.ytd_bind_ct,
        bs.ytd_submission_ct,
        bs.last30_days_submission_ct,
        case when bs.ytd_quote_ct = 0 then 0 else round(100*cast(bs.ytd_new_business_ct as float)/bs.ytd_quote_ct,2) end as hit_ratio,
        bs.offered_renewal_ct,
        bs.offered_renewal_over50k_ct,
        bs.inforce_ct as inforce_policy_ct,
        case when ct.c_tier in ('Platinum','Gold','National','Wholesaler','A&WINS','Burns') then ct.c_tier else null end as commission_tier, 
        bs.inforce_premium_amt,
        null as target_yoy_inforce_premium_pc,
        null as target_yoy_ytd_nb_prem_pc,
        null as target_ytd_nb_premium_pc,
        null as target_ytd_renewal_retention_pc        
        into edw_temp.broker_hubspot_feed_temp1
        FROM
        edw_core.tbroker tb
        left join br_vauk_team bvtm on bvtm.broker_id = tb.broker_id
        left join br_summ as bs    on bs.broker_sk = tb.broker_sk
        left join comm_tier as ct   on ct.broker_id = tb.broker_id
        where tb.broker_nm not like '%test%'

        truncate table edw_integration.broker_hubspot_feed       
    
        INSERT edw_integration.broker_hubspot_feed
        (
            broker_id,broker_nm,mailing_address_line_1,mailing_address_line_2,mailing_address_city_nm,mailing_address_state_nm,
            mailing_address_zip_cd,broker_tier,broker_tier_nm,national_agency_in,broker_type,broker_status,contract_dt,primary_contact_nm,
            broker_email,broker_phone_no,bdm_nm,bdm_email,new_business_uw_nm,renewal_uw_nm,open_submissions_ct,one_year_actual_non_cat_loss_ratio,
            two_year_ultimate_non_cat_loss_ratio,five_year_non_cat_loss_ratio,ytd_bind_ct,ytd_submission_ct,last30_days_submission_ct,hit_ratio,
            offered_renewal_ct,offered_renewal_over50k_ct,inforce_policy_ct,commission_tier,inforce_premium_amt,target_yoy_inforce_premium_pc,
            target_yoy_ytd_nb_prem_pc,target_ytd_nb_premium_pc,target_ytd_renewal_retention_pc,
            create_ts,update_ts,etl_audit_sk
            ,mailing_address_country_nm

        )
        SELECT        
            broker_id,broker_nm,mailing_address_line_1,mailing_address_line_2,mailing_address_city_nm,mailing_address_state_cd,
            mailing_address_zip_cd,broker_tier,broker_tier_nm,national_agency_in,broker_type,broker_status,contract_dt,primary_contact_nm,
            broker_email,broker_phone_no,bdm_nm,bdm_email,new_business_uw_nm,renewal_uw_nm,open_submissions_ct,one_year_actual_non_cat_loss_ratio,
            two_year_ultimate_non_cat_loss_ratio,five_year_non_cat_loss_ratio,ytd_bind_ct,ytd_submission_ct,last30_days_submission_ct,hit_ratio,
            offered_renewal_ct,offered_renewal_over50k_ct,inforce_policy_ct,commission_tier,inforce_premium_amt,target_yoy_inforce_premium_pc,
            target_yoy_ytd_nb_prem_pc,target_ytd_nb_premium_pc,target_ytd_renewal_retention_pc,
            getdate(), getdate(), @etl_audit_sk 
            ,mailing_address_country_nm
        FROM edw_temp.broker_hubspot_feed_temp1
        
        
        SET @rows_affected=@@ROWCOUNT;
        -- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.broker_hubspot_feed_temp1
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