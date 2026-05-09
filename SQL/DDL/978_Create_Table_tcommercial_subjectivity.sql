IF NOT EXISTS
(
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_commercial'
AND TABLE_NAME = 'tcommercial_subjectivity')
BEGIN

CREATE TABLE edw_commercial.tcommercial_subjectivity (
 commercial_subjectivity_sk int IDENTITY(1,1) NOT NULL,
 quote_no varchar(255) NOT NULL,
 effective_dt date NULL,
 expiration_dt date NULL,
 subjectivity_id varchar(255) NOT NULL,
 subjectivity_created_ts datetime2(7) NOT NULL,
 subjectivity_updated_ts datetime2(7) NOT NULL,
 required_for varchar(255) NULL,
 subjectivity_desc varchar(255) NULL,
 completed_in varchar(255) NULL,
 signature_package_in varchar(255) NULL,
 upload_required_in varchar(255) NULL,
 signature_document_in varchar(255) NULL,
 added_by_rule_in varchar(255) NULL,
 deleted_in varchar(255) NULL,
 added_by_user_nm varchar(255) NULL,
 completed_by_user_nm varchar(255) NULL,
-- account_subjectivity_id varchar(255) NULL,
 critical_in varchar(255) NULL,
 create_ts datetime2(7) NOT NULL,
 update_ts datetime2(7) NOT NULL,
 etl_audit_sk int NOT NULL,
 source_system_sk int NOT NULL,
 CONSTRAINT pk_tcommercial_subjectivity PRIMARY KEY (commercial_subjectivity_sk)
);
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
    'tcommercial_subjectivity',
    'Type-1 Dimension',
    'Base',
    'Quote',
    'Stored Procedure',
    'Insert/Update',
    'Daily',
    GETDATE(),
    GETDATE(),
    'edw_commercial'
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tcommercial_subjectivity'
);
