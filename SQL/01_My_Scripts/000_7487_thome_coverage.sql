select top 100 * from edw_core.tetl_audit where process_nm like '%thome_coverage%' order by etl_audit_sk desc;
update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_thome_coverage';
truncate table [edw_core].[thome_coverage];
EXEC [edw_core].[sp_thome_coverage];
select count(1) from [edw_core].[thome_coverage];
select top 100 
facultative_reinsurance_in,layered_limits_in,[100_pc_dwelling_limit_value_amt],[100_pc_other_structures_limit_value_amt],[100_pc_contents_limit_value_amt],[100_pc_loss_of_use_value_amt],
				facultative_attachment_point,facultative_limit_amt,facultative_ceded_premium_amt,facultative_reinsurer_nm,coverage_layer,coverage_layer_placed_pc,coverage_layer_limit_amt,
				newly_purchased_home_in,target_closing_dt,current_policy_anniversary_dt,current_underlying_company_nm,new_client_for_agency_in
from [edw_core].[thome_coverage];