 CREATE TABLE edw_core.tmarine_boat_yacht_operator 
(
    marine_boat_yacht_operator_sk int IDENTITY(1,1) NOT NULL,
    policy_no varchar(255) NOT NULL,
    effective_dt date  NOT NULL,
    transaction_effective_dt date NOT NULL,
    expiration_dt date NOT NULL,
    transaction_dt date NOT NULL ,
    transaction_seq_no int NOT NULL,
    operator_no int NOT NULL,
    operator_unique_id varchar(255),
    policy_history_sk int NOT NULL,
    marine_boat_yacht_sk int NOT NULL,
    first_nm varchar(255),
    last_nm varchar(255),
    license_type varchar(255),
    source_system_sk int ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int ,
    CONSTRAINT pk_tmarine_boat_yacht_operator PRIMARY KEY (marine_boat_yacht_operator_sk),
    CONSTRAINT uidx_tmarine_boat_yacht_operator_polno_effdt_oprno_transeq UNIQUE (policy_no,effective_dt,operator_unique_id,transaction_seq_no),
    CONSTRAINT fk_tmarine_boat_yacht_operator_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk),
    CONSTRAINT fk_tmarine_boat_yacht_operator_marine_boat_yacht_sk FOREIGN KEY (marine_boat_yacht_sk) REFERENCES  edw_core.tmarine_boat_yacht(marine_boat_yacht_sk),
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tmarine_boat_yacht_operator','Type-2 Dimension','Base','Marine','Stored Procedure','Insert','Daily',getdate(),getdate());