CREATE TABLE edw_core.thome_coverage_ext
(
    home_coverage_ext_sk       int NOT NULL IDENTITY(1,1),
    policy_no                  varchar(255),
    effective_dt               date,
    transaction_effective_dt   date,
    expiration_dt              date,
    transaction_dt             date,
    transaction_seq_no         int,
    home_location_sk           int,
    home_coverage_sk           int,
    policy_history_sk          int, 
    home_coverage_ext_label    varchar(255),
    home_coverage_ext_field    varchar(255),
    home_coverage_ext_value    varchar(255),
    source_system_sk           int,
    create_ts                  datetime,
    update_ts                  datetime,
    etl_audit_sk               int,
    CONSTRAINT pk_thome_coverage_ext PRIMARY KEY (home_coverage_ext_sk),
    CONSTRAINT uidx_thome_coverage_ext_polno_effdt_transeq UNIQUE (policy_no,effective_dt,transaction_seq_no),
    CONSTRAINT fk_thome_coverage_ext_location_sk FOREIGN KEY (home_location_sk) REFERENCES  edw_core.thome_location(home_location_sk),
    CONSTRAINT fk_thome_coverage_ext_coverage_sk FOREIGN KEY (home_coverage_sk) REFERENCES  edw_core.thome_coverage(home_coverage_sk)
);

/*INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('thome_coverage_ext','Type-2 Dimension','Base','Home','Stored Procedure','Insert','Daily',getdate(),getdate());
    */