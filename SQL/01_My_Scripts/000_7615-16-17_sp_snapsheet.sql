select top 100 * from edw_core.tetl_audit where process_nm LIKE '%snapsheet%' order by etl_audit_sk desc;
select top 100 * from edw_core.tetl_control where process_nm in ('sp_tclaim_snapsheet');
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' 
where process_nm in 
('sp_tclaim_transaction_snapsheet')
-- ('sp_tclaim_feature_snapsheet','sp_tclaim_payment_snapsheet','sp_tclaim_transaction_snapsheet')
-- ('sp_tclaim_snapsheet',
-- 'sp_tclaim_feature_snapsheet',
-- 'sp_tclaim_payment_snapsheet',
-- 'sp_tclaim_transaction_snapsheet',
-- 'sp_update_tclaim_snapsheet',
-- 'sp_update_tclaim_feature_snapsheet',
-- 'sp_tclaim_note_snapsheet',
-- 'sp_tclaim_task_snapsheet')
;
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tclaim_payment_snapsheet');
exec sp_help 'edw_core.tclaim_transaction';

select * from edw_stage_snapsheet.custom_field_claims_enumeration_values where option_name like '%,%';
-- update edw_stage_snapsheet.custom_field_claims_enumeration_values set option_name = REPLACE(option_name,',','|') where option_name like '%,%';

select * from edw_temp.tclaim_snapsheet_temp1;
select claim_no, count(1) from edw_temp.tclaim_snapsheet_temp1 group by claim_no having COUNT(1) > 1;
select COUNT(1) as ct from edw_core.tclaim where source_system_sk = 5;

select * from edw_core.tclaim a
inner join edw_temp.tclaim_snapsheet_temp1 b
ON a.claim_no=b.claim_no
;

-- delete edw_core.tcause_of_loss where source_system_sk = 5;
-- delete edw_core.tclaim_payment where source_system_sk = 5;
-- delete edw_core.tclaim_transaction where source_system_sk = 5;
-- delete edw_core.tclaim_feature where source_system_sk = 5;
-- delete edw_core.tclaim_task where source_system_sk = 5;
-- delete edw_core.tclaim_note where source_system_sk = 5;
-- delete edw_core.tclaim where source_system_sk = 5;

-- exec [edw_core].[sp_tcause_of_loss_snapsheet];
-- exec [edw_core].[sp_tclaim_snapsheet];
-- exec [edw_core].[sp_tclaim_feature_snapsheet];
-- exec [edw_core].[sp_tclaim_payment_snapsheet];
-- exec [edw_core].[sp_tclaim_transaction_snapsheet];
-- exec [edw_core].[sp_update_tclaim_snapsheet];
-- exec [edw_core].[sp_update_tclaim_feature_snapsheet];
-- exec [edw_core].[sp_tclaim_note_snapsheet];
-- exec [edw_core].[sp_tclaim_task_snapsheet];

select top 10 * from edw_core.tclaim where source_system_sk = 5 and (first_party_driver_nm is not null or source_of_fire is not null or source_of_water is not null);
select top 10 * from edw_core.tclaim where source_system_sk = 5 and (source_of_fire is not null or source_of_water is not null);
select top 10 * from edw_core.tclaim where source_system_sk = 5 and (responsible_party is not null or at_fault_pct is not null);
select * from edw_core.tclaim where source_system_sk = 5;
select * from edw_core.tclaim_feature where source_system_sk = 5;
select * from edw_core.tclaim_payment where source_system_sk = 5;
select * from edw_core.tclaim_transaction where source_system_sk = 5;
select * from edw_core.tclaim_note where source_system_sk = 5;
select * from edw_core.tclaim_task where source_system_sk = 5;
select * from edw_core.tcause_of_loss where source_system_sk = 5;

--** check tables
WITH tbl AS 
(
SELECT * FROM edw_stage_snapsheet.claims 
WHERE 1=1
-- AND id = 485122
-- AND claim_number = '24PRIL828772618'--36 rows
AND claim_number = '24PRLA638183202'
)

-- select * from tbl;
-- SELECT TOP 10 * FROM edw_stage_snapsheet.exposures WHERE claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.financial_reserve_items where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.financial_payment_items where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.financial_payment_details where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.financial_transactions where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.financial_transaction_actions where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.property_incident_detail_fire_damages where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.property_incident_detail_water_damages where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.liability_assignments where claim_id in (select id from tbl);
-- SELECT TOP 10 * FROM edw_stage_snapsheet.liability_determinations where claim_id in (select id from tbl);
SELECT TOP 10 * FROM edw_core.tclaim where claim_no in (select distinct claim_number from tbl);
;


