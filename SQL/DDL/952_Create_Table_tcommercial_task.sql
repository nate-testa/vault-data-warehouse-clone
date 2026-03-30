IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_commercial' 
               AND TABLE_NAME = 'tcommercial_task')
BEGIN
CREATE TABLE edw_commercial.tcommercial_task
(
             
commercial_task_sk                       int IDENTITY(1,1) NOT NULL,
policy_no                                varchar(255) NOT NULL,
effective_dt                             date NOT NULL,
transaction_effective_dt                 date NULL,
transaction_seq_no                       int NULL,  
task_nm                                  varchar(255) NULL,
workflow_nm                              varchar(255) NULL,
workflow_step_nm                         varchar(255) NULL,
created_by_nm                            varchar(255) NULL,
assigned_to_nm                           varchar(255) NULL,
completed_by_nm                          varchar(255) NULL,
task_status                              varchar(255) NULL,
task_priority                            varchar(255) NULL,
task_created_dt                          datetime2(7) NULL,    
task_due_dt                              datetime2(7) NULL,    
task_completed_dt                        datetime2(7) NULL,    
task_completion_time_in_days             int,
task_completion_time_in_minutes          int,
task_updated_dt                          datetime2(7) NULL,
task_closed_in                           varchar(255) NULL,
task_due_days                            int NULL, 
task_suspended_until_dt                  datetime2(7) NULL,
task_abandoned_reason_desc               nvarchar(max),
task_workflow_sk                         int not NULL,
task_workflow_step_sk                    int NULL,
customer_sk                              int NULL,
created_by_user_sk                       int NULL,
assigned_to_user_sk                      int NULL,
completed_by_user_sk                     int NULL,
task_id                                  varchar(255) NULL,
source_system_sk                         Int NOT NULL,
create_ts                                Datetime2(7) NOT NULL,
update_ts                                Datetime2(7) NOT NULL,
etl_audit_sk                             Int NOT NULL,
CONSTRAINT pk_tcommercial_task PRIMARY KEY (commercial_task_sk),
CONSTRAINT uidx_tcommercial_task_polno_effdt_trans_effdt UNIQUE (commercial_task_sk,policy_no ,effective_dt,transaction_effective_dt   ),
CONSTRAINT fk_tcommercial_task_policy_no FOREIGN KEY (policy_no) REFERENCES  edw_commercial.tcommercial_policy(policy_no)

);
END



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tcommercial_task')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tcommercial_task' ; 
END ; 

INSERT INTO edw_core.tedw_table_detail (
    table_nm,
    table_type,
    table_category_nm,
    domain_nm,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'tcommercial_task',
    'Type-2 Dimension',
    'Base',
    'Policy',
    'Stored Procedure',
    'Insert',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tcommercial_task'
);


