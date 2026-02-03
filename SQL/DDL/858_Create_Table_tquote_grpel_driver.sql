IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tquote_grpel_driver')
BEGIN
CREATE TABLE edw_core.tquote_grpel_driver
(
quote_grpel_driver_sk     int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
expiration_dt              date NOT NULL,
transaction_seq_no         int NOT NULL,
quote_history_sk          int NOT NULL,
driver_no                  int NOT NULL,
first_nm                   varchar(255),
middle_nm                  varchar(255),
last_nm                    varchar(255),
birth_dt                   varchar(255),
relationship_to_insured    varchar(255),
dui_dwi_in             varchar(255),
license_status             varchar(255),
license_country_nm         varchar(255),
license_state_cd           varchar(255),
license_year               int,
license_no                 varchar(255),
driver_unique_id           varchar(255),
driver_deleted_in          varchar(255),
source_system_sk           int NOT NULL,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tquote_grpel_driver PRIMARY KEY (quote_grpel_driver_sk),
CONSTRAINT uidx_tquote_grpel_driver_qtno_effdt_drvuid UNIQUE (quote_no,effective_dt,driver_unique_id),
CONSTRAINT fk_tquote_grpel_driver_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk)

);
END

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_grpel_driver','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());