SELECT claim_feature_sk,payment_no,payment_sequence_no,claim_type_cd, COUNT(1) 
FROM edw_temp.tclaim_payment_snapsheet_temp1 
GROUP BY claim_feature_sk,payment_no,payment_sequence_no,claim_type_cd
HAVING COUNT(1) > 1
;

SELECT * FROM edw_temp.tclaim_payment_snapsheet_temp1 WHERE payment_no = '2911384' and claim_feature_sk = '18613' and claim_type_cd = 'property_adjusting';

select distinct product_cd from edw_core.tproduct;
select distinct product_cd from edw_core.tpolicy;

select claim_payment_sk, loss_paid_amt, expense_paid_amt, defense_paid_amt, * 
from edw_core.tclaim_transaction 
-- where claim_payment_sk is not null
where claim_sk = 7657
;

SELECT * FROM edw_temp.tclaim_transaction_snapsheet_temp1 WHERE claim_sk = 7657;
SELECT * FROM edw_temp.tclaim_transaction_snapsheet_temp2 WHERE claim_sk = 7657;
SELECT * FROM edw_temp.tclaim_transaction_snapsheet_temp3 WHERE claim_sk = 7657;
SELECT * FROM edw_temp.tclaim_transaction_snapsheet_temp4 WHERE claim_sk = 7657;

SELECT 
    a.claim_sk,
    a.claim_feature_sk,
    a.product_sk,
    a.policy_sk,
    a.broker_sk,
    a.customer_sk,
    a.transaction_dt_sk,
    a.transaction_ts,
    b.claim_payment_sk,
    -- a.claim_transaction_type_sk,
    -- a.feature_status_sk,
    -- a.loss_reserve_amt,
    -- a.expense_reserve_amt,
    -- a.subrogation_recovery_reserve_amt,
    -- a.salvage_recovery_reserve_amt,
    -- a.salvage_recovery_expense_reserve_amt,
    -- a.subrogation_recovery_expense_reserve_amt,
    b.loss_paid_amt,
    b.expense_paid_amt,
    b.subrogation_recovery_amt,
    b.salvage_recovery_amt,
    b.salvage_expense_recovery_amt,
    b.subrogation_expense_recovery_amt,
    -- a.source_system_sk,
    -- a.created_at,
    -- a.claim_cost_category_sk,
    -- a.defense_reserve_amt,
    -- a.deductible_recovery_reserve_amt,
    -- a.reinsurance_recovery_reserve_amt,
    -- a.overpayment_recovery_reserve_amt,
    -- a.deductible_recovery_expense_reserve_amt,
    -- a.reinsurance_recovery_expense_reserve_amt,
    -- a.overpayment_recovery_expense_reserve_amt,
    -- a.subrogation_recovery_defense_reserve_amt,
    -- a.salvage_recovery_defense_reserve_amt,
    -- a.deductible_recovery_defense_reserve_amt,
    -- a.reinsurance_recovery_defense_reserve_amt,
    -- a.overpayment_recovery_defense_reserve_amt,
    b.defense_paid_amt,
    b.deductible_recovery_amt,
    b.reinsurance_recovery_amt,
    b.overpayment_recovery_amt,
    b.deductible_expense_recovery_amt,
    b.reinsurance_expense_recovery_amt,
    b.overpayment_expense_recovery_amt,
    b.subrogation_defense_recovery_amt,
    b.salvage_defense_recovery_amt,
    b.deductible_defense_recovery_amt,
    b.reinsurance_defense_recovery_amt,
    b.overpayment_defense_recovery_amt
-- INTO edw_temp.tclaim_transaction_snapsheet_temp4
FROM edw_temp.tclaim_transaction_snapsheet_temp2 a
LEFT JOIN edw_temp.tclaim_transaction_snapsheet_temp3 b
    ON a.claim_sk = b.claim_sk
    AND a.product_sk = b.product_sk
    AND a.exposure_name = b.exposure_name
    AND a.transaction_ts = b.transaction_ts
    AND a.financial_transaction_id = b.financial_transaction_id
    AND a.cost_type = b.cost_type
    AND a.exposure_id = b.exposure_id
    AND a.cost_category = b.cost_category
WHERE a.claim_sk = 7657
;

select source_system_sk, payment_submitter_nm, count(1) as rc
from edw_core.tclaim_payment 
group by source_system_sk, payment_submitter_nm
;


SELECT 
    claim_type, 
    loss_type, 
    MAX(updated_at) AS updated_at
FROM edw_stage_snapsheet.claims
GROUP BY claim_type, loss_type
;

select * FROM edw_stage_snapsheet.claims;

select * from edw_core.tcause_of_loss;

select * from edw_stage.migration_create_financial_transaction_action_api_update_stage;

select api_status, count(1) 
from edw_integration.claim_policy_search_snapsheet_api
group by api_status 
order by 1
;
