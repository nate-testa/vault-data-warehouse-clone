DELETE FROM [edw_stage].[migration_loss_type_mapping];

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_50', N'Vandalism', N'SCOL_XL_50_01', N'Vandalism', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_51', N'Wrongful Termination', N'SCOL_XL_51_01', N'Wrongful Termination', N'liability_claim_wrongful_termination',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_52', N'OV Driver DUI', N'SCOL_XL_52_01', N'OV Driver DUI', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_53', N'IV Struck By IV', N'SCOL_XL_53_01', N'IV Struck By IV', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_54', N'IV and OV Struck Simultaneously', N'SCOL_XL_54_01', N'IV and OV Struck Simultaneously', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_55', N'Insured Person Struck By OV', N'SCOL_XL_55_01', N'Pedestrian Struck By OV', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_55', N'Insured Person Struck By OV', N'SCOL_XL_55_02', N'Cyclist Struck By OV', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_55', N'Insured Person Struck By OV', N'SCOL_XL_55_03', N'As Passenger', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_56', N'IV Damaged During Transport', N'SCOL_XL_56_01', N'IV Damaged During Transport', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_57', N'IV Struck By Non Auto Vehicle', N'SCOL_XL_57_01', N'IV Struck By Non Auto Vehicle', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_05', N'Theft', N'SCOL_AU_05_01', N'Partial Loss', N'auto_claim_theft_of_parts',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_05', N'Theft', N'SCOL_AU_05_02', N'Total Loss', N'auto_claim_theft_of_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_06', N'Vandalism', N'SCOL_AU_06_01', N'Vandalism', N'auto_claim_vandalism',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_07', N'Windstorm', N'SCOL_AU_07_01', N'Windstorm', N'auto_claim_storm',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_22', N'Single Vehicle Accident', N'SCOL_AU_22_01', N'Single Vehicle Accident', N'auto_claim_collision_with_fixed_object',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_22', N'Single Vehicle Accident', N'SCOL_AU_22_02', N'IV Damaged Property', N'auto_claim_collision_with_fixed_object',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_23', N'Vehicle Struck by Object', N'SCOL_AU_23_01', N'Vehicle Struck by Object', N'auto_claim_falling_object',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_24', N'Water (Non-Flood)', N'SCOL_AU_24_01', N'Water (Non-Flood)', N'auto_claim_storm',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_26', N'IV Struck By IV', N'SCOL_AU_26_01', N'IV Struck By IV', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_27', N'IV and OV Struck Simultaneously', N'SCOL_AU_27_01', N'IV and OV Struck Simultaneously', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_28', N'Insured Person Struck By OV', N'SCOL_AU_28_02', N'Cyclist Struck By OV', N'auto_claim_collision_with_bicycle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_28', N'Insured Person Struck By OV', N'SCOL_AU_28_03', N'As Passenger', N'auto_claim_collision_with_pedestrian',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_30', N'IV Struck By Non Auto Vehicle', N'SCOL_AU_30_01', N'IV Struck By Non Auto Vehicle', N'auto_claim_collision_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_31', N'Emergency Movement Coverage', N'SCOL_AU_31_01', N'Emergency Movement Coverage', N'auto_claim_storm',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_01', N'IV Struck by OV', N'SCOL_AU_01_01', N'IV Struck by OV', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_01', N'IV Struck by OV', N'SCOL_AU_01_02', N'Sideswipe Impact', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_01', N'IV Struck by OV', N'SCOL_AU_01_03', N'IV Struck by OV Driver DUI', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_01', N'IV Struck by OV', N'SCOL_AU_01_04', N'Hit and Run', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_02', N'IV Driver DUI', N'SCOL_AU_02_01', N'IV Driver DUI', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_04', N'Fire', N'SCOL_AU_04_01', N'Fire', N'auto_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_09', N'Damage By Animal/Gnawing/Nesting', N'SCOL_AU_09_01', N'Damage By AnimalGnawingNesting', N'auto_claim_animal',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_10', N'Earthquake', N'SCOL_AU_10_01', N'Earthquake', N'auto_claim_earthquake',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_12', N'Flood', N'SCOL_AU_12_01', N'Flood', N'auto_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_13', N'Glass Breakage', N'SCOL_AU_13_01', N'Glass Breakage', N'auto_claim_glass',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_14', N'Hail', N'SCOL_AU_14_01', N'Hail', N'auto_claim_hail',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_16', N'IV Struck Pedestrian', N'SCOL_AU_16_01', N'IV Struck Pedestrian', N'auto_claim_collision_with_pedestrian',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_16', N'IV Struck Pedestrian', N'SCOL_AU_16_02', N'IV Struck Cyclist', N'auto_claim_collision_with_bicycle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_17', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_AU_17_01', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_17', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_AU_17_02', N'Multiple Ovs Struck  Caused by IV', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_17', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_AU_17_03', N'Multiple Ovs Struck  Caused by OV', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_18', N'OV Struck by IV', N'SCOL_AU_18_01', N'OV Struck by IV', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_18', N'OV Struck by IV', N'SCOL_AU_18_02', N'Sideswipe Impact', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_19', N'Riot/Civil Commotion', N'SCOL_AU_19_01', N'RiotCivil Commotion', N'auto_claim_riot_or_civil_unrest',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_20', N'Roadside Assistance', N'SCOL_AU_20_01', N'Roadside Assistance', N'auto_claim_tow_or_breakdown',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'AU', N'COL_AU_25', N'OV Driver DUI', N'SCOL_AU_25_01', N'OV Driver DUI', N'auto_claim_collision_with_motor_vehicle',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_01', N'Explosion', N'SCOL_HO_01_01', N'Explosion', N'property_claim_explosion',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_01', N'Arson', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_02', N'Electrical', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_03', N'FirepitFireplace', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_04', N'Fireworks', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_05', N'Kitchen', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_06', N'OtherUndetermined Origin', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_03', N'Flood', N'SCOL_HO_03_01', N'Flood', N'property_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_04', N'Freezing', N'SCOL_HO_04_01', N'Freezing', N'property_claim_freezing_water',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_01', N'AC LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_02', N'Appliance LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_03', N'Drain Line LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_04', N'Fire Sprinkler System', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_05', N'Irrigation System', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_06', N'Other', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_07', N'Roof Leak', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_05', N'Fungi/Mold', N'SCOL_HO_05_08', N'Supply Line LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_06', N'Glass Breakage', N'SCOL_HO_06_01', N'Weather-Driven', N'property_claim_broken_window',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_06', N'Glass Breakage', N'SCOL_HO_06_02', N'All Other', N'property_claim_broken_window',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_07', N'Hail', N'SCOL_HO_07_01', N'Hail', N'property_claim_hail',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_08', N'Hurricane', N'SCOL_HO_08_01', N'Flood Only', N'property_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_08', N'Hurricane', N'SCOL_HO_08_02', N'Wind Only', N'property_claim_wind',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_08', N'Hurricane', N'SCOL_HO_08_03', N'Wind and Flood', N'property_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_09', N'Identity Theft', N'SCOL_HO_09_01', N'Identity Theft', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_10', N'Liability', N'SCOL_HO_10_01', N'Animal', N'property_claim_thirdparty_dog_bite',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_10', N'Liability', N'SCOL_HO_10_02', N'Slip Trip and Fall', N'property_claim_thirdparty_fall',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_02', N'Fire', N'SCOL_HO_02_07', N'Wildfire', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_10', N'Liability', N'SCOL_HO_10_03', N'Other', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_11', N'Lightning', N'SCOL_HO_11_01', N'Lightning', N'property_claim_lightning',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_12', N'Loss Assessment', N'SCOL_HO_12_01', N'Loss Assessment', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_13', N'Power Outage', N'SCOL_HO_13_01', N'Weather-Driven', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_13', N'Power Outage', N'SCOL_HO_13_02', N'All Other', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_14', N'Sinkhole', N'SCOL_HO_14_01', N'Sinkhole', N'property_claim_sinkhole',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_15', N'Smoke', N'SCOL_HO_15_01', N'Fire', N'property_claim_smoke',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_15', N'Smoke', N'SCOL_HO_15_02', N'Wildfire', N'property_claim_smoke',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_16', N'Theft', N'SCOL_HO_16_01', N'Off Premises', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_16', N'Theft', N'SCOL_HO_16_02', N'On Premises', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_17', N'Tornado', N'SCOL_HO_17_01', N'Tornado', N'property_claim_wind',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_18', N'Vandalism', N'SCOL_HO_18_01', N'Vandalism', N'property_claim_vandalism',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_01', N'AC LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_02', N'Appliance LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_03', N'Drain Line LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_04', N'Fire Sprinkler System', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_05', N'Irrigation System', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_06', N'Other', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_07', N'Roof Leak', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_19', N'Water', N'SCOL_HO_19_08', N'Supply Line LeakFailure', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_20', N'Wind', N'SCOL_HO_20_01', N'Wind', N'property_claim_wind',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_21', N'Named Storms Other than Hurricanes', N'SCOL_HO_21_01', N'Named Storms Other than Hurricanes', N'property_claim_weather',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_22', N'Cyber Attack', N'SCOL_HO_22_01', N'Cyber Attack', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_23', N'Collapse', N'SCOL_HO_23_01', N'Weather-Driven', N'property_claim_weather',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_23', N'Collapse', N'SCOL_HO_23_02', N'All Other', N'property_claim_building_collapse',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_24', N'Equipment Breakdown', N'SCOL_HO_24_01', N'Equipment Breakdown', N'property_claim_equipment_breakdown',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_25', N'Damage by Animals', N'SCOL_HO_25_01', N'Damage by Animals', N'property_claim_thirdparty_dog_bite',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_26', N'Service Line', N'SCOL_HO_26_01', N'Service Line', N'property_claim_service_line',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_27', N'Ice Dam', N'SCOL_HO_27_01', N'Ice Dam', N'property_claim_ice_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_28', N'', N'SCOL_HO_28_01', N'Sewer and Drain', N'property_claim_sewer_backup',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_29', N'Workers Compensation', N'SCOL_HO_29_01', N'Workers Compensation', N'property_claim_thirdparty_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_30', N'Mysterious Disappearance', N'SCOL_HO_30_01', N'Mysterious Disappearance', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_31', N'Act of War', N'SCOL_HO_31_01', N'Act of War', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_32', N'Construction Defect', N'SCOL_HO_32_01', N'Construction Defect', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_33', N'Damage from Aircraft', N'SCOL_HO_33_01', N'Damage from Aircraft', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_34', N'Damage from Electrical Current/Power Surge', N'SCOL_HO_34_01', N'Weather-Driven', N'property_claim_power_surge',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_34', N'Damage from Electrical Current/Power Surge', N'SCOL_HO_34_02', N'All Other', N'property_claim_power_surge',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_35', N'Damage from Vehicle', N'SCOL_HO_35_01', N'Damage from Vehicle', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_36', N'Earth Movement', N'SCOL_HO_36_01', N'Earthquake', N'property_claim_earthquake',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_36', N'Earth Movement', N'SCOL_HO_36_02', N'Fire Following', N'property_claim_earth_movement',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_37', N'In Transit', N'SCOL_HO_37_01', N'In Transit', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_38', N'Landslide/Mudslide', N'SCOL_HO_38_01', N'LandslideMudslide', N'property_claim_earth_movement',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_39', N'Libel/Slander/Defamation', N'SCOL_HO_39_01', N'LibelSlanderDefamation', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_40', N'Not Defined/Other', N'SCOL_HO_40_01', N'Not DefinedOther', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_41', N'Nuclear Hazard', N'SCOL_HO_41_01', N'Nuclear Hazard', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_42', N'Riot Civil Commotion', N'SCOL_HO_42_01', N'Riot Civil Commotion', N'property_claim_riot',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_43', N'Snow or Sleet', N'SCOL_HO_43_01', N'Snow or Sleet', N'property_claim_weather',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_44', N'Subsidence', N'SCOL_HO_44_01', N'Subsidence', N'property_claim_earth_movement',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_45', N'Tropical Storm', N'SCOL_HO_45_01', N'Flood Only', N'property_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_45', N'Tropical Storm', N'SCOL_HO_45_02', N'Wind Only', N'property_claim_wind',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_45', N'Tropical Storm', N'SCOL_HO_45_03', N'Wind and Flood', N'property_claim_flood',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'HO', N'COL_HO_46', N'Volcanic Eruption', N'SCOL_HO_46_01', N'Volcanic Eruption', N'property_claim_volcano',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_02', N'Fire', N'SCOL_CO_02_01', N'Arson', N'property_claim_fire',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_06', N'Glass Breakage', N'SCOL_CO_06_02', N'All Other', N'property_claim_broken_window',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_08', N'Hurricane', N'SCOL_CO_08_02', N'Wind Only', N'property_claim_wind',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_33', N'In Transit', N'SCOL_CO_33_01', N'In Transit', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_26', N'Mysterious Disappearance', N'SCOL_CO_26_01', N'Mysterious Disappearance', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_36', N'Mysterious Disappearance', N'SCOL_CO_26_01', N'Mysterious Disappearance', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_36', N'Not Defined/Other', N'SCOL_CO_36_01', N'Not DefinedOther', N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_36', N'Others', NULL, NULL, N'property_claim_other',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_14', N'Theft', NULL, NULL, N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_14', N'Theft', N'SCOL_CO_14_01', N'Off Premises', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_14', N'Theft', N'SCOL_CO_14_02', N'On Premises', N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_14', N'Theft/Break-in/Burglary', NULL, NULL, N'property_claim_theft',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_17', N'Water', NULL, NULL, N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'LUX', N'COL_CO_17', N'Water', N'SCOL_CO_17_04', N'Fire Sprinkler System', N'property_claim_water_damage',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_01', N'OV Struck by IV', N'SCOL_XL_01_01', N'OV Struck by IV', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_01', N'OV Struck by IV', N'SCOL_XL_01_02', N'Sideswipe Impact', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_02', N'IV Driver DUI', N'SCOL_XL_02_01', N'IV Driver DUI', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_06', N'Harassment', N'SCOL_XL_06_01', N'Harrassment', N'liability_claim_harassment',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_08', N'Employment Practices Liability Insurance', N'SCOL_XL_08_01', N'HarassmentAssault', N'liability_claim_harassment',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_08', N'Employment Practices Liability Insurance', N'SCOL_XL_08_02', N'Other', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_08', N'Employment Practices Liability Insurance', N'SCOL_XL_08_03', N'Wrongful Termination', N'liability_claim_wrongful_termination',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_12', N'IV Struck Pedestrian', N'SCOL_XL_12_01', N'IV Struck Pedestrian', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_12', N'IV Struck Pedestrian', N'SCOL_XL_12_02', N'IV Struck Cyclist', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_12', N'IV Struck Pedestrian', N'SCOL_XL_12_03', N'IV Struck Pedestrian & Cyclist', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_13', N'Water (Non-Flood)', N'SCOL_XL_13_01', N'Water (Non-Flood)', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_17', N'Windstorm', N'SCOL_XL_17_01', N'Windstorm', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_24', N'Libel/Slander/Defamation', N'SCOL_XL_24_01', N'LibelSlanderDefamation', N'liability_claim_slander',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_28', N'Cyber Attack', N'SCOL_XL_28_01', N'Cyber Attack', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_29', N'Damage By Animal/Gnawing/Nesting', N'SCOL_XL_29_01', N'Damage by AnimalGnawingNesting', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_30', N'Earthquake', N'SCOL_XL_30_01', N'Earthquake', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_31', N'Explosion', N'SCOL_XL_31_01', N'Explosion', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_32', N'Fire', N'SCOL_XL_32_01', N'Fire', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_33', N'Flood', N'SCOL_XL_33_01', N'Flood', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_34', N'Fraud - Wire/Forgery/Fraudulent Transaction', N'SCOL_XL_34_01', N'Fraud - WireForgeryFraudulent Transaction', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_35', N'Glass Breakage', N'SCOL_XL_35_01', N'Glass Breakage', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_36', N'Hail', N'SCOL_XL_36_01', N'Hail', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_37', N'Identify Theft', N'SCOL_XL_37_01', N'Identify Theft', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_38', N'Impact With Animal', N'SCOL_XL_38_01', N'Impact With Animal', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_39', N'IV Struck by Object', N'SCOL_XL_39_01', N'IV Struck by Object', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_40', N'IV Struck by OV', N'SCOL_XL_40_01', N'IV Struck by OV', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_40', N'IV Struck by OV', N'SCOL_XL_40_02', N'Sideswipe Impact', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_40', N'IV Struck by OV', N'SCOL_XL_40_03', N'IV Struck by OV Driver DUI', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_40', N'IV Struck by OV', N'SCOL_XL_40_04', N'Hit and Run', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_41', N'Liability', N'SCOL_XL_41_01', N'Assault', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_41', N'Liability', N'SCOL_XL_41_02', N'Damage to Property of Others', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_41', N'Liability', N'SCOL_XL_41_03', N'DamageInjury by Animal', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_41', N'Liability', N'SCOL_XL_41_04', N'Other', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_41', N'Liability', N'SCOL_XL_41_05', N'Slip Trip and Fall', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_42', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_XL_42_01', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_42', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_XL_42_02', N'Multiple Ovs Struck  Caused by IV', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_42', N'Multi-Vehicle Accident (Greater Than 2 Vehicles)', N'SCOL_XL_42_03', N'Multiple Ovs Struck  Caused by OV', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_43', N'Riot/Civil Commotion', N'SCOL_XL_43_01', N'RiotCivil Commotion', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_44', N'Roadside Assistance', N'SCOL_XL_44_01', N'Roadside Assistance', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_46', N'Single Vehicle Accident', N'SCOL_XL_46_01', N'Single Vehicle Accident', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_46', N'Single Vehicle Accident', N'SCOL_XL_46_02', N'IV Damaged Property', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_47', N'Theft', N'SCOL_XL_47_01', N'Partial Loss', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_47', N'Theft', N'SCOL_XL_47_02', N'Total Loss', N'liability_claim_other_liability',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_48', N'Underinsured Motorist', N'SCOL_XL_48_01', N'Bodily Inury', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_48', N'Underinsured Motorist', N'SCOL_XL_48_02', N'Property Damage', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_49', N'Uninsured Motorist', N'SCOL_XL_49_01', N'Bodily Inury', N'liability_claim_bodily_injury',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts]) VALUES (N'PEL', N'COL_XL_49', N'Uninsured Motorist', N'SCOL_XL_49_02', N'Property Damage', N'liability_claim_fidelity',GETDATE())

INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts])
VALUES (N'AU', N'COL_AU_08', N'Other', N'SCOL_AU_08_01', N'Other', N'auto_claim_rollover',GETDATE())
 
INSERT [edw_stage].[migration_loss_type_mapping] ([product_cd], [cause_of_loss_cd], [cause_of_loss_desc], [sub_cause_of_loss_cd], [sub_cause_of_loss_desc], [lossType],[create_ts])
VALUES (N'AU', N'COL_AU_15', N'Impact With Animal', N'SCOL_AU_15_01', N'Impact With Animal', N'auto_claim_animal',GETDATE())