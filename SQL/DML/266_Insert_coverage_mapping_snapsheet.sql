insert into edw_stage.coverage_mapping_snapsheet
(
product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts
)
select 'Group Personal Excess Liability' as product_nm,	'tgrpel_coverage' as table_nm,'employment_practises_liability_limit_amt' as column_nm,'Employment Practices Liability' as snapsheet_coverage_nm,'EMPL' as snapsheet_coverage_nm,'Limit' as coverage_type,NULL as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Group Personal Excess Liability' as product_nm,	'tgrpel_coverage' as table_nm,'excess_liability_limit_amt' as column_nm,'Excess Liability' as snapsheet_coverage_nm,'EXL' as snapsheet_coverage_nm,'Limit' as coverage_type,	NULL as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Group Personal Excess Liability' as product_nm,	'tgrpel_coverage' as table_nm,'uninsured_motorist_liability_limit_amt' as column_nm,'UM/UIM Motorist Liability' as snapsheet_coverage_nm,'EXUMOT' as snapsheet_coverage_nm,'Limit' as coverage_type,NULL as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts