update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tpel_coverage';
select * from [edw_core].[tpel_coverage];
select count(1) from [edw_core].[tpel_coverage];
truncate table [edw_core].[tpel_coverage];
EXEC [edw_core].[sp_tpel_coverage];


update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_coverage';
select * from [edw_core].[tquote_pel_coverage];
select COUNT(1) from [edw_core].[tquote_pel_coverage];
truncate table [edw_core].[tquote_pel_coverage];
EXEC [edw_core].[sp_tquote_pel_coverage];


update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_pel_coverage_wip';
select * from [edw_core].[tquote_pel_coverage];
select COUNT(1) from [edw_core].[tquote_pel_coverage];--4613
truncate table [edw_core].[tquote_pel_coverage];
EXEC [edw_core].[sp_tquote_pel_coverage_wip];



--Normal Tables
-- select acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group], acctvof.[Value], count(1)
select distinct acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group]
-- select *
from edw_stage.AccountTransactionVersionObject as acctvo
inner join edw_stage.AccountTransactionVersionObjectField as acctvof
on acctvof.VersionObjectId = acctvo.Id
where 1=1
-- and acctvof.field like '%SDIPPoints%'
-- and acctvof.label like '%xcess%'
-- and [Group] in ('Location Details')
-- and acctvo.ObjectType IN ('PersonalExcessLiability','Location')
and acctvof.Field in (
					'CoverageLimitDeductible'
                    ,'AdditionalCoverageLimitDeductible'
                    ,'UnderinsuredMotoristDeductible'
                    ,'UnderinsuredDeductible'
                    ,'EmploymentPracticesLiabilityDeductible'
                    ,'AutoInsuranceCompany'
                    ,'HomeInsuranceCompany'
				)
-- group by acctvof.Field, acctvof.label, acctvo.ObjectType, acctvof.[Group], acctvof.[Value]
;


select distinct
    coverage_deductible_amt,
    additional_coverage_deductible_amt,
    underinsured_motorist_deductible_amt,
    underinsured_deductible_amt,
    employment_practices_liability_deductible_amt,
    current_underlying_auto_insurance_company_nm,
    current_underlying_home_insurance_company_nm
from [edw_core].[tpel_coverage]
where 1 = 0
or coverage_deductible_amt is not null
or additional_coverage_deductible_amt is not null
or underinsured_motorist_deductible_amt is not null
or underinsured_deductible_amt is not null
or employment_practices_liability_deductible_amt is not null
or current_underlying_auto_insurance_company_nm is not null
or current_underlying_home_insurance_company_nm is not null
;

select distinct
    coverage_deductible_amt,
    additional_coverage_deductible_amt,
    underinsured_motorist_deductible_amt,
    underinsured_deductible_amt,
    employment_practices_liability_deductible_amt,
    current_underlying_auto_insurance_company_nm,
    current_underlying_home_insurance_company_nm
from [edw_core].[tquote_pel_coverage]
where 1 = 0
or coverage_deductible_amt is not null
or additional_coverage_deductible_amt is not null
or underinsured_motorist_deductible_amt is not null
or underinsured_deductible_amt is not null
or employment_practices_liability_deductible_amt is not null
or current_underlying_auto_insurance_company_nm is not null
or current_underlying_home_insurance_company_nm is not null
;

