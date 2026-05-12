  IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_commercial' 
               AND TABLE_NAME = 'tcommercial_quote_reinsurance_quota_share_placement')
BEGIN
CREATE TABLE edw_commercial.tcommercial_quote_reinsurance_quota_share_placement
(
             
commercial_quote_reinsurance_quota_share_placement_sk           int IDENTITY(1,1) NOT NULL,
commercial_quote_sk                                      int NOT NULL,
quote_no                                                 varchar(255) NOT NULL,
effective_dt                                              date NOT NULL,
expiration_dt                                             date NOT NULL,
transaction_seq_no                                        int NULL,  
commercial_quote_reinsurance_sk                                 int NOT NULL,  
carrier_nm                                                varchar(255) NULL,
reference_num                                             varchar(255) NULL,
brokerage_perc                                            varchar(255) NULL,
participation_perc                                        varchar(255) NULL,
per_claim_limit_amt                                       varchar(255) NULL,
aggregate_limit_amt                                       varchar(255) NULL,
net_premium_due_amt                                       varchar(255) NULL,
other_notes                                               varchar(255) NULL,
deleted_in                                                varchar(255) NULL,
source_system_sk                                          Int NOT NULL,
create_ts                                                 Datetime2(7) NOT NULL,
update_ts                                                 Datetime2(7) NOT NULL,
etl_audit_sk                                              Int NOT NULL,
CONSTRAINT pk_tcommercial_quote_reinsurance_quota_share_placement PRIMARY KEY (commercial_quote_reinsurance_quota_share_placement_sk),
CONSTRAINT uidx_tcommercial_quote_reinsurance_quota_share_placement_qtno_commercial_reinsurance_sk UNIQUE (quote_no ,effective_dt,commercial_quote_reinsurance_quota_share_placement_sk ),
CONSTRAINT fk_tcommercial_quote_reinsurance_quota_share_placement FOREIGN KEY (commercial_quote_sk) REFERENCES edw_commercial.tcommercial_quote (commercial_quote_sk),
CONSTRAINT fk_tcommercial_quote_reinsurance_reinsurance_quota_share_placement FOREIGN KEY (commercial_quote_reinsurance_sk ) REFERENCES edw_commercial.tcommercial_quote_reinsurance (commercial_quote_reinsurance_sk)

);
END



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tcommercial_quote_reinsurance_quota_share_placement')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tcommercial_quote_reinsurance_quota_share_placement' ; 
END ; 

INSERT INTO edw_core.tedw_table_detail (
    table_nm,
    table_type,
    table_category_nm,
    domain_nm,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'tcommercial_quote_reinsurance_quota_share_placement',
    'Type-2 Dimension',
    'Base',
    'Policy',
    'Stored Procedure',
    'Insert/Update',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tcommercial_quote_reinsurance_quota_share_placement'
);

