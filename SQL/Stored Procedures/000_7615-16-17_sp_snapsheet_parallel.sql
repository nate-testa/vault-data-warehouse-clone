SELECT top 100 * FROM [edw_integration].[claim_policy_search_snapsheet_api_V1] ORDER BY 1;
SELECT top 100 ID as iidd, update_ts as uts, * FROM [edw_integration].[claim_policy_search_snapsheet_api_V1] where api_status = 'Success' order by update_ts asc;


SELECT * FROM [edw_integration].[claim_policy_search_snapsheet_api_V1] where id between 1 and 34;

UPDATE [edw_integration].[claim_policy_search_snapsheet_api_V1] SET api_status = 'pending' where id <= 100;
UPDATE [edw_integration].[claim_policy_search_snapsheet_api_V1] SET api_status = 'hold' where id > 100;

select api_status, count(1)     
from edw_integration.claim_policy_search_snapsheet_api_V1
group by api_status 
order by 1
;

SELECT productCode, count(1) as ct FROM [edw_integration].[claim_policy_search_snapsheet_api_V1] where id <= 100 group by productCode;

----------------------------------------------------------------------------------------------
select api_status, count(1) ct from edw_integration.claim_policy_search_snapsheet_api group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_create_claim_api group by api_status order by 1;--10000
select api_status, count(1) ct from edw_stage.migration_create_financial_transaction_api group by api_status order by 1;--90000
select api_status, count(1) ct from edw_stage.migration_create_note_api group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_update_exposure_adjuster_api group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_create_claim_api_update_catastrophe group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_update_exposure_status_api group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_create_claim_api_update_status group by api_status order by 1;
select api_status, count(1) ct from edw_stage.migration_create_claim_party_update_api group by api_status order by 1;


select count(1) from edw_stage.migration_create_financial_transaction_api;--93274
select api_status, count(1) from edw_stage.migration_create_financial_transaction_api where financial_transaction_id > 1908 group by api_status order by 1;
select financial_transaction_id, claim_no, api_status from edw_stage.migration_create_financial_transaction_api where financial_transaction_id > 62822 order by financial_transaction_id, claim_no;

SELECT 
    api_status,
    CASE 
        WHEN id BETWEEN 1 AND 35000 THEN '1 - 35000'
        WHEN id BETWEEN 35001 AND 62823 THEN '35001 - 70000'
        ELSE 'Greater than 70000'
    END AS id_range,
    COUNT(*) AS total_count
FROM edw_stage.migration_create_note_api
GROUP BY api_status, 
        CASE 
            WHEN id BETWEEN 1 AND 35000 THEN '1 - 35000'
            WHEN id BETWEEN 35001 AND 62823 THEN '35001 - 70000'
            ELSE 'Greater than 70000'
        END
ORDER BY api_status, id_range;


select top 10 * from edw_stage.migration_create_note_api;

select cast(create_ts as date) as dt, api_status, count(1) from edw_stage.migration_create_note_api group by api_status, cast(create_ts as date) order by 1;

select etl_audit_sk, count(1) ct from edw_stage.migration_create_note_api group by etl_audit_sk;

