INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
	'Metal Validation - Null state code in productobjectfieldvaluedisplay' AS validation_sql_desc ,
     'select count(*) from edw_stage.ProductObjectFieldValueDisplay where
	  Field in (''AdditionalPIP'',''BasicPIP'',''BILimit'',''DeductibleAppliesTo'',''UIMLimit'',''UMBIPolicyLimit'',''UMLimit'',''WorkLossExclusion'',''RoofDeckAttachment'') and StateCode = ''''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;