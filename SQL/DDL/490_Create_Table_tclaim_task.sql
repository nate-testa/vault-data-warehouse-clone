CREATE TABLE edw_core.tclaim_task
(
claim_task_sk int identity(1,1) not null,
claim_no varchar(255) not null,
claim_sk int not null,
task_id int not null,
task_type_nm varchar(255) not null,
task_status varchar(255) not null, 
task_priority varchar(255) , 
task_note nvarchar(max) ,
task_category_nm varchar(255),
task_file_type_nm varchar(255),
task_created_by_nm varchar(255),
task_created_ts DATETIME,
task_completed_by_nm varchar(255), 
task_completed_ts DATETIME, 
task_assigned_to_nm varchar(255), 
task_assigned_by_nm varchar(255), 
task_assigned_ts DATETIME, 
task_effective_ts DATETIME,
task_updated_ts DATETIME,
source_system_sk VARCHAR(255),
create_ts DATETIME,
update_ts DATETIME,
etl_audit_sk VARCHAR(255)
CONSTRAINT pk_tclaim_task PRIMARY KEY (claim_task_sk),
CONSTRAINT uidx_tclaim_task_task_id UNIQUE (task_id),   
CONSTRAINT fk_tclaim_task_claim_sk FOREIGN KEY (claim_sk) REFERENCES  edw_core.tclaim(claim_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_task','Type-2 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());