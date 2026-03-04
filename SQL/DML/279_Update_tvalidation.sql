-- 84 tclaim_feature - claim_coverage_desc is null
update edw_core.tvalidation_sql 
set target_sql = 'select 2'
where
	validation_sql_desc= 'tclaim_feature - claim_coverage_desc is null'

-- 86 tclaim_feature snapsheet claims - missing coverage_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 9'
where
	validation_sql_desc= 'tclaim_feature snapsheet claims - missing coverage_sk'

-- 87 tclaim_feature snapsheet claims - missing item_sk
update edw_core.tvalidation_sql 
set target_sql = 'select 36'
where
	validation_sql_desc= 'tclaim_feature snapsheet claims - missing item_sk'

-- 81 Snapsheet Validation- Cancelled approved reserves/payments
update edw_core.tvalidation_sql 
set target_sql = 'select 9'
where
	validation_sql_desc= 'Snapsheet Validation- Cancelled approved reserves/payments'


-- 3 tpolicy_transaction - item_sk= 0 for AU
update edw_core.tvalidation_sql
set source_sql =
'select count(*) from
edw_core.tpolicy_transaction pt
inner join edw_core.tdate d on pt.effective_dt_sk = d.date_sk
where product_sk = 3 and isnull(item_sk,0) = 0 and tax_fee_surcharge_sk = 0 and source_system_sk <> 1
and internal_coverage_sk not in
(
select internal_coverage_sk from edw_core.tinternal_coverage
where internal_coverage_cd in (''Automobile Death Indemnity and Disability Income'',
''Auto Death Disability'',''Emergency Living Expense'',''Equipment Manufacturer Parts Enhancement'',
''Full Glass Coverage Enhancement'',''Multiple Policy Deductible Enhancement'',''Stated Value Enhancement'')
)
and d.actual_dt >= ''2025-01-01'' and premium_amt <> 0',
target_sql = 'select 0'
where
validation_sql_desc= 'tpolicy_transaction - item_sk= 0 for AU'