
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_driver_incident')
BEGIN
CREATE TABLE edw_core.tgrpel_driver_incident
(
grpel_driver_incident_sk             int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
transaction_effective_dt   date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
policy_history_sk          int NOT NULL,
grpel_driver_sk            int NOT NULL,
driver_no                  int,
incident_no                int,
incident_source            varchar(255),
incident_status            varchar(255),
indicent_dt                date,
incident_type              varchar(255),
incident_description       varchar(255),
source_system_sk           int NOT NULL,
create_ts                  datetime2(7),
update_ts                  datetime2(7),
etl_audit_sk               int,
CONSTRAINT pk_tgrpel_driver_incident PRIMARY KEY (grpel_driver_incident_sk ),
CONSTRAINT uidx_tgrpel_driver_incident_polno_effdt_transeq_driver_sk UNIQUE (policy_no,effective_dt,transaction_seq_no,grpel_driver_sk ),
CONSTRAINT fk_tgrpel_driver_incident_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk),
CONSTRAINT fk_tgrpel_driver_incident_grpel_driver_sk FOREIGN KEY (grpel_driver_sk) REFERENCES  edw_core.tgrpel_driver(grpel_driver_sk),
);
END



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_driver_incident')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_driver_incident' ; 
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
    'tgrpel_driver_incident',
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
    WHERE table_nm = 'tgrpel_driver_incident'
);


