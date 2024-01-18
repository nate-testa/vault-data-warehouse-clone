CREATE TABLE edw_core.ttask_workflow
(
    task_workflow_sk  int IDENTITY(1,1) NOT NULL,
    task_workflow_nm  varchar(255),
    task_workflow_category_nm varchar(255),
    create_ts datetime,
    update_ts datetime,
    CONSTRAINT pk_ttask_workflow PRIMARY KEY (task_workflow_sk)
);
 
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts)
    VALUES ('ttask_workflow','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

alter table edw_core.ttask 
add CONSTRAINT fk_ttask_task_workflow_sk FOREIGN KEY (task_workflow_sk) REFERENCES edw_core.ttask_workflow(task_workflow_sk)