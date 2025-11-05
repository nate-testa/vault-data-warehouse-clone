-- *** sp_thome_coverage
select top 10 * from edw_core.tetl_audit where process_nm = 'sp_thome_coverage' order by etl_audit_sk desc;
select * from edw_core.tetl_control where process_nm in ('sp_thome_coverage','sp_thome_additional_coverage');
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_thome_coverage','sp_thome_additional_coverage');
-- EXEC sp_help '[edw_core].[thome_coverage]';
-- EXEC sp_help '[edw_core].[tquote_home_coverage]';

DELETE FROM [edw_core].[thome_additional_coverage];
DELETE FROM [edw_core].[thome_coverage];

SELECT COUNT(1) FROM [edw_core].[thome_coverage];
SELECT COUNT(1) FROM [edw_core].[thome_additional_coverage];

SELECT top 100 * FROM [edw_core].[thome_coverage];
SELECT top 100 * FROM [edw_core].[thome_additional_coverage];

-- EXEC [edw_core].[sp_thome_coverage];
EXEC [edw_core].[sp_thome_additional_coverage];


-- last_source_extract_ts >2025-10-02 00:02:58.1898559 AND last_source_extract_ts <=2025-10-02 15:11:18.9389124

-- Error Number:515 Error State:2 Error Severity:16 Error Procedure:edw_core.sp_thome_coverage Error Line:164 Error Message:Cannot insert the value NULL into column 'policy_history_sk', table 'vault_edw.edw_core.thome_coverage'; column does not allow nulls. INSERT fails.
-- Error Number:245 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_thome_coverage Error Line:164 Error Message:Conversion failed when converting the nvarchar value 'No Response' to data type int.

-- TRUNCATE TABLE [edw_core].[tquote_home_coverage];
SELECT COUNT(1) FROM [edw_core].[tquote_home_coverage];
SELECT top 10 * FROM [edw_core].[tquote_home_coverage];
-- EXEC [edw_core].[sp_tquote_home_coverage];

----------------------------------------------------------------------------

select premium_analytics_grade, count(1) rc
from edw_core.thome_coverage tc
group by premium_analytics_grade
;


select policy_no , premium_analytics_grade
from edw_core.thome_coverage tc
where policy_no = 'HO200039227'
;


with thome_coverage_temp1 as (
    select act.*
    from
        edw_stage.AccountTransaction act
        inner join edw_stage.Product p on p.Id=act.ProductId
    where
        act.PolicyNumber = 'HO200039227'
        and act.[State] ='ISSUED'	
        and p.ProductLine = 'PersonalLines'
        -- and act.IssuedDate > @last_source_extract_ts
)
select * 
from
(
select ROW_NUMBER()over(partition by act.PolicyNumber ,act.EffectiveDate ,act.PolicyChangeNumber  order by pofv.[version] desc ) as rn,
act.PolicyNumber ,act.EffectiveDate ,act.PolicyChangeNumber as transaction_seq_no,
pofv.ValueDisplay as [Value]
,acc.PremiumAnalyticsGrade as premium_analytics_grade
from
    thome_coverage_temp1 act
    inner join edw_stage.Account acc on acc.PolicyNumber = act.PolicyNumber and acc.EffectiveDate = act.EffectiveDate
    inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId    
    inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
    inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId 
    left join
    (
            SELECT *
            FROM edw_stage.ProductObjectFieldValueDisplay
            WHERE
            Field = 'RoofDeckAttachment'
        
    ) AS pofv ON atvof.Field=pofv.Field and act.ProductId = pofv.ProductId and atvo.ObjectType = pofv.ObjectType
        and  atv.RiskStateCode=pofv.statecode and atvof.[Value] = pofv.[Value]
        and act.EffectiveDate between pofv.EffectiveDate and isnull(pofv.ExpirationDate,'2099-01-01')
        and pofv.IsRenewal = acc.IsRenewal
where   
    atvo.ObjectType in ('Homeowner','Condo','Inspection')
    and atvof.Field= 'RoofDeckAttachment'
    and isnull(atvof.[Value],'')  != ''
) as a
where
    rn = 1
;


select atvo.*
from edw_stage.AccountTransaction act
inner join edw_stage.Product p on p.Id=act.ProductId
inner join edw_stage.Account acc on acc.PolicyNumber = act.PolicyNumber and acc.EffectiveDate = act.EffectiveDate
inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId    
inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId 
where act.PolicyNumber = 'HO200039227'
and atvo.ObjectType in ('Homeowner','Condo','Inspection')
and atvof.Field= 'RoofDeckAttachment'
and isnull(atvof.[Value],'')  != ''
;

select AccountId, count(1) rc from edw_stage.AccountTransactionVersion group by AccountId having count(1) > 1;





