ALTER TABLE [edw_core].[tauto_vehicle] DROP CONSTRAINT [uidx_tauto_vehicle_policyno_effective_dt_vehicleno];

ALTER TABLE [edw_core].[tauto_vehicle] ADD CONSTRAINT [uidx_tauto_vehicle_policyno_effective_dt_vehicle_unique_id] UNIQUE (policy_no,effective_dt,vehicle_unique_id);
