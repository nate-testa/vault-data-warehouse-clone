INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Inforce count mismatch between Hubspot and tdaily_inforce_policy' ,
'select count(*)
from edw_core.tdaily_inforce_policy inf
        inner join edw_core.tpolicy pol on inf.policy_sk = pol.policy_sk
        inner join edw_core.tcustomer cust on cust.customer_id = pol.customer_id
        inner join edw_core.tdate td on inf.inforce_dt_sk = td.date_sk and actual_dt = DATEADD(day, -1, cast(getdaTE() as date))
where ((
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
		))' AS source_sql ,
       'select  count(*)
from edw_integration.customer_hubspot_feed
where policy_inforce_in = ''Yes''' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;