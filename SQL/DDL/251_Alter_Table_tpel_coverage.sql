ALTER TABLE edw_core.tpel_coverage ADD secondary_insured_coverage_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD underinsured_motorist_liability_for_secondary_insured_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD defense_inside_limits_in varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD auto_liability_exclusion_in varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD auto_underlying_limit_type varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD auto_underlying_limit_per_occurence_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD auto_underlying_limit_for_property_damage_amt varchar(255);
ALTER TABLE edw_core.tpel_coverage ADD home_underlying_limit_amt varchar(255);