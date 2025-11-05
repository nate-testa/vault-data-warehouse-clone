-- SELECT COUNT(1) FROM edw_core.thome_coverage;
EXEC SP_HELP '[edw_core].[thome_coverage]';
-- Unique Key: policy_no, effective_dt, transaction_seq_no

--1) Drop temp tables
DROP TABLE IF EXISTS edw_temp.thome_coverage_backfill_temp1;


--2) Create temp table

with source_data_1 as (
	select act.*
	from
		edw_stage.AccountTransaction act
		inner join edw_stage.Product p on p.Id=act.ProductId
	where
		act.PolicyNumber is not null and
		act.[State] ='ISSUED'	
		and p.ProductLine = 'PersonalLines'
		-- and act.IssuedDate > @last_source_extract_ts
)
,source_data_2 as (
	select
		act.PolicyNumber ,act.EffectiveDate ,act.TransactionEffectiveDate ,
		act.policychangenumber as transaction_seq_no, act.IssuedDate as transactiondate, act.IssuedDate, p.name product_name
		,atv.PremiumAnalyticsGrade as premium_analytics_grade
	from
		source_data_1 act
		inner join edw_stage.Product p on p.Id=act.ProductId
		inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
		inner join edw_stage.AccountTransactionVersionPremium atvp on atv.Id=atvp.AccountTransactionVersionId				
		inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
	where
		atvo.ObjectType in ('Homeowner','Condo','Inspection')
)
select 
	PolicyNumber,EffectiveDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,
	premium_analytics_grade,
	IssuedDate
into edw_temp.thome_coverage_backfill_temp1
from source_data_2
;


--3) Update Final table
UPDATE a 
SET  a.premium_analytics_grade = b.premium_analytics_grade
FROM edw_core.thome_coverage a
LEFT JOIN edw_temp.thome_coverage_backfill_temp1 b
ON a.policy_no = b.PolicyNumber  
AND a.effective_dt = b.EffectiveDate
AND a.transaction_seq_no = b.transaction_seq_no
;


--4) Drop temp tables
DROP TABLE IF EXISTS edw_temp.thome_coverage_backfill_temp1;


--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

SELECT TOP 10 * FROM edw_core.thome_coverage t
WHERE t.premium_analytics_grade is not null
;

SELECT premium_analytics_grade, COUNT(1) RC 
FROM edw_core.thome_coverage 
GROUP BY premium_analytics_grade
;

/*
UPDATE edw_core.thome_coverage
SET  premium_analytics_grade = NULL
;
-- */
