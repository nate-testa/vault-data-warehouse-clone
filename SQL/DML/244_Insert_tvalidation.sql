INSERT INTO edw_commercial.tcommercial_validation_sql
 (commercial_validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)

SELECT 'tcommercial_policy_transaction - policy_sk = 0' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_transaction where isnull(commercial_policy_sk,0) = 0' AS source_sql ,   
  'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - coverage_sk= 0 for Media' AS commercial_validation_sql_desc ,
	'select count(*) from edw_commercial.tcommercial_policy_transaction where product_sk = 7 and isnull(coverage_sk,0) = 0' AS source_sql ,
   'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts

UNION
SELECT 'tcommercial_policy_transaction - coverage_sk= 0 for LPL' AS commercial_validation_sql_desc ,
    'select count(*) from edw_commercial.tcommercial_policy_transaction where product_sk = 8 and isnull(coverage_sk,0) = 0' AS source_sql ,
   'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - coverage_sk= 0 for MPL' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_transaction where product_sk = 9 and isnull(coverage_sk,0) = 0' AS source_sql ,
 'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - policy_transaction_type_sk = 0' AS commercial_validation_sql_desc ,	
'SELECT count(*) from edw_commercial.tcommercial_policy_transaction where isnull(policy_transaction_type_sk,0) = 0 ' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - product_sk = 0' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_transaction where isnull(product_sk,0) = 0' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - broker_sk = 0' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_transaction where isnull(broker_sk,0) = 0' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - customer_sk = 0' AS commercial_validation_sql_desc ,
'select count(*) from edw_commercial.tcommercial_policy_transaction where isnull(customer_sk,0) = 0' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy - invalid risk_state_cd' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy where risk_state_cd is null or risk_state_cd not in (select state_cd from edw_core.tstate)' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - Missing transactions for policies in tcommercial_policy' AS commercial_validation_sql_desc , 	
'select count(*) from edw_commercial.tcommercial_policy pol where not exists (select 1 from edw_commercial.tcommercial_policy_transaction tr where tr.commercial_policy_sk=pol.commercial_policy_sk) and customer_id not like ''%LIT%''' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Inforce_ct for current month - ALL - mismatch between tcommercial_daily_inforce_policy and tcommercial_policy_summary' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_daily_inforce_policy where inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' AS source_sql ,
'select count(*) from edw_commercial.tcommercial_policy_summary where inforce_ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy - insured_nm is null' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy where insured_nm is null' AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_history - transaction_type is null' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_history where transaction_type is null'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy - dupes on policy_no' AS commercial_validation_sql_desc ,	
'select count(*) from ( select policy_no from edw_commercial.tcommercial_policy group by policy_no having count(*)>1) a'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_transaction - negative total premium_amt' AS commercial_validation_sql_desc ,	
'select count(*) from (select tr.commercial_policy_sk from edw_commercial.tcommercial_policy_transaction tr, edw_commercial.tcommercial_policy pol where tr.commercial_policy_sk=pol.commercial_policy_sk  group by tr.commercial_policy_sk having sum(tr.premium_amt)<0) a'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_quote_history - Dupes on latest_transaction_in' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_quote_history where quote_no in (select quote_no from edw_commercial.tcommercial_quote_history where latest_transaction_in = ''Y'' group by quote_no having count(*) > 1) '  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_policy_history - transactions after policy expiry' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy_history where datediff("d",expiration_dt,cast(transaction_ts as date)) > 0 and datediff("d",cast(transaction_ts as date),getdate()) <= 30'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'tcommercial_claim_feature - negative paid' AS commercial_validation_sql_desc ,	
'SELECT count(*) from ( select commercial_claim_feature_sk from edw_commercial.tcommercial_claim_feature  a group by commercial_claim_feature_sk having  SUM( COALESCE( ( a.loss_paid_amt + a.expense_paid_amt + a.defense_paid_amt), 0) )<0 ) a'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Metal Validation - AccountTransaction - Issued transaction with prorated premium' AS commercial_validation_sql_desc ,	
'select count(*) from ( select PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,IssuedDate from edw_stage.AccountTransaction a, edw_stage.Product b
where state=''ISSUED'' and stage=''POLICY'' and NetPremiumDeltaProRated is not null and a.ProductId=b.id and ProductLine=''CommercialLines'') a'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION
SELECT 'Metal Validation - AccountTransaction - Missing premium stat records for issued transactions' AS commercial_validation_sql_desc ,	
'select count(*) from edw_stage.accounttransaction a, edw_stage.Product b 
where not exists (select * from edw_stage.AccountTransactionCoveragePremium b
where a.id=b.AccountTransactionId) and a.[State]=''ISSUED'' and a.ProductId=b.id and b.ProductLine=''CommercialLines''
and cast(IssuedDate as date)>=''20240301'''  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'Metal Validation - AccountTransaction - Missing premium stat records for issued transactions' AS commercial_validation_sql_desc ,	
'select count(*) from edw_stage.accounttransaction a, edw_stage.Product b where not exists (select * from edw_stage.AccountTransactionCoveragePremium b
where a.id=b.AccountTransactionId) and a.[State]=''ISSUED'' and a.ProductId=b.id and b.ProductLine=''CommercialLines''
and cast(IssuedDate as date)>=''20240301'''  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim_transaction - Duplicate claim transactions' AS commercial_validation_sql_desc ,	
'select count(*)
from
(
  select distinct commercial_claim_sk , commercial_claim_feature_sk , transaction_ts, commercial_claim_payment_sk,
  count(*) over (partition by commercial_claim_sk , commercial_claim_feature_sk, transaction_ts, commercial_claim_payment_sk) as ct
  from edw_commercial.tcommercial_claim_transaction
  where   commercial_claim_payment_sk is not null 
) a where ct > 1'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim_feature - aslob_sk is null but claim coverage exists' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_claim_feature a where aslob_sk is null  and claim_coverage_desc is not null and exists
(select * from edw_commercial.tcommercial_claim_transaction b where a.commercial_claim_feature_sk=b.commercial_claim_feature_sk)'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim_feature - claim_coverage_desc is null' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_claim_feature a where claim_coverage_desc is null and exists
(select * from edw_commercial.tcommercial_claim_transaction b where a.commercial_claim_feature_sk=b.commercial_claim_feature_sk)'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim_transaction - feature_status_sk null' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_claim_transaction where commercial_claim_feature_sk is null'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim_transaction - row count is 0' AS commercial_validation_sql_desc ,	
'select count(*) from edw_core.tetl_audit where process_nm=''sp_tcommercial_claim_transaction'' and
DATENAME(WEEKDAY, process_start_ts) not in (''Monday'',''Sunday'') and record_ct=0 and cast(process_start_ts as date)=cast(getdate() as date)'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_policy_transaction - row count is 0' AS commercial_validation_sql_desc ,	
'select count(*) from edw_core.tetl_audit where process_nm=''sp_tcommercial_policy_transaction'' and
DATENAME(WEEKDAY, process_start_ts) not in (''Monday'',''Sunday'') and record_ct=0 and cast(process_start_ts as date)=cast(getdate() as date)'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_policy - Incorrect cancelled policy status' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_policy where cancellation_effective_dt > getdate() and policy_status = ''Cancelled'''  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'Snapsheet claims - null product_sk' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_claim where product_sk is null'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'tcommercial_claim - claim_no length > 15' AS commercial_validation_sql_desc ,	
'select count(*) from edw_commercial.tcommercial_claim where len(claim_no) > 15'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'Inforce commercial customers with $0 inforce premium' AS commercial_validation_sql_desc ,	
'SELECT COUNT(*) FROM (SELECT customer_sk FROM edw_commercial.tcommercial_daily_inforce_policy 
    WHERE inforce_dt_sk = (SELECT date_sk FROM edw_core.tdate WHERE actual_dt = ''var_actual_dt'') GROUP BY customer_sk HAVING SUM(premium_amt) = 0) t'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts
UNION 
SELECT 'Test policies in tcommercial_daily_inforce_policy' AS commercial_validation_sql_desc ,	
'select count(*)
from edw_commercial.tcommercial_daily_inforce_policy inf
        inner join edw_commercial.tcommercial_policy pol on inf.commercial_policy_sk = pol.commercial_policy_sk
        inner join edw_core.tcustomer cust on cust.customer_id = pol.customer_id
        inner join edw_core.tdate td on inf.inforce_dt_sk = td.date_sk and actual_dt = DATEADD(day, -1, cast(getdaTE() as date))
where ((
isnull(pol.insured_nm,'''') LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS OR
isnull(cust.last_nm,'''')  LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS OR
isnull(cust.first_nm,'''')  LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS OR
isnull(cust.customer_nm,'''')  LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS
))'  AS source_sql ,
'select 0' AS target_sql ,'Y' AS active_in ,'Daily' AS frequency_desc ,getdate() AS create_ts ,getdate() AS update_ts