INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
		'Duplicate claim transactions' AS validation_sql_desc ,
       'select sum(ct) from
(
select claim_sk , claim_feature_sk , transaction_ts, claim_payment_sk, 
count(*) as ct from edw_core.tclaim_transaction where 
claim_payment_sk is not null 
group by claim_sk , claim_feature_sk, transaction_ts, claim_payment_sk
having count(*) > 1
) as a' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;