update edw_core.tvalidation_sql  
set source_sql = 'select count(*) from edw_core.tproducer    
where email in (select  email from edw_integration.producer_hubspot_feed where producer_status = ''Active'' group by email having count(*) > 1)',
validation_sql_desc ='tproducer - Duplicate email for Active producer'
where validation_sql_desc = 'tproducer - Duplicate producer email';