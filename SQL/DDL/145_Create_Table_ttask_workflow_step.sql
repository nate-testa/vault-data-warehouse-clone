CREATE TABLE edw_core.ttask_workflow_step
(
    task_workflow_step_sk int IDENTITY(1,1) NOT NULL,
    task_workflow_step_nm varchar(255) NOT NULL,
    task_workflow_step_category_nm varchar(255),
    task_workflow_nm varchar(255) NOT NULL,
    create_ts datetime,
    update_ts datetime,
    CONSTRAINT pk_ttask_workflow_step PRIMARY KEY (task_workflow_step_sk)
);

INSERT INTO edw_core.tedw_table_detail
    (table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts)
VALUES
    ('ttask_workflow_step', 'Type-1 Dimension', 'Base', 'Policy', 'Stored Procedure', 'Insert/Update', 'Daily', getdate(), getdate());


