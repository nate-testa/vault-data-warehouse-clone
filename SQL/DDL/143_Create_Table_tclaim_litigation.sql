CREATE TABLE edw_core.tclaim_litigation 
(
    claim_litigation_sk int IDENTITY(1,1) NOT NULL,
    claim_no varchar(255) NOT NULL,
    subclaim_seq_no varchar(255) NOT NULL,
    claim_sk int NOT NULL,
    claim_feature_sk int NOT NULL, 
    litigation_nm varchar(255),
    litigation_type varchar(255),
    litigation_status varchar(255),
    litigation_status_remark nvarchar(max),
    litigation_case_no varchar(255),
    litigation_open_dt date,
    litigation_mediation_dt date,
    litigation_close_dt datetime,
    litigation_location varchar(255),
    plaintiff_firm_nm varchar(255),
    plaintiff_firm_phone_no varchar(255),
    plaintiff_email varchar(255),
    litigation_dispute_amt decimal(15,2),
    final_settlement_amt decimal(15,2),
    source_system_sk int,    
    create_ts datetime NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
    CONSTRAINT pk_tclaim_litigation PRIMARY KEY (claim_litigation_sk),
    CONSTRAINT fk_tclaim_litigation_claim_sk FOREIGN KEY (claim_sk) REFERENCES  edw_core.tclaim(claim_sk),
    CONSTRAINT fk_tclaim_litigation_claim_feature_sk FOREIGN KEY (claim_feature_sk) REFERENCES  edw_core.tclaim_feature(claim_feature_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts)
    VALUES ('tclaim_litigation','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
