insert into edw_stage.coverage_mapping_snapsheet
(
product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,
create_ts,update_ts
)
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'hull_value_limit_amt' as column_nm,
'Hull Value' as snapsheet_coverage_nm,'HUV' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union

select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'liability_limit_amt' as column_nm,
'Liability' as snapsheet_coverage_nm,'LIABI' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'medical_payments_limit_amt' as column_nm,
'Medical Payments' as snapsheet_coverage_nm,'MDPY' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'opa_pollution_liability_limit_amt' as column_nm,
'OPA Pollution' as snapsheet_coverage_nm,'OPP' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'personal_effects_limit_amt' as column_nm,
'Personal Effects' as snapsheet_coverage_nm,'PEF' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts
union
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'theft_deductible' as column_nm,
'Theft' as snapsheet_coverage_nm,'THF' as snapsheet_coverage_cd,'Deductible' as coverage_type,'theft' as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts

union
select 'Marine Boat & Yacht' as product_nm, 'tmarine_boat_yacht_coverage' as table_nm, 'uninsured_boater_limit_amt' as column_nm,
'Uninsured Boater' as snapsheet_coverage_nm,'UB' as snapsheet_coverage_cd,'Limit' as coverage_type,null as snapsheet_deductible_type,getdate() as create_ts,getdate() as update_ts