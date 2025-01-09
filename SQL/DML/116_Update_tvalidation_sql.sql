update edw_core.tvalidation_sql 
set source_sql = 'select count(*)
	from
	(
		  select distinct claim_sk , claim_feature_sk , transaction_ts, claim_payment_sk,
				  count(*) over (partition by claim_sk , claim_feature_sk, transaction_ts, claim_payment_sk) as ct 
		  from edw_core.tclaim_transaction 
		  where   claim_payment_sk is not null  
	) a
	where ct > 1',
	validation_sql_desc = 	'tclaim_transaction - Duplicate claim transactions'
where validation_sql_desc = 	'Duplicate claim transactions'