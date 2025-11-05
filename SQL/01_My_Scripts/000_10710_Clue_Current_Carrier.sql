select TOP 10 * from edw_core.tetl_audit where process_nm like '%carrier%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm like '%carrier%';
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed');
EXEC sp_help 'edw_integration.policy_current_carrier_auto_np01_feed';
EXEC sp_help 'edw_integration.policy_current_carrier_auto_sj01_feed';
EXEC sp_help 'edw_integration.policy_current_carrier_auto_pr01_feed';
EXEC sp_help 'edw_integration.policy_current_carrier_auto_vr01_feed';

SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed];
-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed];
-- EXEC [edw_core].[sp_claim_clue_auto_feed];


select top 100 * from edw_integration.policy_current_carrier_auto_np01_feed;
select top 100 * from edw_integration.policy_current_carrier_auto_sj01_feed;
select top 100 * from edw_integration.policy_current_carrier_auto_pr01_feed;
select top 100 * from edw_integration.policy_current_carrier_auto_vr01_feed;

select count(1) rc from edw_integration.policy_current_carrier_auto_np01_feed
union all select count(1) rc from edw_integration.policy_current_carrier_auto_sj01_feed
union all select count(1) rc from edw_integration.policy_current_carrier_auto_pr01_feed
union all select count(1) rc from edw_integration.policy_current_carrier_auto_vr01_feed
;

SELECT *
        FROM edw_integration.policy_current_carrier_auto_np01_feed
        --WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
        WHERE policy_no in ('AU100103987-04','AU100187925')
        ;

-------------------------------------------------------------------------------------

select a.* from (
select RecordCode, policy_no, policy_history_sk, transaction_seq_no, null as auto_driver_sk, null as auto_vehicle_sk, null as auto_policy_coverage_sk, null as auto_vehicle_coverage_sk, create_ts
from edw_integration.policy_current_carrier_auto_np01_feed
where policy_no = 'AU100103987-04'
--and policy_history_sk = 200011
union all
select RecordCode, policy_no, policy_history_sk, transaction_seq_no, auto_driver_sk, null as auto_vehicle_sk, null as auto_policy_coverage_sk, null as auto_vehicle_coverage_sk, create_ts
from edw_integration.policy_current_carrier_auto_sj01_feed
where policy_no = 'AU100103987-04'
--and policy_history_sk = 200011
union all
select RecordCode, policy_no, policy_history_sk, transaction_seq_no,null as auto_driver_sk,  auto_vehicle_sk, auto_policy_coverage_sk, auto_vehicle_coverage_sk, create_ts
from edw_integration.policy_current_carrier_auto_pr01_feed
where policy_no = 'AU100103987-04'
--and policy_history_sk = 200011
union all
select RecordCode, policy_no, policy_history_sk, transaction_seq_no, null as auto_driver_sk, auto_vehicle_sk, null as auto_policy_coverage_sk, auto_vehicle_coverage_sk, create_ts
from edw_integration.policy_current_carrier_auto_vr01_feed
where policy_no = 'AU100103987-04'
--and policy_history_sk = 200011
) a
order by 2,3,6,5,1 
;

-----------------------------------------------------------------------------------------------------------------------
SELECT * FROM edw_integration.policy_current_carrier_auto_np01_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE);