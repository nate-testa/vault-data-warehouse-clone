insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'thome_coverage - null residence_type' 
		,'select count(*) from edw_core.thome_coverage where residence_type is null'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();  

insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tclaim_transaction - total reserves <> 0 for closed claim'  
		,'select count(*) from (
			select c.claim_no
			from edw_core.tclaim_transaction ct, edw_core.tclaim c
			where ct.claim_sk = c.claim_sk
			and c.claim_status = ''CLOSED''
			group by c.claim_no
			having sum(ct.loss_reserve_amt +  ct.expense_reserve_amt + ct.adjusting_other_reserve_amt 
					+ ct.subro_reserve_amt + ct.salvage_reserve_amt + ct.subro_expense_reserve_amt 
					+ ct.salvage_expense_reserve_amt) <> 0) a'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();   