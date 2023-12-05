select 
commission_statement_email  as 'Email',
NULL as 'billing_admin_name',
broker_id as 'agency_code',
broker_nm as ' agency_name',
primary_address_city_nm as 'agency_city',
primary_address_state_cd  as 'agency_state',
NULL as 'Status'
from vault_edw.edw_core.tbroker
--where broker_id = 56512



