DROP table if exists edw_core.ttask;

CREATE TABLE edw_core.ttask (
    task_sk int IDENTITY(1,1) NOT NULL,
    policy_no varchar(255)not NULL,
    effective_dt date not NULL,
    transaction_effective_dt date NULL,
    transaction_seq_no int NULL, -- number from account transaction table
    task_nm varchar(255) NULL,
    workflow_nm varchar(255) NULL,
    workflow_step_nm varchar(255) NULL,
    created_by_nm    varchar(255) NULL,
    assigned_to_nm    varchar(255) NULL,
    completed_by_nm varchar(255) NULL,    
    task_status    varchar(255) NULL,
    priority int NULL,
    is_closed_in varchar(1) NULL,    
    due_days int NULL,
    created_dt datetime2 NULL,    
    due_dt datetime2 NULL,    
    completed_dt    datetime2 NULL,
    updated_dt datetime2 NULL,
    source_system_sk int NULL,
    create_ts datetime NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
    CONSTRAINT pk_ttask PRIMARY KEY (task_sk),
    --CONSTRAINT uidx_ttask_polno_effdt_transeq UNIQUE (policy_no,effective_dt,transaction_seq_no)
    )