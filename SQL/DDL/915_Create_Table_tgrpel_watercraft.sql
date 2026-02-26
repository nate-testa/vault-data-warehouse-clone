
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_watercraft')
BEGIN
CREATE TABLE edw_core.tgrpel_watercraft
(
grpel_watercraft_sk             int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
transaction_effective_dt   date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
policy_history_sk          int NOT NULL,
watercraft_no                 int NOT NULL,
watercraft_year               int,
watercraft_make               varchar(255),
watercraft_model              varchar(255),
watercraft_unique_id          varchar(255),
watercraft_deleted_in         varchar(255),
source_system_sk           int NOT NULL,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tgrpel_watercraft PRIMARY KEY (grpel_watercraft_sk),
CONSTRAINT uidx_tgrpel_watercraft_polno_effdt_transeq_watercraft_uid UNIQUE (policy_no,effective_dt,transaction_seq_no,watercraft_unique_id),
CONSTRAINT fk_tgrpel_watercraft_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)

);
END


IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_watercraft')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_watercraft' ; 
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
    'tgrpel_watercraft',
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
    WHERE table_nm = 'tgrpel_watercraft'
);


