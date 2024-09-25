select top 100 * from edw_core.tetl_audit where process_nm like 'sp_policy_redzone_feed' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm = 'sp_policy_redzone_feed';
select * from [edw_integration].[policy_redzone_feed];
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_policy_redzone_feed';
-- truncate table [edw_integration].[policy_redzone_feed];
-- EXEC [edw_core].[sp_policy_redzone_feed];



SELECT * FROM [edw_temp].[policy_redzone_feed_temp0] WHERE policy_no = 'HO200029590';

SELECT *
FROM edw_core.titem_inforce AS summ	
INNER JOIN edw_core.tdate AS td ON td.date_sk = summ.month_sk
;

SELECT	 summ.policy_sk,
    '' as unique_id, 
    pol.policy_no, 
    pr.product_nm, 		
    loc.[latitude], 
    loc.[longitude], 
    trim(trim(loc.[address_line_1] || ' ' || isnull(loc.[address_line_2],'')) || ' ' || isnull(loc.[unit_no],'')) as address_line,
    loc.[city_nm], 
    loc.[county_nm], 
    loc.[state_cd], 
    loc.[zip_cd],
    -- cov.[total_insured_value_amt],
    -- SUM(ISNULL(cov.[total_insured_value_amt],0)) as total_insured_value_amt,
    -- SUM(CAST(cov.[total_insured_value_amt] AS bigint)) as total_insured_value_amt,
    ins.insured_nm, 
    isnull(ins.mobile_phone_no, ins.home_phone_no) as ins_ph_no, 
    ins.email as ins_email,
    br.[broker_id], 
    br.[broker_nm], 
    br.[broker_phone_no], 
    br.[broker_email],
    -- SUM(cov.[dwelling_limit_amt]) as dwelling_limit_amt, 
    -- SUM(cov.[other_structures_limit_amt]) as other_structures_limit_amt, 
    -- SUM(cov.[contents_limit_amt]) as contents_limit_amt, 
    -- SUM(round(
    --     case 
    --         when cov.[dwelling_limit_amt]> 0 then cov.[dwelling_limit_amt]*cov.loss_of_use_derived_pc
    --         else cov.[contents_limit_amt]*cov.loss_of_use_derived_pc 
    --     end
    --     ,0)) as cov_d,
    '' as gate_code
    -- @current_date AS create_ts,
    -- @current_date AS update_ts,
    -- @etl_audit_sk AS etl_audit_sk,
    -- MAX(td.actual_dt) AS filter_dt
-- INTO [edw_temp].[policy_redzone_feed_temp0]
FROM edw_core.titem_inforce AS summ	
INNER JOIN edw_core.tdate AS td ON td.date_sk = summ.month_sk		
INNER JOIN edw_core.thome_coverage AS cov ON summ.coverage_sk = cov.home_coverage_sk		
INNER JOIN edw_core.thome_location AS loc ON summ.item_sk = loc.home_location_sk		
INNER JOIN edw_core.tpolicy AS pol ON summ.policy_sk = pol.policy_sk		
INNER JOIN edw_core.tproduct AS pr ON summ.product_sk = pr.product_sk		
INNER JOIN edw_core.tbroker AS br ON summ.broker_sk = br.broker_sk		
LEFT JOIN edw_core.tpolicy_insured AS ins ON summ.policy_history_sk = ins.policy_history_sk AND ins.primary_insured_in = 'Yes'		
WHERE pr.product_cd = 'HO'
AND pol.policy_no = 'HO200029590'
AND ISNUMERIC(cov.[total_insured_value_amt]) <> 0

;

SELECT * FROM edw_core.tpolicy;
SELECT policy_no, policy_history_sk, transaction_seq_no FROM edw_core.tpolicy_insured WHERE policy_no = 'HO200029590';
SELECT * FROM edw_core.titem_inforce WHERE policy_sk = '30705';


WITH tbl AS (
    SELECT 
        pol.policy_no, 
        pr.product_nm, 		
        loc.[latitude], 
        loc.[longitude], 
        trim(trim(loc.[address_line_1] || ' ' || isnull(loc.[address_line_2],'')) || ' ' || isnull(loc.[unit_no],'')) as address_line,
        loc.[city_nm], 
        loc.[county_nm], 
        loc.[state_cd], 
        loc.[zip_cd],
        CAST(cov.[total_insured_value_amt] AS BIGINT) as total_insured_value_amt,
        ins.insured_nm, 
        isnull(ins.mobile_phone_no, ins.home_phone_no) as ins_ph_no, 
        ins.email as ins_email,
        br.[broker_id], 
        br.[broker_nm], 
        br.[broker_phone_no], 
        br.[broker_email],
        CAST(cov.[dwelling_limit_amt] AS BIGINT) as dwelling_limit_amt, 
        CAST(cov.[other_structures_limit_amt] AS BIGINT) as other_structures_limit_amt, 
        CAST(cov.[contents_limit_amt] AS BIGINT) as contents_limit_amt, 
        CAST(round(
            case 
                when cov.[dwelling_limit_amt]> 0 then cov.[dwelling_limit_amt]*cov.loss_of_use_derived_pc
                else cov.[contents_limit_amt]*cov.loss_of_use_derived_pc 
            end
            ,0) AS BIGINT) as cov_d,
        '' as gate_code
    FROM edw_core.titem_inforce AS summ	
    INNER JOIN edw_core.tdate AS td ON td.date_sk = summ.month_sk		
    INNER JOIN edw_core.thome_coverage AS cov ON summ.coverage_sk = cov.home_coverage_sk		
    INNER JOIN edw_core.thome_location AS loc ON summ.item_sk = loc.home_location_sk		
    INNER JOIN edw_core.tpolicy AS pol ON summ.policy_sk = pol.policy_sk		
    INNER JOIN edw_core.tproduct AS pr ON summ.product_sk = pr.product_sk		
    INNER JOIN edw_core.tbroker AS br ON summ.broker_sk = br.broker_sk		
    LEFT JOIN edw_core.tpolicy_insured AS ins ON summ.policy_history_sk = ins.policy_history_sk AND ins.primary_insured_in = 'Yes'		
    WHERE pr.product_cd = 'HO'
    AND td.yearmonth = (select max(yearmonth) from edw_core.tdate where actual_dt < cast(getdate() as date))
)
SELECT * FROM tbl
;