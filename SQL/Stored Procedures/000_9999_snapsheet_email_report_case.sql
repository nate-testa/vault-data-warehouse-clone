SELECT CAST(update_ts AS DATE) as update_ts, api_status, COUNT(1) as Row_Count 
FROM edw_integration.claim_policy_search_snapsheet_api 
WHERE policyType != 'professional_liability' 
AND CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
GROUP BY CAST(update_ts AS DATE), api_status
;

SELECT CAST(create_ts AS DATE) create_ts, CAST(update_ts AS DATE) as update_ts, COUNT(1) rc 
FROM edw_integration.claim_policy_search_snapsheet_api 
WHERE CAST(update_ts AS DATE) = '2025-07-11' 
GROUP BY CAST(create_ts AS DATE), CAST(update_ts AS DATE);


select policyNumber,inceptionDate, *
FROM edw_integration.claim_policy_search_snapsheet_api 
WHERE CAST(update_ts AS DATE) = '2025-07-11' 
order by 1,2
;


SELECT api_status, COUNT(1) FROM edw_integration.claim_policy_search_snapsheet_api GROUP BY api_status;

SELECT
    policyNumber, policyType, status, productCode, inceptionDate, policyEntities, transaction_seq_no
FROM 
(
    select 
        policyNumber, 
        policyType, 
        status, 
        productCode, 
        inceptionDate, 
        policyEntities, 
        transaction_seq_no,
        ROW_NUMBER() OVER (PARTITION BY policyNumber , inceptionDate ORDER BY transaction_seq_no DESC) AS rank
    from 
        edw_integration.claim_policy_search_snapsheet_api
    where api_status in ('pending')
    and 1=1
) a 
WHERE a.rank = 1