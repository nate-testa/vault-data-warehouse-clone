IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_vehicle')
BEGIN
CREATE TABLE edw_core.tgrpel_vehicle
(
grpel_vehicle_sk             int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
vehicle_no                 int,
vehicle_year               int,
vehicle_make               varchar(255),
vehicle_model              varchar(255),
vehicle_unique_id          varchar(255),
vehicle_deleted_in         varchar(255),
source_system_sk           int,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tgrpel_vehicle PRIMARY KEY (grpel_vehicle_sk),
CONSTRAINT uidx_tgrpel_vehicle_polno_effdt_transeq_vehuid UNIQUE (policy_no,effective_dt,transaction_seq_no,vehicle_unique_id)
);
END

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tgrpel_vehicle','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

