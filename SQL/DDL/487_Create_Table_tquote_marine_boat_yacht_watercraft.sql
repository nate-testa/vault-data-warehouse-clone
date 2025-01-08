CREATE TABLE edw_core.tquote_marine_boat_yacht_watercraft 
(
    quote_marine_boat_yacht_watercraft_sk int IDENTITY(1,1) NOT NULL,
    quote_no varchar(255) NOT NULL,
    effective_dt date  NOT NULL,
    expiration_dt date NOT NULL,
    transaction_seq_no int NOT NULL,
    watercraft_no int NOT NULL,
    watercraft_unique_id varchar(255),
    quote_history_sk int NOT NULL,
    watercraft_make varchar(255),
    watercraft_model varchar(255),
    watercraft_year varchar(255),
	watercraft_pwc_id varchar(255),
    source_system_sk int ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int ,
    CONSTRAINT pk_tquote_marine_boat_yacht_watercraft PRIMARY KEY (quote_marine_boat_yacht_watercraft_sk),
    CONSTRAINT uidx_tquote_marine_boat_yacht_watercraft_qtno_effdt_wcft_uid_transeq UNIQUE (quote_no,effective_dt,watercraft_unique_id,transaction_seq_no),
    CONSTRAINT fk_tquote_marine_boat_yacht_watercraft_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_marine_boat_yacht_watercraft','Type-2 Dimension','Base','Marine','Stored Procedure','Insert','Daily',getdate(),getdate());