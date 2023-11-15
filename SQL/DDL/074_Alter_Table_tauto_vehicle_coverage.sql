ALTER TABLE [edw_core].[tauto_vehicle_coverage] DROP CONSTRAINT [uidx_tauto_vehicle_coverage_polno_effdt_vehno_transeq];

ALTER TABLE [edw_core].[tauto_vehicle_coverage] ADD CONSTRAINT [uidx_tauto_vehicle_coverage_polno_effdt_vehuniqueid_transeq] UNIQUE (policy_no,effective_dt,vehicle_unique_id,transaction_seq_no);

