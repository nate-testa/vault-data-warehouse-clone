INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Current Carrier  NP01- Missing required fields' ,
'select count(*) 
from edw_integration.policy_current_carrier_auto_np01_feed pccanf 
where 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''')= '''' OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyName)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyType)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(NAICCode)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyInceptionDate)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyPeriodEndDate)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyPeriodBeginDate)),'''')  = '''' OR
ISNULL(LTRIM(RTRIM(PolicyHolderMailAddressStreetName)),'''')  = '''' OR
ISNULL(LTRIM(RTRIM(PolicyHolderMailAddressCity)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyHolderMailAddressState)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyHolderMailAddressZip)),'''')  = ''''
)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
SELECT
'Current Carrier  PR01- Missing required fields' ,
'select count(* )
from edw_integration.policy_current_carrier_auto_PR01_feed pccapf 
where 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(VIN)),'''') = ''''
)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
UNION
   SELECT
'Current Carrier SJ01- Missing required fields' ,
'select COUNT(*)
from 
edw_integration.policy_current_carrier_auto_SJ01_feed pccasf 
where 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''') =  ''''  OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''') =  ''''  OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''')=  ''''  OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''') =  ''''  OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''') =  ''''  OR 
ISNULL(LTRIM(RTRIM(RelationshipToPolicyHolder)),'''')=  ''''  OR 
ISNULL(LTRIM(RTRIM(NameLast)),'''')=  ''''  OR 
ISNULL(LTRIM(RTRIM(NameFirst)),'''') =  ''''  OR 
ISNULL(LTRIM(RTRIM(DOB)),'''') =  '''' 
)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts

UNION


SELECT
'Current Carrier VR01- Missing required fields' ,
'select  count(*) 
from edw_integration.policy_current_carrier_auto_vr01_feed pccavf 
WHERE 
(
ISNULL(LTRIM(RTRIM(RecordCode)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(ContribCompanyAMBestNumber)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(PolicyNumber)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(InsuranceType)),'''')  = '''' OR 
ISNULL(LTRIM(RTRIM(ChangeEffectiveDate)),'''')  = '''' OR
ISNULL(LTRIM(RTRIM(VIN)),'''') = '''' OR 
ISNULL(LTRIM(RTRIM(VehicleAddDate)),'''') = ''''
)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
  union  
SELECT
'Current Carrier SJ01- Policies having no A1 record  ' ,
'select count(*)
from
(select SUM(case when RelationshipToPolicyHolder = ''A1'' THEN 1 ELSE 0 END) as ct
from edw_integration.policy_current_carrier_auto_sj01_feed
group by policy_history_sk
having SUM(case when RelationshipToPolicyHolder = ''A1'' THEN 1 ELSE 0 END)=0
) as a
' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
 union  
SELECT
'Current Carrier NP01- States outside the USA ' ,
'select  count(*) from edw_integration.policy_current_carrier_auto_np01_feed
where PolicyHolderMailAddressState not in(select state_cd from edw_core.tstate)' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;