ALTER TABLE edw_core.ttask ALTER COLUMN policy_no varchar(255) NULL;
ALTER TABLE edw_core.ttask ALTER COLUMN effective_dt date NULL;
ALTER TABLE edw_core.ttask ADD customer_sk int not NULL; 

 IF OBJECT_ID('edw_core.uidx_ttask_polno_effdt_task')  IS NOT NULL 
    ALTER TABLE edw_core.ttask DROP CONSTRAINT uidx_ttask_polno_effdt_task;

 IF OBJECT_ID('edw_core.uidx_ttask_polno_effdt_task_wf_wfs_cust')  IS NOT NULL 
    ALTER TABLE edw_core.ttask DROP CONSTRAINT uidx_ttask_polno_effdt_task_wf_wfs_cust;

    
ALTER TABLE edw_core.ttask ADD CONSTRAINT uidx_ttask_polno_effdt_task_wf_wfs_cust UNIQUE (policy_no,effective_dt,transaction_seq_no,task_nm,task_created_dt,workflow_nm,workflow_step_nm,customer_sk)