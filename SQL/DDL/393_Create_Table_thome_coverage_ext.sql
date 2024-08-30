CREATE TABLE edw_stage.thome_coverage_ext
(
    home_coverage_ext_sk       int NOT NULL IDENTITY(1,1),
    policy_no                  varchar(255),
    effective_dt               date, 
    transaction_seq_no         int, 
    label                       varchar(255),
    field                       varchar(255),
    [value]                     varchar(255), 
    create_ts                  datetime,
    update_ts                  datetime,
    etl_audit_sk               int,
    CONSTRAINT pk_thome_coverage_ext PRIMARY KEY (home_coverage_ext_sk) 
); 