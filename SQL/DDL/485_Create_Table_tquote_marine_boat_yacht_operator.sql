 CREATE TABLE edw_core.tquote_marine_boat_yacht_operator 
(
    quote_marine_boat_yacht_operator_sk int IDENTITY(1,1) NOT NULL,
    quote_no varchar(255) NOT NULL,
    effective_dt date  NOT NULL,
    expiration_dt date NOT NULL,
    transaction_seq_no int NOT NULL,
    operator_no int NOT NULL,
    operator_unique_id varchar(255),
    quote_history_sk int NOT NULL,
    quote_marine_boat_yacht_sk int NOT NULL,
    first_nm varchar(255),
    last_nm varchar(255),
    license_type varchar(255),
    source_system_sk int ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int ,
    CONSTRAINT pk_tquote_marine_boat_yacht_operator PRIMARY KEY (quote_marine_boat_yacht_operator_sk),
    CONSTRAINT uidx_tquote_marine_boat_yacht_operator_quoteno_effdt_opruid_transeq UNIQUE (quote_no,effective_dt,operator_unique_id,transaction_seq_no),
    CONSTRAINT fk_tquote_marine_boat_yacht_operator_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk),
    CONSTRAINT fk_tquote_marine_boat_yacht_operator_quote_marine_boat_yacht_sk FOREIGN KEY (quote_marine_boat_yacht_sk) REFERENCES  edw_core.tquote_marine_boat_yacht(quote_marine_boat_yacht_sk),
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_marine_boat_yacht_operator','Type-2 Dimension','Base','Marine','Stored Procedure','Insert','Daily',getdate(),getdate());