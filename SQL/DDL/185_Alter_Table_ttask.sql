IF OBJECT_ID('edw_core.uidx_ttask_polno_effdt_task_wf_wfs_cust')  IS NOT NULL 
ALTER TABLE [edw_core].[ttask] DROP CONSTRAINT [uidx_ttask_polno_effdt_task_wf_wfs_cust];
