select * from edw_stage.t_clm_case;


--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'HO200030244'
    ) 
    -- OR PolicyNumber LIKE 'CO100051662%'
)
,acctv AS (
    SELECT * FROM edw_stage.AccountTransactionVersion 
    WHERE AccountTransactionId in (select Id from acct)
)
,acctvo AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObject 
    WHERE AccountTransactionVersionId in (select Id from acctv)
)
,acctvof AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE VersionObjectId in (select Id from acctvo)
)

--***All
-- select * from acct;
-- select * from acctv;
-- select * from acctvo;
-- select * from acctvof;

--***Filters
SELECT 
    '****acct****' as acct, acct.*, 
    '****acctv****' as acctv, acctv.*, 
    '****acctvo****' as acctvo, acctvo.*, 
    '****acctvof****' as acctvof, acctvof.*,
    'End'
FROM acct
INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
WHERE 1=1 
AND acctvof.Field = '%OtherStructuresOnTheResidencePremisesIncreasedLimit%'
-- AND acct.PolicyChangeNumber = 1
-- AND acct.PolicyNumber is not null 
-- AND acct.[State] ='ISSUED'
-- AND acctvo.[Index] = 6
-- AND acctvo.ObjectType = 'ExtendedLiabilityLocation'
-- AND [Value] LIKE '%10159 S Foothill Blvd%'
;
--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************


--**Create Policy (create_policy)
select
	distinct policy_no as policyNumber,
	CASE
		when product_nm = 'Auto' then 'auto'
		when product_nm = 'Homeowners' then 'home'
		ELSE 
product_nm
	END as policyType ,
	policy_status as status ,
	--effective_dt as coverageStartDate , 
	FORMAT(effective_dt,
	'yyyy-MM-ddTHH:mm:ssZ') AS coverageStartDate ,
	--ISO DateTime Format 
	JSON_QUERY((
	select
		cpsa.insured_nm as name
for json path,
		include_null_values,
		WITHOUT_ARRAY_WRAPPER
)) as policyEntities
	--insured_nm as name 
from
	edw_integration.claim_policy_search_api cpsa
where
	policy_no in ('AU100118541-01', 'HO100201853-01') 
; 

--**Create Policy (create_policy)

--**Create Claim (create_claim)
select *
    -- claim_api_sk,claimNumber,claimType,status,policyNumber,datetimeOfLoss,
    -- datetimeOfNotification,accountCode,lossType,notes,claimIncidentDetails,
    -- exposures,vehicles,claimParties
from edw_stage.migration_create_claim_api
;

-- update edw_stage.migration_create_claim_api set lossType = 'property_claim_Theft' where claim_api_sk = 14;
-- update edw_stage.migration_create_claim_api set api_status = 'Success', api_Error_description = '493849' where claim_api_sk = 3;
-- update edw_stage.migration_create_claim_api set api_Error_description = NULL where api_status = 'Success';


--**Create Claim (create_claim)

select distinct 
    policy_no as policyNumber , 
    null as policyType, 
    policy_status as [status], 
    product_nm as productCode, 
    null as inceptionDate, 
    null as coverageStartDate, 
    null as coverageEndDate, 
    insured_nm as agentNumber, 
    null as policyVehicles, 
    null as policyDrivers, 
    null as policyEntities, 
    null as externalClaims
from edw_integration.claim_policy_search_api
where policy_no in ('AU100118541-01','HO100201853-01')
;

select * from edw_stage.migration_create_claim_api;


INSERT INTO edw_stage.migration_create_policy_api (policyNumber,policyType,[status],productCode,inceptionDate,policyEntities,api_status)
VALUES
    (
        SELECT distinct
            policy_no as policyNumber,
            case
                when product_nm = 'Auto' then 'auto'
                when product_nm = 'Homeowners' then 'business_owners_policy' 
                else product_nm
            end as policyType,
            policy_status as [status],
            NULL as productCode,
            effective_dt as inceptionDate ,
            JSON_QUERY((
                select insured_nm as [name]
                for json path, include_null_values
                ))as policyEntities,
            'pending' as api_status
        FROM
            edw_integration.claim_policy_search_api
        WHERE
            policy_no in ('HO100030764','AU100019779')
    )
