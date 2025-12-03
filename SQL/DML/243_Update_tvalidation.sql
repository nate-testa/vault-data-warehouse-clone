update edw_core.tvalidation_sql
set
	source_sql = 
	'SELECT count(*) FROM edw_integration.claim_clue_auto_feed WHERE LTRIM(RTRIM(PolicyHolderMailAddressStreetName)) = '''' OR LTRIM(RTRIM(PolicyHolderMailAddressCity)) = '''' OR LTRIM(RTRIM(PolicyHolderMailAddressState)) = '''' OR LTRIM(RTRIM(PolicyHolderMailAddressZip)) = '''' OR    LTRIM(RTRIM(policyHolderNameFirst)) = '''' OR     LTRIM(RTRIM(policyHolderNameLast)) = '''' OR LTRIM(RTRIM(claimReportingStatus)) = '''' OR LTRIM(RTRIM(claimAmount)) = '''' OR (LTRIM(RTRIM(claimtype)) = '''' AND LTRIM(RTRIM(claimReportingStatus)) = ''A'') OR LTRIM(RTRIM(policyNumber)) = '''' OR LTRIM(RTRIM(policyType)) = '''' OR LTRIM(RTRIM(contribCompany)) = '''' OR LTRIM(RTRIM(claimNumber)) = '''' OR claimAmount LIKE ''%-%'''
	,update_ts = GETDATE()
where validation_sql_desc = 'Clue Auto - null values'
go