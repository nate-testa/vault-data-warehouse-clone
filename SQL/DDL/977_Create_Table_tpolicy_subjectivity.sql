IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tpolicy_subjectivity')
BEGIN
CREATE TABLE edw_core.tpolicy_subjectivity
(
             
	policy_subjectivity_sk          int IDENTITY(1,1) NOT NULL,
	policy_no                       varchar(255) NOT NULL,
	effective_dt                    datetime2(7) NOT NULL,
	expiration_dt                   datetime2(7) NOT NULL,
	transaction_effective_dt        datetime2(7) NOT NULL,
	transaction_seq_no              int NOT NULL,
	policy_history_sk               int NOT NULL,
	required_for                    varchar(255) NULL,
	subjectivity_desc               nvarchar(2000) NULL,
	completed_in                    varchar(255) NULL,
	create_ts                       datetime2(7) NOT NULL,
	update_ts                       datetime2(7) NOT NULL,
	etl_audit_sk                    int NOT NULL,
	source_system_sk                int NOT NULL
CONSTRAINT pk_policy_subjectivity_sk PRIMARY KEY (policy_subjectivity_sk),
CONSTRAINT fk_tpolicy_subjectivity_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES edw_core.tpolicy_history (policy_history_sk)
);
END
IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tpolicy_subjectivity')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tpolicy_subjectivity' ; 
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
    update_ts,
    schema_nm
)
SELECT
    'tpolicy_subjectivity',
    'Type-1 Dimension',
    'Base',
    'Policy',
    'Stored Procedure',
    'Insert/Update',
    'Daily',
    GETDATE(),
    GETDATE(),
    'edw_core'
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tpolicy_subjectivity'
);
