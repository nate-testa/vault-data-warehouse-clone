ALTER TABLE edw_core.tpel_coverage ADD coverage_deductible_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD additional_coverage_deductible_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD underinsured_motorist_deductible_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD underinsured_deductible_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD employment_practices_liability_deductible_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD current_underlying_auto_insurance_company_nm varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD current_underlying_home_insurance_company_nm varchar(255);