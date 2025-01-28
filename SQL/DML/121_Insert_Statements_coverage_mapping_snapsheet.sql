DELETE FROM edw_stage.coverage_mapping_snapsheet ; 

INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Auto','tauto_policy_coverage','accidental_death_benefit_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','added_first_party_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','bodily_injury_limit_amt','Split Limits','SPL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combination_fpb_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combined_single_limit_amt','Combined Single Limits','CSL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combined_um_bi_policy_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combined_um_pd_policy_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combined_underinsured_motorist_limit_amt','Underinsured Motorist Liablity','UIM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','combined_uninsured_motorist_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','extended_medical_limit_amt','Medical Payments','MEDP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Auto','tauto_policy_coverage','extraordinary_medical_benefits_limit_amt','Medical Payments','MEDP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','funeral_expense_benefit_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','medical_payment_limit_amt','Medical Payments','MEDP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','permissive_driver_unique_bi_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','permissive_driver_unique_combined_single_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','permissive_driver_unique_pd_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','physical_damage_deductible_adjustment','Not needed for day 1',NULL,'Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','pip_deductible','PIP','PIP','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','pip_limit_amt','PIP','PIP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','property_damage_limit_amt','PD Liability Limit','PDL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Auto','tauto_policy_coverage','transportation_expense_daily_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','um_bi_policy_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','um_pd_policy_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','underinsured_motorist_limit_amt','Underinsured Motorist Liablity','UIM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','uninsured_motorist_deductible','Uninsured Motorist Liablity','UM','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','uninsured_motorist_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_policy_coverage','work_loss_benefit_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','collision_deductible','Collisio','COL','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','extended_towing_and_labor_i','Roadside Assistance','RDS','Indicator',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','full_glass_coverage_i','Full Glass','GLS','Indicator',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Auto','tauto_vehicle_coverage','motorcycle_med_limit_amt','Medical Payments','MEDP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','otc_deductible','Comprehensive','COMP','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','umpd_deductible','Uninsured Motorist Liablity','UM','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Auto','tauto_vehicle_coverage','umpd_limit_amt','Uninsured Motorist Liablity','UM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_class_type','blanket_limit_amt','Collections - Blanket Limit','COBL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_class_type','scheduled_limit_amt','Collections - Scheduled','COSC','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_coverage','coverage_deductible_amt','Collections - Blanket Limit/Collections - Scheduled',NULL,'Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_coverage','earthquake_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_coverage','earthquake_deductible_loss_limitations_limit','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_coverage','hurricane_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Collections','tcollection_coverage','transit_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_coverage','wildfire_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Collections','tcollection_scheduled_item','coverage_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','additional_coverage_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','coverage_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','do_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','employment_practices_liability_amt','Employment Practices Liability','EMPL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','employment_practices_liability_deductible_amt','Employment Practices Liability','EMPL','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','home_underlying_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','pel_limit_amt','Excess liability','EXL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Excess','tpel_coverage','underinsured_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','underinsured_motorist_deductible_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','uninsured_underinsured_liability_amt','UM/UIM Liability','EXUM','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Excess','tpel_coverage','uninsured_underinsured_motorist_liability_amt','UM/UIM Motorist Liability','EXUMOT','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','business_property_increase_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','contents_extended_replacement_cost_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','coverage_for_piers_wharves_and_docks_due_to_weight_of_ice_or_snow_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','damage_to_property_of_others_increased_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','deductible_waiver_large_losses_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','earthquake_coverage_extension_deductible','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Home/Condo','thome_additional_coverage','earthquake_coverage_extension_loss_assessment_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','earthquake_endorsement_deductible','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','escaped_liquid_fuel_liability_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','escaped_liquid_fuel_remediation_liability_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','fungi_bacteria_increase_limit','Fungi or Bacteria Extensio','FNG','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','home_cyber_protection_coverage_deductible','Home Cyber Protectio','CYB','Deductible',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','home_cyber_protection_coverage_limit_amt','Home Cyber Protectio','CYB','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','home_daycare_coverage_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','home_systems_protection_limit_amt','Home Systems Protectio','HSP','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','increased_incidental_business_property_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Home/Condo','thome_additional_coverage','increased_incidental_business_threshold_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','landscaping_coverage_increased_plant_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','landscaping_coverage_sleet_and_weight_of_ice_and_snow_coverage_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','landscaping_coverage_wind_and_hail_coverage_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','loss_assessment_increase_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','matching_undamaged_property_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','mine_subsidence_coverage_limit_amt','Mine Subsidence','MSB','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','serviceline_protection_i','Service Line Protectio','SLP','Indicator',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','dwelling_limit_amt','Sewers and Drains Limitatio','SDL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','other_structures_on_the_residence_premises_increased_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Home/Condo','thome_additional_coverage','screen_enclosure_limit_amt','Screen Enclosure','SE','Limit',NULL,'2024-10-15 19:00:42.977','2024-11-13 18:48:14.050'),
	 ('Home/Condo','thome_additional_coverage','waterdamage_limitation_endorsement_limit_amt','Water Damage limitatio','WDL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','waterdamage_sublimit_amt','Water Damage limitatio','WDL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_additional_coverage','workercompensation_liability_occurance_limit_amt','Workers compensatio','WC','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','aop_deductible','AOP Deductible','AOP','Deductible','base','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','aop_deductible_manual','AOP Deductible Manual','AOPM','Deductible','base','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','contents_limit_amt','Contents','COV-C','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','dwelling_limit_amt','Dwelling','COV-A','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','hurricane_deductible','Hurricane Deductible','HD','Deductible','annual_hurricane','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','hurricane_or_named_storm_deductible','Hurricane or Named Storm Deductible','HNSD','Deductible','named_storm','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Home/Condo','thome_coverage','COALESCE(loss_of_use_limit_amt, loss_of_use_option)','Loss of use','COV-D','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','medical_payments_limit_amt','Medical payment','MEDPY','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','named_storm_deductible','Named Storm Deductible','NSD','Deductible','named_storm','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','other_structures_limit_amt','Other structures','COV-B','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','personal_liability_limit_amt','Personal Liability','LIAB','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','reinsurance_attachment_limit_amt','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','tornado_or_hailstorm_deductible','Tornado or Hailstorm Deductible','THD','Deductible','wind_hail','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','water_deductible','Water Deductible','WD','Deductible','flood','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','water_deductible_manual','Water Deductible Manual','WDM','Deductible','flood','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','wildfire_deductible','Wildfire Deductible','WLD','Deductible','theft','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
INSERT INTO edw_stage.coverage_mapping_snapsheet (product_nm,table_nm,column_nm,snapsheet_coverage_nm,snapsheet_coverage_cd,coverage_type,snapsheet_deductible_type,create_ts,update_ts) VALUES
	 ('Home/Condo','thome_coverage','wildfire_deductible_manual','Wildfire Deductible Manual','WLDM','Deductible','theft','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','wind_or_hailstorm_deductible','Wind or Hailstorm Deductible','WHD','Deductible','wind_hail','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('Home/Condo','thome_coverage','wind_or_hailstorm_deductible_manual','Wind or Hailstorm Deductible Manual','WHDM','Deductible','wind_hail','2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('NFP','nfp_policy','employment_practises_liability_coverage','Employment Practices Liability','EMPL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('NFP','nfp_policy','family_trust_management_liability_coverage','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('NFP','nfp_policy','group_excess_liability_coverage','Excess Liability ','EXL','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('NFP','nfp_policy','non_profit_d&o_liability_coverage','Not needed for day 1',NULL,'Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977'),
	 ('NFP','nfp_policy','uninsured_motorist_liability_coverage','UM/UIM Motorist Liability','EXUMOT','Limit',NULL,'2024-10-15 19:00:42.977','2024-10-15 19:00:42.977');
