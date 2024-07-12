ALTER TABLE edw_core.tpolicy_insured ADD CONSTRAINT fk_tpolicy_insured_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
GO
ALTER TABLE edw_core.tpel_coverage ADD CONSTRAINT fk_tpel_coverage_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
GO
ALTER TABLE edw_core.tpel_location ADD CONSTRAINT fk_tpel_location_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
GO
ALTER TABLE edw_core.tloss_history ADD CONSTRAINT fk_tloss_history_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
GO
ALTER TABLE edw_core.tadditional_interest ADD CONSTRAINT fk_tadditional_interest_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.tpel_vehicle ADD CONSTRAINT fk_tpel_vehicle_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
GO
ALTER TABLE edw_core.tpel_driver ADD CONSTRAINT fk_tpel_driver_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.tpel_driver_incident ADD CONSTRAINT fk_tpel_driver_incident_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.tpel_watercraft ADD CONSTRAINT fk_tpel_watercraft_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.thome_coverage ADD CONSTRAINT fk_thome_coverage_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.thome_additional_coverage ADD CONSTRAINT fk_thome_additional_coverage_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  
GO
ALTER TABLE edw_core.tmortgagee ADD CONSTRAINT fk_tmortgagee_policy_history_sk FOREIGN KEY([policy_history_sk]) REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])  

