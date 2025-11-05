select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_tpel_location');
update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tpel_location');
-- EXEC sp_help '[edw_core].[sp_tpel_location]';

-- TRUNCATE TABLE [edw_core].[tpel_location];

SELECT COUNT(1) FROM [edw_core].[tpel_location];

SELECT top 1000 * FROM [edw_core].[tpel_location];


-- EXEC [edw_core].[sp_tpel_location];

----------------------------------------------------------------------------


-- ,CASE WHEN atvo.IsdeletedOnPolicyChange = 1 THEN 'Yes' ELSE 'No' END as location_deleted_in
-- inner join edw_stage.AccountTransactionVersionObject atvo

drop table if exists edw_temp.tpel_location_temp1
select 
    PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,source_system_sk,policy_history_sk,
    rownum as [index],
    IssuedDate,AddressLine1,AddressLine2,AddressCity,AddressState,AddressZipCode,AddressCounty,AddressCountry,
    NumberOfSwimmingPools,MultiFamilyDwelling,VacantOrUnoccupied,ForSale,
    SquareFootage,NumberofAthleticStructures,ShortTermRental,LongTermRental,LocationsLimitsIndicator,primary_location_in
    ,location_deleted_in
    into edw_temp.tpel_location_temp1
from
(
select * 
from
    (
    -- We are generating rownum becase atvo.[index] is 1 for every row of a policy and we are using it as location_no but we should 
    -- have different location_no for different location of a policy number.
    -- This rownum is used as location no
    select
    DENSE_RANK()OVER(PARTITION BY act.PolicyNumber, CAST(act.EffectiveDate AS DATE), act.policychangenumber ORDER BY atvo.Id) as rownum,
    act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
    CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.policy_history_sk,
    CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
    act.policychangenumber AS transaction_seq_no, act.IssuedDate as TransactionDate,atvo.[index],
    act.IssuedDate,atvof.Field,atvof.[Value] -- ,atvo.Id
    ,CASE WHEN atvof_2.Field = 'PrimaryLocationId' THEN 'Yes' ELSE 'No' END AS primary_location_in
    ,CASE WHEN atvo.IsdeletedOnPolicyChange = 1 THEN 'Yes' ELSE 'No' END as location_deleted_in
    from
        edw_stage.AccountTransaction act
        inner join edw_stage.Product p on p.Id=act.ProductId
        inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
        inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
        inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
        left join edw_stage.AccountTransactionVersionObjectField atvof_2 on atvof_2.ReferenceObjectId = atvo.id and atvof_2.Field = 'PrimaryLocationId'
        left join [edw_core].[tpolicy_history] tph on tph.policy_no=act.PolicyNumber
                and tph.effective_dt=act.EffectiveDate
                and tph.transaction_seq_no = act.policychangenumber
        left join edw_stage.Product pr on act.ProductId = pr.id
    where
    act.PolicyNumber is not null and
        act.[State] ='ISSUED'
        and p.[Name]='Personal Excess Liability'
        and pr.ProductLine = 'PersonalLines'
        and atvo.ObjectType='Location'
        and atvof.Field IN 
        (
            'AddressLine1','AddressLine2','AddressCity','AddressState','AddressZipCode','AddressCounty',
            'AddressCountry','NumberOfSwimmingPools','MultiFamilyDwelling','VacantOrUnoccupied','ForSale',
            'SquareFootage','NumberofAthleticStructures','ShortTermRental','LongTermRental','LocationsLimitsIndicator'
        )
        -- and act.IssuedDate > @last_source_extract_ts
    ) as t
) as t
pivot 
(
    max(Value) FOR Field IN (NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
            IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,
            AddressState,AddressZipCode,AddressCounty,AddressCountry,NumberOfSwimmingPools,MultiFamilyDwelling,
            VacantOrUnoccupied,ForSale,SquareFootage,NumberofAthleticStructures,ShortTermRental,LongTermRental,LocationsLimitsIndicator)
) as pivottable
;

SELECT location_deleted_in, COUNT(1) FROM edw_temp.tpel_location_temp1 GROUP BY location_deleted_in;