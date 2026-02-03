IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_driver')
BEGIN

CREATE TABLE edw_core.tgrpel_driver
(
grpel_driver_sk              int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
transaction_effective_dt   date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
policy_history_sk          int NOT NULL,
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
source_system_sk           int,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tgrpel_driver PRIMARY KEY (grpel_driver_sk),
CONSTRAINT uidx_tgrpel_driver_polno_effdt_transeq_drvuid UNIQUE (policy_no,effective_dt,transaction_seq_no,driver_unique_id),
CONSTRAINT fk_tgrpel_driver_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)
);
END

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tgrpel_driver','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


