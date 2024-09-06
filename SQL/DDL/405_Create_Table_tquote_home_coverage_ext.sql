CREATE TABLE edw_stage.tquote_home_coverage_ext
(
    quote_home_coverage_ext_sk       int NOT NULL IDENTITY(1,1),
    quote_no                  varchar(255),
    effective_dt               date, 
    transaction_seq_no         int, 
    label                       varchar(255),
    field                       varchar(255),
    [value]                     varchar(255), 
    create_ts                  datetime,
    update_ts                  datetime,
    etl_audit_sk               int,
    CONSTRAINT pk_tquote_home_coverage_ext PRIMARY KEY (quote_home_coverage_ext_sk) 
); 