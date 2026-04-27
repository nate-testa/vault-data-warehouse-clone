  IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_participant')
BEGIN 
CREATE TABLE edw_core.tgrpel_participant
(
             
grpel_participant_sk                 int IDENTITY(1,1) NOT NULL,
grpel_master_policy_no                varchar(255) NOT NULL,
grpel_participant_id                  varchar(255) NOT NULL,
first_nm                        	  varchar(255) NULL,
last_nm                               varchar(255) NULL, 
email                                 varchar(255) NULL, 
tier_type                             varchar(255) NULL,
enrollment_status                     varchar(255) NULL,
deleted_in                            varchar(255) NULL,
source_system_sk           int NOT NULL,
create_ts                  datetime2(7) NOT NULL,
update_ts                  datetime2(7) NOT NULL,
etl_audit_sk               int NOT NULL,
CONSTRAINT pk_tgrpel_participant PRIMARY KEY (grpel_participant_sk)

);
END



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_participant')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_participant' ; 
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
    'tgrpel_participant',
    'Type-1 Dimension',
    'Base',
    'Group Personal Excess Liability',
    'Stored Procedure',
    'Insert/Update',
    'Daily',
    GETDATE(),
    GETDATE(),
    'edw_core'
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tgrpel_participant'
);


