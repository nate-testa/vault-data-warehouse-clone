select * from edw_core.tetl_audit where process_nm like '%sp%' order by etl_audit_sk desc;


--tpel_coverage
select count(1), max(transaction_dt) from [edw_core].[tpel_coverage];
select * from [edw_core].[tpel_coverage];
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tpel_coverage');
truncate table [edw_core].[tpel_coverage];
EXEC [edw_core].[sp_tpel_coverage];
select * from [edw_core].[tpel_coverage]
where [excess_coverage_premium_adjustment_method] is not null 
    or [excess_coverage_premium_adjustment_factor] is not null 
    or [excess_coverage_premium_adjustment_retention] is not null 
    or [excess_coverage_premium_adjustment_retention_reason] is not null 
;

--tquote_pel_coverage
select count(1) from [edw_core].[tquote_pel_coverage];
select * from [edw_core].[tquote_pel_coverage];
update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tquote_pel_coverage');
truncate table [edw_core].[tquote_pel_coverage];
EXEC [edw_core].[sp_tquote_pel_coverage];
EXEC [edw_core].[sp_tquote_pel_coverage_wip];
select * from [edw_core].[tquote_pel_coverage]
where [excess_coverage_premium_adjustment_method] is not null 
    or [excess_coverage_premium_adjustment_factor] is not null 
    or [excess_coverage_premium_adjustment_retention] is not null 
    or [excess_coverage_premium_adjustment_retention_reason] is not null 
;


--########################
--## Check Foreing Keys ##
--########################
SELECT 
    OBJECT_NAME(f.parent_object_id) AS 'Main Table',
    OBJECT_NAME (f.referenced_object_id) AS 'Secondary Table',
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS 'Column in Main Table',
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS 'Column in Secondary Table'
FROM 
    sys.foreign_keys AS f
INNER JOIN 
    sys.foreign_key_columns AS fc ON f.object_id = fc.constraint_object_id
WHERE 
    f.referenced_object_id = OBJECT_ID('edw_core.tquote_collection_class_type')
;

with acctvpf AS (
            SELECT  
                acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.policychangenumber, field,
                acctvpf.AccountTransactionVersionPremiumId,
                acctvpf.Coverage,
                CONCAT(
                    CASE 
                        WHEN Coverage = 'Excess Liability' THEN 'excess_coverage'
                        ELSE LOWER(REPLACE(Coverage,' ','_'))
                    END
                    ,'_premium_adjustment'
                ) AS FinalColumnName,
                acctvpf.FactorMethod AS method,
                CONVERT(nvarchar(3000), acctvpf.Factor) AS amount,
                acctvpf.Retention AS [retention],
                acctvpf.Reason AS reason
            FROM [edw_stage].[AccountTransaction] AS acct
            INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
            INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
            INNER JOIN [edw_stage].[AccountTransactionVersionPremium] AS acctvp ON acctv.id = acctvp.AccountTransactionVersionId
            INNER JOIN [edw_stage].[AccountTransactionVersionPremiumFactor] AS acctvpf ON acctvp.id = acctvpf.AccountTransactionVersionPremiumId
            WHERE acct.[State] = 'ISSUED'
			AND acct.PolicyNumber IS NOT NULL
            -- AND acct.IssuedDate > @last_source_extract_ts
			AND acctvpf.Coverage IN ('Excess Liability')
            AND p.[Name] = 'Personal Excess Liability'
            AND p.ProductLine = 'PersonalLines'
			AND acctvpf.field = 'Adjustment'
			AND acctvpf.FactorMethod <> 'None'
        )

select distinct field, FinalColumnName from acctvpf
;

select field,			FactorMethod from [edw_stage].[AccountPremiumFactor];