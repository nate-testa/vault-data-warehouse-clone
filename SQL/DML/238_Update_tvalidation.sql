update edw_core.tvalidation_sql
set
	source_sql = 
	'select count(*) from edw_integration.policy_current_carrier_auto_np01_feed  
	where PolicyHolderMailAddressState not in(select state_cd from edw_core.tstate) 
	and PolicyHolderMailAddressState!=''YY''
	'
where validation_sql_desc = 'Current Carrier NP01- States outside the USA'