INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal validation - invalid created/bound/issued userid' AS validation_sql_desc ,
     'select count(*) from edw_stage.AccountTransaction where IssuedByUserId is not null and cast(CreatedDate as date)>''20250702''
		and ((CreatedById=''00000000-0000-0000-0000-000000000000'') OR (BoundByUserId=''00000000-0000-0000-0000-000000000000'') or
		(IssuedByUserId=''00000000-0000-0000-0000-000000000000''))' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;