; 

select top 10 * from edw_core.tpolicy;


select * from edw_stage.migration_create_claim_api where api_status = 'Success' AND api_response is not null AND claimNumber = 'C24HOA00064';
select * from edw_stage.migration_create_note_api;
select * from edw_stage.migration_create_financial_transaction_api where claim_no = 'C24HOA00064';
-- delete from edw_stage.migration_create_financial_transaction_api where claim_no = 'C24HOA00064'
select * from edw_stage.migration_update_exposure_adjuster_api;
select top 10 * from edw_integration.claim_policy_search_snapsheet_api where policyNumber = 'AU100117034-01';
select top 10 * from [edw_integration].[policy_ivans_auto_feed] where PolicyNumber_031 = 'AU100117034-01';

select top 10 * from edw_stage.migration_update_exposure_status_api;

-- update edw_stage.migration_update_exposure_adjuster_api set [data] = replace([data],'aUessCYVYbRmtVx3Qdw','3H-aUessCYVYbRmtVx3Qdw') where exposureReferenceNumber = '1138283';

select 
    claim_no, exposure_id, exposureReferenceNumber, [data]
from edw_stage.migration_update_exposure_adjuster_api
where api_status  in ('Error', 'pending')
;

select api_status, count(1) from edw_integration.claim_policy_search_snapsheet_api group by api_status;
-- update edw_integration.claim_policy_search_snapsheet_api set api_status = 'pending' where api_status = 'Error';

-- select claimNumber from edw_stage.migration_create_claim_api group by claimNumber having count(1) > 1;

-- update edw_integration.claim_policy_search_snapsheet_api set policyEntities = '[{"name":null,"firstName":"Joseph","lastName":"Wagner","entityType":"PERSON","addresses":{"address1":"101","address2":null,"city":"North Brunswick","region":"NJ","postalCode":"08902","country":"US"},"contactMethods":[]}]' where policyNumber = 'HO200030328' and transaction_seq_no = 1;

select 
    claim_api_sk, claimNumber, claimType, status, policyNumber, datetimeOfLoss, datetimeOfNotification,
    accountCode, lossType, claimIncidentDetails, exposures, vehicles, claimParties
from edw_stage.migration_create_claim_api
where api_status = 'pending'
;

select * from edw_stage.migration_create_claim_api
;

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
    where api_status in ('Error','pending') 
) a 
WHERE a.rank = 1
;


SELECT CAST(update_ts AS DATE) as update_ts, api_status, COUNT(1) as Row_Count 
FROM edw_integration.claim_policy_search_snapsheet_api 
WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
GROUP BY CAST(update_ts AS DATE), api_status
;

select claim_no, note_created_ts, note_json as data
from edw_stage.migration_create_note_api
where api_status = 'pending'
;

select * from edw_stage.migration_create_claim_api_update_status
;

select 
    claimRerenceNumber, data
from edw_stage.migration_create_claim_api_update_catastrophe
where api_status  in ('Error', 'pending')
;

select * from edw_stage.migration_create_claim_api_update_catastrophe
;

select count(1) as ct from edw_stage.migration_create_financial_transaction_api where api_status = 'Error' and claim_no = 'C23AUA00059';

select * from edw_stage.migration_create_financial_transaction_api where claim_no = 'C23AUA00059';
select * from edw_stage.migration_create_claim_api;

select
    settle_payee_id, data
from edw_integration.claim_financial_transaction_action_snapsheet_api
where api_status  in ('pending')
;
select * from edw_integration.claim_financial_transaction_action_snapsheet_api;