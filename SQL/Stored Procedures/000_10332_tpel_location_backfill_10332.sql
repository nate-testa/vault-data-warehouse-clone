-- SELECT COUNT(1) FROM edw_core.tpel_location;
-- EXEC SP_HELP '[edw_core].[tpel_location]';
-- Unique Key: policy_no, effective_dt, transaction_seq_no, location_no

--1) Drop temp tables
DROP TABLE IF EXISTS edw_temp.tpel_location_backfill_temp1;


--2) Create temp table
select 
	PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,source_system_sk,policy_history_sk,
	rownum as location_no,
	IssuedDate
	,location_deleted_in
	into edw_temp.tpel_location_backfill_temp1
from
(
	select * 
	from
		(
			select
				DENSE_RANK()OVER(PARTITION BY act.PolicyNumber, CAST(act.EffectiveDate AS DATE), act.policychangenumber ORDER BY atvo.Id) as rownum,
				act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
				CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.policy_history_sk,
				CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
				act.policychangenumber AS transaction_seq_no, act.IssuedDate as TransactionDate,atvo.[index],
				act.IssuedDate
				,CASE WHEN atvo.IsdeletedOnPolicyChange = 1 THEN 'Yes' ELSE 'No' END as location_deleted_in
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				left join [edw_core].[tpolicy_history] tph on tph.policy_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.policychangenumber
				left join edw_stage.Product pr on act.ProductId = pr.id
			where act.PolicyNumber is not null and
				act.[State] ='ISSUED'
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and atvo.ObjectType='Location'
				-- and act.IssuedDate > @last_source_extract_ts
		) as t
) as t
;

--3) Update Final table
UPDATE a 
SET  a.location_deleted_in = b.location_deleted_in
FROM edw_core.tpel_location a
LEFT JOIN edw_temp.tpel_location_backfill_temp1 b
ON a.policy_no = b.PolicyNumber  
AND a.effective_dt = b.EffectiveDate
AND a.transaction_seq_no = b.transaction_seq_no 
AND a.location_no = b.location_no
;


--4) Drop temp tables
DROP TABLE IF EXISTS edw_temp.tpel_location_backfill_temp1;


--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

SELECT TOP 100 * FROM edw_core.tpel_location t
WHERE t.location_deleted_in is not null
;

SELECT location_deleted_in, COUNT(1) RC 
FROM edw_core.tpel_location 
GROUP BY location_deleted_in
;

/*
UPDATE edw_core.tpel_location
SET  location_deleted_in = NULL
;
-- */
