
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for HO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 1 and item_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for LUX', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 2 and item_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for AU', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and item_sk = 0 and tax_fee_surcharge_amt = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - item_sk= 0 for CO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 5 and item_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts 

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - policy_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where policy_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts
		 
insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for HO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 1 and coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for LUX', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 2 and coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for AU', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 3 and coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for PEL', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 4 and coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - coverage_sk= 0 for CO', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 5 and coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - policy_transaction_type_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where policy_transaction_type_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - internal_coverage_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where internal_coverage_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - product_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where product_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - broker_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where broker_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy_transaction - customer_sk = 0', 
		'select count(*) from edw_core.tpolicy_transaction where customer_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - invalid risk_state_cd', 
		'select count(*) from edw_core.tpolicy where risk_state_cd not in (select state_cd from edw_core.tstate)' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts 

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'tpolicy - billingaccount_sk = 0', 
		'select count(*) from edw_core.tpolicy where billingaccount_sk = 0' source_sql,
		'select 0' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'thome_coverage - loss_of_use_pc is NULL', 
		'select count(*) from edw_core.thome_coverage where loss_of_use_pc is null' source_sql,
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
		'select count(*) from edw_core.tdaily_inforce_policy where inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(day,-1,cast(getdate() as date)))' source_sql,
		'select count(*) from edw_core.tpolicy_summary where inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,''0'','''') ,datepart(mm,getdate()) ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - HO - mismatch between tdaily_inforce_policy and tpolicy_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 1 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(day,-1,cast(getdate() as date)))' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 1 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,''0'','''') ,datepart(mm,getdate()) ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - AU - mismatch between tdaily_inforce_policy and tpolicy_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 3 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(day,-1,cast(getdate() as date)))' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 3 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,''0'','''') ,datepart(mm,getdate()) ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - LUX - mismatch between tdaily_inforce_policy and tpolicy_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 2 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(day,-1,cast(getdate() as date)))' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 2 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,''0'','''') ,datepart(mm,getdate()) ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts

insert into edw_core.tvalidation_sql
	(validation_sql_desc, source_sql, target_sql, active_in, frequency_desc, create_ts, update_ts)
select 'Inforce_ct - PEL - mismatch between tdaily_inforce_policy and tpolicy_summary', 
		'select count(*) from edw_core.tdaily_inforce_policy where product_sk = 4 and inforce_Dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(day,-1,cast(getdate() as date)))' source_sql,
		'select count(*) from edw_core.titem_summary where product_sk = 4 and inforce_Ct = 1 and month_sk = (select max(date_sk) from edw_core.tdate where yearmonth = concat(datepart(yyyy,getdate()),iif(datepart(mm,getdate()) < 10,''0'','''') ,datepart(mm,getdate()) ))' target_sql, 
		'Y' active_in, 
		'Daily' frequency_desc, 
		getdate() create_ts, 
		getdate() update_ts	 