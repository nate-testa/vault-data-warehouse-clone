INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'CLUE Property feed validation - loss paid amount mismatch' AS validation_sql_desc ,
       'with clue_claim as
( 
SELECT * FROM 
(
select claimNumber,claimAmount,CAST(CAST(claimAmount AS INT) / 100.0 AS DECIMAL(15,2)) AS clue_loss_paid
,ROW_NUMBER() over (partition by claimNumber order by create_ts desc) AS RNK from edw_integration.claim_clue_property_feed 
where claimReportingStatus=''A''
)A
WHERE A.RNK=1
),
edw_claim as
(
SELECT claim_sk,claim_no, claim_status,sum(loss_paid_amt+expense_paid_amt+defense_paid_amt+overpayment_recovery_amt+overpayment_expense_recovery_amt+overpayment_defense_recovery_amt) as edw_loss_paid
FROM edw_core.tclaim cl
where source_system_sk!=1 and product_sk in (1,2,5) and exists (select * from edw_core.tclaim_transaction ct where cl.claim_sk=ct.claim_sk)
and policy_no in (
    select policy_no from edw_stage.OneShieldPolicy_clue 
    union 
    select policy_no from edw_core.tpolicy
    union
    select policy_no from edw_core.thome_location
    union
    select policy_no from edw_core.tcollection_location
) 
group by claim_sk,claim_no,claim_status
)
select claim_sk,b.claim_no,claim_status,a.clue_loss_paid, b.edw_loss_paid into #temp1 
from  edw_claim b left join clue_claim  a on 
 a.claimNumber=b.claim_no where isnull(a.clue_loss_paid,99999999999)!=b.edw_loss_paid and claim_no not in (''C24HOA00377'',''C24HOA00323'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;


INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'CLUE Property feed validation - invalid format data' AS validation_sql_desc ,
       'select * from edw_integration.claim_clue_property_feed where 
trim(riskAddressStreetName)='' or trim(riskAddressState)='' or trim(riskAddressZip)='' or trim(riskAddressCity)=''
or trim(policyHolderNameFirst)='' or trim(policyHolderNameLast)='' or trim(claimReportingStatus)=''
or trim(claimAmount)='' or trim(causeOfLoss)='' or trim(policyNumber)='' or trim(policyType)=''
or trim(contribCompany)='' or trim(claimNumber)='' or claimAmount like ''%-%''' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;