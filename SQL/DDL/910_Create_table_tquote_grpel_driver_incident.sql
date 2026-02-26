
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tquote_grpel_driver_incident')
BEGIN
CREATE TABLE edw_core.tquote_grpel_driver_incident
(
quote_grpel_driver_incident_sk             int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
quote_history_sk          int NOT NULL,
quote_grpel_driver_sk            int NOT NULL,
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
CONSTRAINT pk_tquote_grpel_driver_incident PRIMARY KEY (quote_grpel_driver_incident_sk),
CONSTRAINT uidx_tquote_grpel_driver_incident_qtno_effdt_driver_sk UNIQUE (quote_no ,effective_dt,quote_grpel_driver_sk ),
CONSTRAINT fk_tquote_grpel_driver_incident_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES  edw_core.tquote_history(quote_history_sk),
CONSTRAINT fk_tquote_grpel_driver_incident_quote_grpel_driver_sk FOREIGN KEY (quote_grpel_driver_sk) REFERENCES  edw_core.tquote_grpel_driver(quote_grpel_driver_sk),
);
END


IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_driver_incident')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_driver_incident' ; 
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
    'tquote_grpel_driver_incident',
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
    WHERE table_nm = 'tquote_grpel_driver_incident'
);


