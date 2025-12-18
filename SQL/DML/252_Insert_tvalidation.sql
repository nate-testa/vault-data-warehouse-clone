INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Home location address having greater than 96 characters' ,
'SELECT count(*)
FROM edw_core.thome_location hl
WHERE LEN(
        ISNULL(address_line_1, '''') +
        ISNULL(address_line_2, '''') +
        ISNULL(unit_no, '''') +
        ISNULL(city_nm, '''') +
        ISNULL(state_cd, '''') +
        ISNULL(zip_cd, '''')
      ) > 96'  AS source_sql ,
       'select  0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;