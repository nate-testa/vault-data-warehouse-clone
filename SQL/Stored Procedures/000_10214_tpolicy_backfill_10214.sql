-- SELECT COUNT(1) FROM edw_core.tpolicy;
-- EXEC SP_HELP '[edw_core].[tpolicy]';
-- Unique Key: policy_no, effective_dt

--1) Drop table
DROP TABLE IF EXISTS edw_temp.tpolicy_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tpolicy_backfill_temp2;


--2) Create temp table
WITH cte_AccountTransaction AS (
	SELECT  
		acct.*,
		case when acct.ExternalSourceId is not NULL 
				then 2 --(AV2) 
				Else 4 --(Metal)
		end ssk
		,ROW_NUMBER() OVER (PARTITION BY acct.PolicyNumber, acct.EffectiveDate 
				ORDER BY acct.policychangenumber DESC) AS AccountTransaction_Rank
	FROM edw_stage.AccountTransaction acct 
	left join edw_stage.Product pr on acct.ProductId = pr.id
	WHERE acct.PolicyNumber is not null 
		and acct.State ='ISSUED'
		and pr.ProductLine = 'PersonalLines' 
		-- AND GREATEST(acct.IssuedDate)>@last_source_extract_ts
)
SELECT cte_Acc.*
INTO edw_temp.tpolicy_backfill_temp1
FROM cte_AccountTransaction cte_Acc
WHERE cte_Acc.AccountTransaction_Rank = 1

SELECT 
	tmp1.PolicyNumber,
	tmp1.EffectiveDate,
	acc.RenewalCapFactor as renewal_cap_factor
	INTO edw_temp.tpolicy_backfill_temp2
FROM edw_temp.tpolicy_backfill_temp1 tmp1
INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = tmp1.Id
inner join edw_stage.Account acc on tmp1.AccountId = acc.Id 
left join edw_stage.Product pr on tmp1.ProductId = pr.id
where pr.productline <> 'CommercialLines'
;

--3) Update Final table
UPDATE a 
SET  a.renewal_cap_factor = b.renewal_cap_factor
FROM edw_core.tpolicy a
LEFT JOIN edw_temp.tpolicy_backfill_temp2 b
ON a.policy_no = b.PolicyNumber  
AND a.effective_dt = b.EffectiveDate


--4) Drop table
DROP TABLE IF EXISTS edw_temp.tpolicy_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tpolicy_backfill_temp2;


--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(1) FROM edw_core.tpolicy t
WHERE t.renewal_cap_factor is not null
;

/*
UPDATE edw_core.tpolicy
SET  renewal_cap_factor = NULL
;
-- */

select RenewalCapFactor, count(1) from edw_stage.Account group by RenewalCapFactor;