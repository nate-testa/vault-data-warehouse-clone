CREATE TABLE edw_core.tquote_grpel_driver
(
quote_grpel_driver_sk              int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255),
effective_dt               date,
expiration_dt              date,
transaction_seq_no         int,
quote_history_sk          int,
driver_no                  int,
prefix                     varchar(255),
first_nm                   varchar(255),
middle_nm                  varchar(255),
last_nm                    varchar(255),
suffix                     varchar(255),
birth_dt                   varchar(255),
relationship_to_insured    varchar(255),
has_dui_dwi_in             varchar(255),
license_status             varchar(255),
license_country_nm         varchar(255),
license_state_cd           varchar(255),
license_year               int,
license_no                 varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tquote_grpel_driver PRIMARY KEY (quote_grpel_driver_sk),
CONSTRAINT uidx_tquote_grpel_driver_qtno_effdt_drvno UNIQUE (quote_no,effective_dt,driver_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_grpel_driver','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


