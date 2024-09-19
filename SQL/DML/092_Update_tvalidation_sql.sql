update edw_core.tvalidation_sql set active_in = 'N' where validation_sql_sk = 66 and validation_sql_desc = 'Metal Validation - AccountTransaction - Duplicate cancelled transactions'
update edw_core.tvalidation_sql set target_sql = 'select 1' where validation_sql_sk = 68 and validation_sql_desc = 'Metal Validation - AccountTransaction - Duplicate cancelled transactions'

update edw_core.tvalidation_sql
set
	target_sql = 'select count(*) from edw_core.tpolicy_transaction a
inner join edw_core.tinternal_coverage ic on a.internal_coverage_sk = ic.internal_coverage_sk
where isnull(collection_class_type_sk,0) = 0
and tax_fee_surcharge_sk = 0    
and (product_sk = 2  or (source_system_sk = 4 and product_sk in (1,5) and ic.internal_coverage_cd = ''Lux'')  )'
where validation_sql_desc = 'tpolicy_transaction - LUX - collection_class_type_sk = 0'
