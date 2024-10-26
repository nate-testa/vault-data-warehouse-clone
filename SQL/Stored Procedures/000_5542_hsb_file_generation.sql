-- /*
select top 100 * from edw_core.tetl_audit where process_nm like '%policy_hsb_%' order by etl_audit_sk desc;
select MAX(reporting_date) AS reporting_date from [edw_integration].[policy_hsb_cyber_feed];
select reporting_date, create_ts, etl_audit_sk, count(1) from [edw_integration].[policy_hsb_cyber_feed] group by reporting_date, etl_audit_sk, create_ts order by reporting_date;
select * from edw_core.tetl_control where process_nm like '%policy_hsb_%';--2020-01-01 00:00:00.0000000
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_policy_hsb_cyber_feed';
-- truncate table [edw_integration].[policy_hsb_cyber_feed];
-- EXEC [edw_core].[sp_policy_hsb_cyber_feed];

SELECT * FROM [edw_temp].[policy_hsb_cyber_feed_temp1];


--*********************************************************************************************************************
--*********************************************************************************************************************
--*********************************************************************************************************************
SELECT count(1) as rc FROM [edw_integration].[policy_hsb_cyber_feed] ;
SELECT count(1) as rc FROM [edw_integration].[policy_hsb_hsp_feed]   ;
SELECT count(1) as rc FROM [edw_integration].[policy_hsb_slc_feed]   ;

--check duplicate rows
SELECT policy_no, count(1) as rc FROM [edw_integration].[policy_hsb_cyber_feed] group by policy_no having count(1) > 1;
SELECT policy_no, count(1) as rc FROM [edw_integration].[policy_hsb_hsp_feed]   group by policy_no having count(1) > 1;
SELECT policy_no, count(1) as rc FROM [edw_integration].[policy_hsb_slc_feed]   group by policy_no having count(1) > 1;

--negative premiums
select * from [edw_integration].[policy_hsb_cyber_feed] where hcp_net_premium_amt like '%-%';
select * from [edw_integration].[policy_hsb_hsp_feed]   where hsp_net_premium_amt like '%-%';
select * from [edw_integration].[policy_hsb_slc_feed]   where slc_net_premium_amt like '%-%';
-- delete from [edw_integration].[policy_hsb_cyber_feed] where hcp_net_premium_amt like '%-%';
-- delete from [edw_integration].[policy_hsb_hsp_feed]   where hsp_net_premium_amt like '%-%';
-- delete from [edw_integration].[policy_hsb_slc_feed]   where slc_net_premium_amt like '%-%';


--doesn't have deductible ammount
select hcp_deductible_amt, * from [edw_integration].[policy_hsb_cyber_feed] where hcp_deductible_amt in ('',0,null);
select hsp_deductible_amt, * from [edw_integration].[policy_hsb_hsp_feed]   where hsp_deductible_amt in ('',0,null);
select slc_deductible_amt, * from [edw_integration].[policy_hsb_slc_feed]   where slc_deductible_amt in ('',0,null);



SELECT * 
FROM edw_core.tpolicy 
WHERE policy_status = 'Active' 
AND policy_no like 'HO100258458%'
AND product_cd in ('HO','CO')
AND effective_dt <= GETDATE()
AND expiration_dt >= GETDATE()
;

select 
    policy_no, effective_dt, transaction_seq_no, home_systems_protection_limit_amt, home_cyber_protection_coverage_deductible, home_cyber_protection_coverage_limit_amt,
    ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY transaction_seq_no DESC) AS RN
from edw_core.thome_additional_coverage
where policy_no = 'HO100258458-01'
;

--no have decimals and should it.
select * from [edw_integration].[policy_hsb_cyber_feed] where hcp_net_premium_amt not like '%.%';
select * from [edw_integration].[policy_hsb_hsp_feed]   where hsp_net_premium_amt not like '%.%';
select * from [edw_integration].[policy_hsb_slc_feed]   where slc_net_premium_amt not like '%.%';

--have decimals and should not have it.
select * from [edw_integration].[policy_hsb_cyber_feed] where hcp_limit_amt like '%.%' or hcp_deductible_amt like '%.%' or base_homeowner_premium like '%.%' or final_homeowner_premium like '%.%' or policy_deductible like '%.%' or coverage_a_value like '%.%';
select hsp_limit_amt, hsp_deductible_amt, base_homeowner_premium, final_homeowner_premium , policy_deductible , coverage_a_value , coverage_b_value , coverage_c_value, * from [edw_integration].[policy_hsb_hsp_feed]   where hsp_limit_amt like '%.%' or hsp_deductible_amt like '%.%' or base_homeowner_premium like '%.%' or final_homeowner_premium like '%.%' or policy_deductible like '%.%' or coverage_a_value like '%.%' or coverage_b_value like '%.%' or coverage_c_value like '%.%';
select slc_limit_amt, slc_deductible_amt, base_homeowner_premium, final_homeowner_premium , policy_deductible , coverage_a_value , coverage_b_value , coverage_c_value, * from [edw_integration].[policy_hsb_slc_feed]   where slc_limit_amt <> '50000' or slc_deductible_amt <> '500' or base_homeowner_premium like '%.%' or final_homeowner_premium like '%.%' or policy_deductible like '%.%' or coverage_a_value like '%.%' or coverage_b_value like '%.%' or coverage_c_value like '%.%';

-- delete from [edw_integration].[policy_hsb_cyber_feed] where hcp_deductible_amt like '%.%' or coverage_a_value like '%.%' or slc_limit_amt like '%.%' or final_homeowner_premium like '%.%' or base_homeowner_premium like '%.%' or policy_deductible like '%.%';
-- delete from [edw_integration].[policy_hsb_hsp_feed]   where hsp_limit_amt like '%.%' or hsp_deductible_amt like '%.%' or base_homeowner_premium like '%.%' or final_homeowner_premium like '%.%' or policy_deductible like '%.%' or coverage_a_value like '%.%' or coverage_b_value like '%.%' or coverage_c_value like '%.%';
-- delete from [edw_integration].[policy_hsb_slc_feed]   where slc_limit_amt <> '50000' or slc_deductible_amt <> '500' or base_homeowner_premium like '%.%' or final_homeowner_premium like '%.%' or policy_deductible like '%.%' or coverage_a_value like '%.%' or coverage_b_value like '%.%' or coverage_c_value like '%.%';

--policy_deductible is null
select * from [edw_integration].[policy_hsb_cyber_feed] where policy_deductible is null;
select * from [edw_integration].[policy_hsb_hsp_feed]   where policy_deductible is null;
select * from [edw_integration].[policy_hsb_slc_feed]   where policy_deductible is null;

-- delete from [edw_integration].[policy_hsb_cyber_feed] where policy_deductible is null;
-- delete from [edw_integration].[policy_hsb_hsp_feed]   where policy_deductible is null;
-- delete from [edw_integration].[policy_hsb_slc_feed]   where policy_deductible is null;


--*********************************************************************************************************************
--*********************************************************************************************************************
--*********************************************************************************************************************





--*********************************************************************************************************************
--*******LOAD DATA*****************************************************************************************************
--*********************************************************************************************************************
update edw_core.tetl_control set last_source_extract_ts = '2020-01-01 00:00:00' where process_nm in ('sp_policy_hsb_cyber_feed','sp_policy_hsb_hsp_feed','sp_policy_hsb_slc_feed');
select edw_core.fn_get_last_source_extract_ts('sp_policy_hsb_cyber_feed');

select count(1) from [edw_integration].[policy_hsb_cyber_feed]
union all
select count(1) from [edw_integration].[policy_hsb_hsp_feed]
union all
select count(1) from [edw_integration].[policy_hsb_slc_feed]
;

truncate table [edw_integration].[policy_hsb_cyber_feed];
truncate table [edw_integration].[policy_hsb_hsp_feed];
truncate table [edw_integration].[policy_hsb_slc_feed];

EXEC [edw_core].[sp_policy_hsb_cyber_feed];
EXEC [edw_core].[sp_policy_hsb_hsp_feed];
EXEC [edw_core].[sp_policy_hsb_slc_feed];


select hcp_deductible_amt, count(1) 
from [edw_integration].[policy_hsb_cyber_feed]
-- where hcp_deductible_amt in ('0','') or hcp_deductible_amt IS NULL
group by hcp_deductible_amt
;

-- select hcp_net_premium_amt, coverage_a_value from [edw_integration].[policy_hsb_cyber_feed] where not (hcp_net_premium_amt <= 0 or coverage_a_value IS NULL or coverage_a_value = 0);
--filter out
select count(1) from [edw_integration].[policy_hsb_cyber_feed] where not (hcp_net_premium_amt <= 0 or coverage_a_value IS NULL or coverage_a_value = 0) 
union all
select count(1) from [edw_integration].[policy_hsb_hsp_feed] where not (hsp_net_premium_amt <= 0 or coverage_a_value IS NULL or coverage_b_value IS NULL or coverage_a_value = 0 or coverage_b_value = 0 or original_homeowner_policy_effective_dt IS NULL)
union all
select count(1) from [edw_integration].[policy_hsb_slc_feed] where not (slc_net_premium_amt <= 0 or coverage_a_value IS NULL or coverage_b_value IS NULL or coverage_a_value = 0 or coverage_b_value = 0)
;


SELECT distinct hcp_deductible_amt, count(*)  FROM vault_edw.edw_integration.policy_hsb_cyber_feed WHERE hcp_deductible_amt not in ('0','') AND hcp_deductible_amt IS NOT NULL
group by hcp_deductible_amt
;


-- update [edw_integration].[policy_hsb_hsp_feed] set [no_of_units_in_dwelling] = '' where [no_of_units_in_dwelling] = '0' OR [no_of_units_in_dwelling] IS NULL;
-- update [edw_integration].[policy_hsb_hsp_feed] set [distance_to_hydrant] = '' where [distance_to_hydrant] = '0' OR [distance_to_hydrant] IS NULL;
-- update [edw_integration].[policy_hsb_hsp_feed] set [insurance_score] = '' where [insurance_score] = '0' OR [insurance_score] IS NULL;
-- update [edw_integration].[policy_hsb_hsp_feed] set [agent_code] = '' where [agent_code] = '0' OR [agent_code] IS NULL;

select distinct distance_to_hydrant from [edw_integration].[policy_hsb_hsp_feed];


select top 10 * from [edw_integration].[policy_hsb_hsp_feed];
where coverage_a_value = 0 
or coverage_a_value is null
;
select * from [edw_integration].[policy_hsb_hsp_feed]

select * from [edw_temp].[hsb_log_tmp];

-- truncate table [edw_temp].[hsb_log_tmp];


--*********************************************************************************************************************
--*********************************************************************************************************************
--*********************************************************************************************************************
