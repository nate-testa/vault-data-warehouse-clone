INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Clue Auto - null values' AS validation_sql_desc ,
'SELECT count(*) FROM edw_integration.claim_clue_auto_feed
WHERE
LTRIM(RTRIM(PolicyHolderMailAddressStreetName)) = '''' OR
LTRIM(RTRIM(PolicyHolderMailAddressCity)) = '''' OR
LTRIM(RTRIM(PolicyHolderMailAddressState)) = '''' OR
LTRIM(RTRIM(PolicyHolderMailAddressZip)) = '''' OR   
LTRIM(RTRIM(policyHolderNameFirst)) = '''' OR    
LTRIM(RTRIM(policyHolderNameLast)) = '''' OR
LTRIM(RTRIM(claimReportingStatus)) = '''' OR
LTRIM(RTRIM(claimAmount)) = '''' OR
LTRIM(RTRIM(claimtype)) = '''' OR
LTRIM(RTRIM(policyNumber)) = '''' OR
LTRIM(RTRIM(policyType)) = '''' OR
LTRIM(RTRIM(contribCompany)) = '''' OR
LTRIM(RTRIM(claimNumber)) = '''' OR
claimAmount LIKE ''%-%'''
        AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts; 