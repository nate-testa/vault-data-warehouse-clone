--Control tables
select * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
select * from edw_core.tetl_control where process_nm like '%clue%';
select * from edw_core.tedw_table_detail where table_nm like '%ivans%';



/*
removed duplicate     Product joins
 select
            act.PolicyNumber as quote_no,act.EffectiveDate ,act.ExpirationDate ,act.TransactionEffectiveDate ,
            --tqh.quote_history_sk,thql.quote_home_location_sk,
            0 as transaction_seq_no,act.CreatedDate, p.name product_name,
            CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value],
            atvpf.FactorMethod, atvpf.Factor, atvpf.Retention, atvpf.Reason
           from
                dbo.Account act --> Replace accounttransaction with this
                inner join dbo.Product p on p.Id=act.ProductId
                inner join dbo.AccountObject atvo on atvo.AccountId=act.id --> Accounttransactionversionobject
                left join dbo.Accountpremium ap on ap.AccountId=act.id -->
                left join dbo.AccountPremiumCoverage atvp on atvp.AccountPremiumId=ap.id --> Accounttransactionversioncoveragepremium
                left join dbo.AccountPremiumfactor atvpf on atvpf.AccountPremiumId=ap.id and atvpf.coverage = 'Homeowners'
                inner join dbo.AccountObjectField atvof on atvof.ObjectId=atvo.id -->AccountTransactionVersionObjectField
           --     left join edw_core.tquote_history tqh on tqh.quote_no=act.PolicyNumber and tqh.effective_dt=act.EffectiveDate and tqh.transaction_seq_no = act.[Number]
            --    left join edw_core.tquote_home_location thql on thql.quote_no=act.PolicyNumber                      
             --   left join dbo.Product pr on act.ProductId = pr.id
            where
                act.PolicyNumber is not null --and
                --act.[Stage] IN ('QUOTE')
                and atvo.ObjectType in ('Homeowner','Condo','Inspection')
                and p.ProductLine = 'PersonalLines'
                and not exists (select * from dbo.AccountTransaction actr where actr.AccountId=act.id)
                and act.PolicyNumber='HO200029044'
                and greatest(act.CreatedDate,act.UpdatedDate)>@last_source_extract_ts
*/

-- [AccountTransaction] -> [Account]
-- [AccountTransactionVersion] -> delete this join
-- [AccountTransactionVersionObject] -> [AccountObject] : acctvo -> acco
-- [AccountTransactionVersionObjectField] -> [AccountObjectField] : acctvof -> accof
-- [tquote_history]

/* ****--changes
--Replace this
(
    SELECT
        *
    FROM [edw_stage].[AccountTransaction]
    WHERE Stage in ('QUOTE','POLICY')
        AND CreatedDate > @last_source_extract_ts
) acct
--Using this
(
    SELECT *
    FROM [edw_stage].[Account] AS a
    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
) acc

--Delete this join
INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id

--Replace this
[edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
--Using this
[edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id

--Replace this
[edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
--Using this
[edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id

--Replace this
[edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
--Using this
[edw_stage].[AccountPremium] AS accp ON accp.AccountId = acc.id

--Replace this
[edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
--Using this
[edw_stage].[AccountPremiumFactor] AS accpf ON accpf.AccountPremiumId = accp.id


--set transaction_seq_no as -> 0: 0 as transaction_seq_no

--Replace this
acct.
--Using this
acc.

--Replace this
acctvo.
--Using this
acco.

--Replace this
acctvof.
--Using this
accof.

--Replace this
acctvp.
--Using this
accp.

--Replace this
acctvpf.
--Using this
accpf.

--Create Merge sentence


*/



select top 10 * from [edw_stage].[AccountTransactionVersion];

select top 10 * from [edw_stage].[Account];
select top 10 * from [edw_stage].[AccountObject];

EXEC edw_core.sp_tquote_auto_vehicle_wip;--ok
EXEC edw_core.sp_tquote_auto_driver_wip;
EXEC edw_core.sp_tquote_auto_driver_incident_wip;
EXEC edw_core.sp_tquote_auto_garage_location_wip;
EXEC edw_core.sp_tquote_auto_policy_coverage_wip;
EXEC edw_core.sp_tquote_auto_vehicle_coverage_wip;
EXEC edw_core.sp_tquote_auto_vehicle_coverage_rapa_wip;--ok


SELECT count(1) FROM [edw_stage].[Account] where PolicyNumber is null;