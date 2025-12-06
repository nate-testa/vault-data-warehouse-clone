--113 (Inforce customers with $0 inforce premium)
update edw_core.tvalidation_sql 
set source_sql='SELECT COUNT(*) FROM (SELECT customer_sk FROM edw_core.tdaily_inforce_policy WHERE source_system_sk <> 6 and inforce_dt_sk = (SELECT date_sk FROM edw_core.tdate WHERE actual_dt = ''var_actual_dt'') GROUP BY customer_sk HAVING SUM(premium_amt) = 0) t'
where validation_sql_desc = 'Inforce customers with $0 inforce premium';


--38 (tpolicy_transaction - negative total prmeium_amt)
update edw_core.tvalidation_sql
set source_sql='select count(*) from (select tr.policy_sk from edw_core.tpolicy_transaction tr, edw_core.tpolicy pol where tr.policy_sk=pol.policy_sk and pol.migrated_in=''No'' and pol.source_system_sk!=6 group by tr.policy_sk having sum(tr.premium_amt)<0) a'
where validation_sql_desc = 'tpolicy_transaction - negative total prmeium_amt';


--130 (Inforce count mismatch between Hubspot and tdaily_inforce_policy)
update edw_core.tvalidation_sql
set source_sql='select count(*)
from edw_core.tdaily_inforce_policy inf
        inner join edw_core.tpolicy pol on inf.policy_sk = pol.policy_sk
        inner join edw_core.tcustomer cust on cust.customer_id = pol.customer_id
        inner join edw_core.tdate td on inf.inforce_dt_sk = td.date_sk and actual_dt = DATEADD(day, -1, cast(getdaTE() as date))
where inf.source_system_sk <> 6 and ((
			isnull(pol.insured_nm,'''') NOT LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS AND
			isnull(cust.last_nm,'''') NOT LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS AND
			isnull(cust.first_nm,'''') NOT LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS AND
			isnull(cust.customer_nm,'''') NOT LIKE ''%test%'' COLLATE SQL_Latin1_General_CP1_CI_AS
		)
		OR (
			isnull(pol.insured_nm,'''') LIKE ''%Richard Tester%'' OR
			isnull(pol.insured_nm,'''') LIKE ''%Potestio%'' OR
			isnull(pol.insured_nm,'''') LIKE ''%Testaverde%'' OR 
			isnull(cust.last_nm,'''') LIKE ''%Potestio%'' OR
			isnull(cust.last_nm,'''') LIKE ''%Testaverde%'' OR
			isnull(cust.first_nm,'''') + '' '' + isnull(cust.last_nm,'''') LIKE ''%Richard Tester%'' OR 
			isnull(cust.customer_nm,'''') LIKE ''%Richard Tester%'' OR
			isnull(cust.customer_nm,'''') LIKE ''%Potestio%'' OR
			isnull(cust.customer_nm,'''') LIKE ''%Testaverde%''
		))'
where validation_sql_desc = 'Inforce count mismatch between Hubspot and tdaily_inforce_policy';


--86
update edw_core.tvalidation_sql set target_sql='select 4'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing coverage_sk';

--48
update edw_core.tvalidation_sql set active_in = 'N'
where validation_sql_desc = 'thome_coverage - multiple deductibles';


--87 (tclaim_feature snapsheet claims - missing item_sk) Updated query
update edw_core.tvalidation_sql 
set source_sql='SELECT count(*) FROM edw_core.tclaim c,	edw_core.tclaim_feature cf,	edw_core.tcustomer cus WHERE c.claim_sk = cf.claim_sk AND cf.source_system_sk = 5 AND cf.product_sk not in (4,10) AND cf.item_sk IS NULL AND cus.customer_id = c.customer_id AND cus.customer_nm <> ''Vault Insurance'''
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing item_sk';

	
--88 (tclaim_feature snapsheet claims - missing vehicle_coverage_sk)
update edw_core.tvalidation_sql
set source_sql='SELECT  count(*) FROM edw_core.tclaim c, edw_core.tclaim_feature cf, edw_core.tcustomer cus WHERE	c.claim_sk = cf.claim_sk AND cf.source_system_sk = 5 AND cf.product_sk = 3	AND cf.vehicle_coverage_sk IS NULL	AND cus.customer_id = c.customer_id and cus.customer_nm <> ''Vault Insurance'''
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing vehicle_coverage_sk';


--17 (tpolicy - billingaccount_sk = 0)
update edw_core.tvalidation_sql
set source_sql='SELECT count(*) FROM edw_core.tpolicy p , edw_core.tcustomer cus WHERE  cus.customer_id = p.customer_id and cus.customer_nm <> ''Vault Insurance'' and isnull(billingaccount_sk,	0) = 0	AND source_system_sk NOT IN (1,6)'
where validation_sql_desc = 'tpolicy - billingaccount_sk = 0';