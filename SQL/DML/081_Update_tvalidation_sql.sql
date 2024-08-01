update edw_core.tvalidation_sql 
set target_sql = 'select 5'
where validation_sql_desc  = 'tclaim_feature - negative paid' ; 

update edw_core.tvalidation_sql 
set target_sql = 'select 59'
where validation_sql_desc  = 'tpolicy_transaction - LUX - collection_class_type_sk = 0' ;

update edw_core.tvalidation_sql 
set target_sql = 'select 35'
where validation_sql_desc  = 'tauto_vehicle - duplicate vehicle VIN' ;

update edw_core.tvalidation_sql 
set target_sql = 'select 4'
where validation_sql_desc  = 'tpolicy - incorrect uw_company_nm and program_type' ;

update edw_core.tvalidation_sql 
set target_sql = 'select 1'
where validation_sql_desc  = 'tcollection_class_type - missing transactions' ;

update edw_core.tvalidation_sql 
set target_sql = 'select 40'
where validation_sql_desc  = 'tpolicy_transaction - item_sk= 0 for AU' ; 

update edw_core.tvalidation_sql 
set target_sql = 'select 217'
where validation_sql_desc  = 'tpolicy - billingaccount_sk = 0'; 

update edw_core.tvalidation_sql 
set active_in = 'N'
where validation_sql_desc  = 'Metal Validation - AccountTransactionVersionObjectField - Bad data like value';

update edw_core.tvalidation_sql 
set active_in = 'N'
where validation_sql_desc  = 'Metal Validation - AccountobjectField - Bad data like value or NaN';
	   