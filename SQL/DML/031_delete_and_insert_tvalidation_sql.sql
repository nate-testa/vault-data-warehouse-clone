delete from edw_core.tvalidation_result
delete from edw_core.tvalidation_sql

DBCC CHECKIDENT('edw_core.tvalidation_result',RESEED,0)
DBCC CHECKIDENT('edw_core.tvalidation_sql',RESEED,0)

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for HO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 1 and isnull(item_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for LUX', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 2 and isnull(item_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for AU', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and isnull(item_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for CO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 5 and isnull(item_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts 

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - policy_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(policy_sk,0) = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts
			 
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for HO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 1 and isnull(coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for LUX', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 2 and isnull(coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for AU', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and isnull(coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for PEL', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 4 and isnull(coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for CO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 5 and isnull(coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts		

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - policy_transaction_type_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(policy_transaction_type_sk,0) = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - internal_isnull(coverage_sk,0) = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(internal_coverage_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - product_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(product_sk,0) = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - broker_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(broker_sk,0) = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - customer_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where isnull(customer_sk,0) = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - invalid risk_state_cd', 
		'select count(*) from edw_core.tpolicy where risk_state_cd is null or risk_state_cd not in (select state_cd from edw_core.tstate)' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts 

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - billingaccount_sk = 0', 
		'select count(*) from edw_core.tpolicy where isnull(billingaccount_sk,0) = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'thome_coverage - loss_of_use_derived_pc is NULL', 
		'select count(*) from edw_core.thome_coverage where loss_of_use_derived_pc is null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - Missing transactions for policies in tpolicy ', 
		'select count(*) from edw_core.tpolicy pol where not exists (select 1 from edw_core.tpolicy_transaction tr where tr.policy_sk=pol.policy_sk)' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts 

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct for current month - ALL - mismatch between tdaily_inforce_policy and tpolicy_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' source_sql,
		'select count(*) from edw_core.tpolicy_summary where inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - HO - mismatch between tdaily_inforce_policy and titem_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 1 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 1 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - AU - mismatch between tdaily_inforce_policy and titem_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 3 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' source_sql,
		'select count(distinct policy_sk) from edw_core.titem_summary where product_sk = 3 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - LUX - mismatch between tdaily_inforce_policy and titem_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 2 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 2 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts
		
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - PEL - mismatch between tdaily_inforce_policy and titem_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 4 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = ''var_actual_dt'')' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 4 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,''var_actual_dt''),iif(datepart(mm,''var_actual_dt'') < 10,''0'','''') ,datepart(mm,''var_actual_dt'') ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts;

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - vehicle_coverage_sk = 0 for AU', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and isnull(vehicle_coverage_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts
		
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - insured_nm is null', 
		'select count(*) from edw_core.tpolicy where insured_nm is null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts;	

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_history - transaction_type is null', 
		'select count(*) from edw_core.tpolicy_history where transaction_type is null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tquote - first_offered_quote_history_sk is null', 
		'select count(*) from edw_core.tquote where first_offered_quote_history_sk is null and bind_dt is not null' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tbroker_vault_team - dupes', 
		'select count(distinct broker_id) from
		  (select broker_id,product_nm,program_type,team_member_type,count(*) cnt from edw_core.tbroker_vault_team 
		  group by broker_id,product_nm,program_type,team_member_type
		  having count(*)>1
		  )a' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tcollection_class_type - missing transactions', 
		'select count(*) from edw_core.tpolicy_history a , edw_core.tproduct b
		 where a.product_sk = b.product_sk and a.source_system_sk in (2,4) and b.product_cd=''LUX''
		 and not exists (Select * from edw_core.tcollection_class_type b where a.policy_history_sk=b.policy_history_sk)' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_insured - dupes on primary insured', 
		'select count(*) from
		(
		select policy_no, effective_dt, transaction_seq_no, primary_insured_in
		from edw_core.tpolicy_insured
		where primary_insured_in = ''Yes''
		group by policy_no, effective_dt, transaction_seq_no, primary_insured_in
		having count(1) > 1
		) a' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - incorrect uw_company_nm and program_type', 
		'SELECT count(*) FROM edw_core.tpolicy p 
INNER JOIN edw_core.tpolicy_transaction pt ON pt.policy_sk = p.policy_sk
INNER JOIN edw_core.tinternal_coverage tic ON pt.internal_coverage_sk = tic.internal_coverage_sk
WHERE p.uw_company_nm = ''Vault E & S Insurance Company'' AND tic.internal_coverage_desc = ''Subscriber Contribution''' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	;