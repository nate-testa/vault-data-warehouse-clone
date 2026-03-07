IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tquote_grpel_master_coverage_tier')
BEGIN
CREATE TABLE edw_core.tquote_grpel_master_coverage_tier
(
quote_grpel_master_coverage_tier_sk                                       int NOT NULL IDENTITY(1,1),
grpel_master_quote_no                                              varchar(255) NOT NULL,
quote_grpel_master_coverage_sk                                              int NOT NULL, 
effective_dt                                                       date NOT NULL,
expiration_dt                                                      date NOT NULL,
transaction_seq_no                                                 int NOT NULL,
tier_type                                                          varchar(255),
no_of_participating_members                                        varchar(255),
excess_liability_limit_min_amt                                     varchar(255),  
excess_liability_limit_max_amt                                     varchar(255),
excess_liability_sponsored_amt                                     varchar(255),
uninsured_underinsured_motorist_liability_limit_min_amt           varchar(255),  
uninsured_underinsured_motorist_liability_limit_max_amt           varchar(255),
uninsured_underinsured_motorist_liability_limit_sponsored_amt     varchar(255), 
non_profit_do_liability_limit_min_amt                              varchar(255),
non_profit_do_liability_limit_max_amt                              varchar(255),  
non_profit_do_liability_limit_sponsored_amt                        varchar(255),  
employment_practices_liability_limit_min_amt                       varchar(255), 
employment_practices_liability_limit_max_amt                       varchar(255),
employment_practices_liability_limit_sponsored_amt                 varchar(255),
family_trust_management_liability_limit_min_amt                    varchar(255), 
family_trust_management_liability_limit_max_amt                    varchar(255),
family_trust_management_liability_limit_sponsored_amt              varchar(255),
source_system_sk                                                   int NOT NULL,
create_ts                                                          datetime2(7) NOT NULL,
update_ts                                                          datetime2(7) NOT NULL,
etl_audit_sk                                                       int NOT NULL,
CONSTRAINT pk_tquote_grpel_master_coverage_tier PRIMARY KEY (quote_grpel_master_coverage_tier_sk),
CONSTRAINT uidx_tquote_grpel_master_coverage_tier_grpel_qtno_effdt_trans_seq_no UNIQUE (grpel_master_quote_no ,effective_dt,transaction_seq_no),
CONSTRAINT fk_tquote_grpel_master_coverage_tier_quote_grpel_master_coverage_sk  FOREIGN KEY (quote_grpel_master_coverage_sk ) REFERENCES  edw_core.tquote_grpel_master_coverage (quote_grpel_master_coverage_sk )

);
END

--DROP



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_master_coverage_tier')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_master_coverage_tier' ; 
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
    'tquote_grpel_master_coverage_tier',
    'Type-2 Dimension',
    'Base',
    'Group Personal Excess Liability',
    'Stored Procedure',
    'Insert',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tquote_grpel_master_coverage_tier'
);