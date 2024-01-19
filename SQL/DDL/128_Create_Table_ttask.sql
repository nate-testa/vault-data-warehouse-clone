DROP table if exists edw_core.ttask;

CREATE TABLE edw_core.ttask (
    task_sk int IDENTITY(1,1) NOT NULL,
    policy_no varchar(255) NOT NULL,
    effective_dt date NOT NULL,
    transaction_effective_dt date NULL,
    transaction_seq_no int NULL,  
    task_nm varchar(255) NULL,
    workflow_nm varchar(255) NULL,
    workflow_step_nm varchar(255) NULL,
    created_by_nm    varchar(255) NULL,
    assigned_to_nm    varchar(255) NULL,
    completed_by_nm varchar(255) NULL,    
    task_status    varchar(255) NULL,
    task_priority int NULL,
    task_created_dt datetime2(7) NULL,    
    task_due_dt datetime2(7) NULL,    
    task_completed_dt    datetime2(7) NULL,
    task_completion_time_in_days int,
    task_completion_time_in_minutes int,
    task_updated_dt datetime2(7) NULL,
    task_closed_in varchar(255) NULL,   
    task_due_days int NULL, 
    task_suspended_until_dt datetime2(7) NULL,
    task_abandoned_reason_desc nvarchar(max),
    task_workflow_sk int not NULL,
    source_system_sk int NULL,
    create_ts datetime NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
    CONSTRAINT pk_ttask PRIMARY KEY (task_sk),
    );

    delete from edw_core.tedw_table_detail
    where table_nm = 'ttask';
    
    INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts)
    VALUES ('ttask','Type-2 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());