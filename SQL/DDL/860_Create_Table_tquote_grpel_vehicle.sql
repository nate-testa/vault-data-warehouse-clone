CREATE TABLE edw_core.tquote_grpel_vehicle
(
quote_grpel_vehicle_sk             int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255),
effective_dt               date,
expiration_dt              date,
transaction_seq_no         int,
quote_history_sk          int,
vehicle_no                 int,
vehicle_year               int,
vehicle_make               varchar(255),
vehicle_model              varchar(255),
vehicle_unique_id          varchar(255),
vehicle_deleted_in         varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tquote_grpel_vehicle PRIMARY KEY (quote_grpel_vehicle_sk),
CONSTRAINT uidx_tquote_grpel_vehicle_qtno_effdt_vehno UNIQUE (quote_no,effective_dt,vehicle_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_grpel_vehicle','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

