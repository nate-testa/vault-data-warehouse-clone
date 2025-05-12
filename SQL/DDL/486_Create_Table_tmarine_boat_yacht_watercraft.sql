CREATE TABLE edw_core.tmarine_boat_yacht_watercraft 
(
    marine_boat_yacht_watercraft_sk int IDENTITY(1,1) NOT NULL,
    policy_no varchar(255) NOT NULL,
    effective_dt date  NOT NULL,
    transaction_effective_dt date NOT NULL,
    expiration_dt date NOT NULL,
    transaction_dt date NOT NULL ,
    transaction_seq_no int NOT NULL,
    watercraft_no int NOT NULL,
    watercraft_unique_id varchar(255),
    policy_history_sk int NOT NULL,
    watercraft_make varchar(255),
    watercraft_model varchar(255),
    watercraft_year varchar(255),
	watercraft_pwc_id varchar(255),
    source_system_sk int ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int ,
    CONSTRAINT pk_tmarine_boat_yacht_watercraft PRIMARY KEY (marine_boat_yacht_watercraft_sk),
    CONSTRAINT uidx_tmarine_boat_yacht_watercraft_polno_effdt_wcftuid_transeq UNIQUE (policy_no,effective_dt,watercraft_unique_id,transaction_seq_no),
    CONSTRAINT fk_tmarine_boat_yacht_watercraft_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tmarine_boat_yacht_watercraft','Type-2 Dimension','Base','Marine','Stored Procedure','Insert','Daily',getdate(),getdate());