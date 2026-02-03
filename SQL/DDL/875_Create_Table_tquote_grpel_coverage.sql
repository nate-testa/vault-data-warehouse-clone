IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_core'
and TABLE_name = 'tquote_grpel_coverage')
BEGIN
CREATE TABLE edw_core.tquote_grpel_coverage
(
grpel_master_policy_sk                         int NOT NULL IDENTITY(1,1),  
quote_no                                       varchar(255) NOT NULL,
grpel_quote_no                                 varchar(255) NOT NULL,
effective_dt                                   date NOT NULL,
expiration_dt                                  date NOT NULL,
transaction_seq_no                             int NOT NULL,
quote_history_sk                               int NOT NULL,
group_nm                                       varchar(255) NOT NULL,
group_excess_liability_limit_amt               varchar(255),
uninsured_motorist_liability_limit_amt         varchar(255),
employment_practises_liability_limit_amt       varchar(255),
non_profit_do_liability_limit_amt              varchar(255),
family_trust_management_liability_limit_amt    varchar(255),
uninsured_underinsured_liability_limit_amt     varchar(255),
reputational_injury_coverage_limit_amt         varchar(255),
no_of_vehicles                                 varchar(255),
no_of_private_staff                            varchar(255),
no_of_high_performance_vehicles                varchar(255),
no_of_recreational_vehicles                    varchar(255),
no_of_boats_yachts                             varchar(255),
no_of_personal_watercraft                      varchar(255),
underlying_auto_insurance_company              varchar(255),
underlying_home_insurance_company              varchar(255),
underlying_watercraft_insurance_company        varchar(255),
source_system_sk                               int NOT NULL,
create_ts                                      datetime,
update_ts                                      datetime,
etl_audit_sk                                   int,
CONSTRAINT pk_tquote_grpel_coverage PRIMARY KEY (grpel_master_policy_sk),
CONSTRAINT uidx_tquote_grpel_coverage_qtno_effdt_transeq UNIQUE (quote_no,effective_dt,transaction_seq_no),
CONSTRAINT fk_tquote_grpel_coverage_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk)
)
END;


IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_coverage')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_coverage' ; 
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
    'tgrpel_coverage',
    'Type-2 Dimension',
    'Base',
    'Group Personal Excess Liability',
    'Stored Procedure',
    'Insert',
    'Monthly',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tquote_grpel_coverage'
);


