update edw_stage.coverage_mapping_snapsheet
set snapsheet_coverage_nm = 'Not needed for day 1',
snapsheet_coverage_cd = null,
snapsheet_deductible_type = null
where product_nm = 'Marine Boat & Yacht' 
and snapsheet_coverage_nm = 'Theft' ; 