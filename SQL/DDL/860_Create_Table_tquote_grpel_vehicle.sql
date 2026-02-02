IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tquote_grpel_vehicle')
BEGIN
CREATE TABLE edw_core.tquote_grpel_vehicle
(
quote_grpel_vehicle_sk             int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
expiration_dt              date NOT NULL,
transaction_seq_no         int NOT NULL,
quote_history_sk          int NOT NULL,
vehicle_no                 int NOT NULL,
vehicle_year               int,
vehicle_make               varchar(255),
vehicle_model              varchar(255),
vehicle_unique_id          varchar(255),
vehicle_deleted_in         varchar(255),
source_system_sk           int NOT NULL,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tquote_grpel_vehicle PRIMARY KEY (quote_grpel_vehicle_sk),
CONSTRAINT uidx_tquote_grpel_vehicle_qtno_effdt_vehuid UNIQUE (quote_no,effective_dt,vehicle_unique_id),
CONSTRAINT fk_tquote_grpel_vehicle_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk)

);
END

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_grpel_vehicle','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


