-- SELECT COUNT(1) FROM edw_core.tquote;
-- EXEC SP_HELP '[edw_core].[tquote]';
-- Unique Key: quote_no

--1) Drop table
DROP TABLE IF EXISTS edw_temp.tquote_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tquote_backfill_temp2;


--2) Create temp table
SELECT acc.* 
into edw_temp.tquote_backfill_temp1
FROM edw_stage.Account acc 
left join edw_stage.Product pr on acc.ProductId = pr.id
WHERE acc.PolicyNumber is not null 
and  pr.ProductLine = 'PersonalLines' 


SELECT 
	tmp1.PolicyNumber,
	tmp1.EffectiveDate,
	tmp1.RenewalCapFactor as renewal_cap_factor
INTO edw_temp.tquote_backfill_temp2
FROM edw_temp.tquote_backfill_temp1 tmp1
	left join edw_stage.Product pr on tmp1.ProductId = pr.id
	where pr.productline <> 'CommercialLines'
;

--3) Update Final table
UPDATE a 
SET  a.renewal_cap_factor = b.renewal_cap_factor
FROM edw_core.tquote a
LEFT JOIN edw_temp.tquote_backfill_temp2 b
ON a.quote_no = b.PolicyNumber  
AND a.effective_dt = b.EffectiveDate


--4) Drop table
DROP TABLE IF EXISTS edw_temp.tquote_backfill_temp1;
DROP TABLE IF EXISTS edw_temp.tquote_backfill_temp2;


--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(1) FROM edw_core.tquote t
WHERE t.renewal_cap_factor is not null
;

/*
UPDATE edw_core.tquote
SET  renewal_cap_factor = NULL
;
-- */

select RenewalCapFactor, count(1) from edw_stage.Account group by RenewalCapFactor;