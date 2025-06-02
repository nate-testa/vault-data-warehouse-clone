-- ===============================================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts and updates commercial broker hubspot data
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						            |	Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 05/30/25		         Yunus Mohammed				1. Created this procedure
-- ================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_broker_hubspot_feed_commercial]

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

        declare @ret_start_mn int;
        declare @ret_end_mn	int;
        declare @var_end_mn	int;

        set @ret_start_mn = (select min(yearmonth) from edw_core.tdate where actual_dt = dateadd("yyyy",-1, EOMONTH(				getdate())));
        set @ret_end_mn   = (select min(yearmonth) from edw_core.tdate where actual_dt = dateadd(  "mm",-1, EOMONTH(				getdate())));
        set @var_end_mn   = (select min(yearmonth) from edw_core.tdate where actual_dt = EOMONTH( dateadd("d",-1,getdate())));

		DROP TABLE IF exists edw_temp.broker_hubspot_feed_commercial_temp1;
          
        with br_summ as
        (
            SELECT
                broker_sk,               
                --
                sum(case when td.yearmonth = @var_end_mn then tbs.ytd_bind_ct else 0 end) as ytd_bind_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.open_submission_ct else 0 end) as open_submissions_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.ytd_submission_ct else 0 end) as ytd_submission_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.last30_days_submission_ct else 0 end) as last30_days_submission_ct,
                --
                
                sum(case when td.yearmonth = @var_end_mn then tbs.policy_renewal_offered_ct			else 0 end) as offered_renewal_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.policy_renewal_offered_over_50k_ct else 0 end) as offered_renewal_over50k_ct,
                --
                sum(case when td.yearmonth = @var_end_mn then tbs.inforce_ct							else 0 end) as inforce_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.inforce_premium_amt				else 0 end) as inforce_premium_amt,
                sum(case when td.yearmonth = @var_end_mn then tbs.ytd_new_business_ct					else 0 end) as ytd_new_business_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.ytd_quote_ct							else 0 end) as ytd_quote_ct,
                sum(case when td.yearmonth = @var_end_mn then tbs.ytd_new_business_premium_amt		else 0 end) as ytd_new_business_premium_amt,                
                --
                sum(case when td.yearmonth between @ret_start_mn and @ret_end_mn and tbs.policy_renewal_accepted_ct is not null then tbs.policy_renewal_accepted_ct else 0 end) rolling_12_policy_renewal_accepted_ct,
                sum(case when td.yearmonth between @ret_start_mn and @ret_end_mn and tbs.policy_renewal_ct  is not null then tbs.policy_renewal_ct else 0 end) rolling_12_policy_renewal_ct
                --
                
                --
            FROM edw_commercial.tcommercial_broker_summary tbs
			inner join edw_core.tdate td on td.date_sk = tbs.month_sk
            where td.yearmonth >= @ret_start_mn
			and td.yearmonth <= @var_end_mn            
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
            'Commercial Lines' as broker_business_type,
            null as bdm_nm,
            null as bdm_email,
            null as new_business_uw_nm,
            null as renewal_uw_nm, 
            bs.open_submissions_ct,            
            bs.ytd_bind_ct,
            bs.ytd_submission_ct,
            bs.last30_days_submission_ct,
            case when bs.ytd_quote_ct = 0 then 0 else round(100*cast(bs.ytd_new_business_ct as float)/bs.ytd_quote_ct,2) end as hit_ratio,
            bs.offered_renewal_ct,
            bs.offered_renewal_over50k_ct,
            bs.inforce_ct as inforce_policy_ct,
            case when ct.c_tier in ('Platinum','Gold','National','Wholesaler','A&WINS','Burns') then ct.c_tier else null end as commission_tier, 
            bs.inforce_premium_amt,            
            null as target_yoy_ytd_nb_prem_pc,            
            null as target_ytd_renewal_retention_pc
            ,bs.ytd_new_business_premium_amt as ytd_nb_premium_amt            
            ,case when rolling_12_policy_renewal_ct > 0 then round(100*cast(rolling_12_policy_renewal_accepted_ct as float)/rolling_12_policy_renewal_ct,2) else null end ytd_renewal_retention_pc
            ,tb.primary_address_state_cd
            ,case when ytd_bind_ct = 0 then null else ytd_quote_ct/ytd_bind_ct end as quote_to_bind_ratio
	        ,case when ytd_quote_ct = 0 then null else ytd_submission_ct/ytd_quote_ct end as submission_to_quote_ratio
        into    edw_temp.broker_hubspot_feed_commercial_temp1
        FROM    edw_core.tbroker tb
        -- left join br_vauk_team bvtm on bvtm.broker_id = tb.broker_id
        left join br_summ as bs    on bs.broker_sk = tb.broker_sk
        left join comm_tier as ct   on ct.broker_id = tb.broker_id
        where   isnull(tb.broker_nm,'') not like '%test%'
        and (tb.broker_id like '1%' and len(tb.broker_id) = 5)		
    
        INSERT edw_integration.broker_hubspot_feed
        (
            broker_id,broker_nm,mailing_address_line_1,mailing_address_line_2,mailing_address_city_nm,mailing_address_state_nm,
            mailing_address_zip_cd,mailing_address_country_nm, 
            broker_tier,broker_tier_nm,national_agency_in,broker_type,broker_status,contract_dt,primary_contact_nm,
            broker_email,broker_phone_no,bdm_nm,bdm_email,new_business_uw_nm,renewal_uw_nm,open_submissions_ct,
            ytd_bind_ct,ytd_submission_ct,last30_days_submission_ct,hit_ratio,
            offered_renewal_ct,offered_renewal_over50k_ct,inforce_policy_ct,commission_tier,inforce_premium_amt
            --,target_yoy_ytd_nb_prem_pc,target_ytd_renewal_retention_pc            
            ,ytd_nb_premium_amt            
            ,ytd_renewal_retention_pc
            ,primary_address_state_cd,broker_business_type
            ,quote_to_bind_ratio,submission_to_quote_ratio
            ,create_ts,update_ts,etl_audit_sk
        )
        SELECT
            broker_id,broker_nm + ' - ' + broker_id,mailing_address_line_1,mailing_address_line_2,mailing_address_city_nm,mailing_address_state_cd,
            mailing_address_zip_cd,mailing_address_country_nm
            ,broker_tier,broker_tier_nm,national_agency_in,broker_type,broker_status,contract_dt,primary_contact_nm,
            broker_email,broker_phone_no,bdm_nm,bdm_email,new_business_uw_nm,renewal_uw_nm,open_submissions_ct,
            ytd_bind_ct,ytd_submission_ct,last30_days_submission_ct,hit_ratio,
            offered_renewal_ct,offered_renewal_over50k_ct,inforce_policy_ct,commission_tier,inforce_premium_amt
            --,target_yoy_ytd_nb_prem_pc,target_ytd_renewal_retention_pc
            ,ytd_nb_premium_amt            
            ,ytd_renewal_retention_pc
            ,primary_address_state_cd,broker_business_type
            ,quote_to_bind_ratio,submission_to_quote_ratio
            ,getdate(), getdate(), @etl_audit_sk
        FROM edw_temp.broker_hubspot_feed_commercial_temp1
        
        
        SET @rows_affected=@@ROWCOUNT;
        -- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.broker_hubspot_feed_commercial_temp1
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