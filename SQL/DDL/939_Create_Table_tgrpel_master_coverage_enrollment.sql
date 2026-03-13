IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tgrpel_master_coverage_enrollment')
BEGIN
CREATE TABLE edw_core.tgrpel_master_coverage_enrollment
(
grpel_master_coverage_enrollment_sk             Int NOT NULL IDENTITY(1,1),
grpel_master_coverage_sk                        Int NOT NULL,
grpel_master_policy_no                          Varchar(255) NOT NULL,
effective_dt                                    Date NOT NULL,
expiration_dt                                   Date NOT NULL,
enrollment_created_user_nm                      Varchar(255),
enrollment_created_ts                           Datetime2(7) ,
enrollment_initial_start_dt                     Date ,
enrollment_period_in_days                       Int,
enrollment_frequency                            Varchar(255),
override_enrollment_to_open_in                  Varchar(255),
source_system_sk                                Int NOT NULL,
create_ts                                       Datetime2(7) NOT NULL,
update_ts                                       Datetime2(7) NOT NULL,
etl_audit_sk                                    Int NOT NULL,
CONSTRAINT pk_tgrpel_master_coverage_enrollment PRIMARY KEY (grpel_master_coverage_enrollment_sk),
CONSTRAINT uidx_tgrpel_master_coverage_enrollment_grpel_polno_effdt_created_ts UNIQUE (grpel_master_policy_no  ,effective_dt,enrollment_created_ts ),
CONSTRAINT fk_tgrpel_master_coverage_enrollment_coverage_sk FOREIGN KEY (grpel_master_coverage_sk) REFERENCES  edw_core.tgrpel_master_coverage(grpel_master_coverage_sk)

);
END



IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_master_coverage_enrollment')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_master_coverage_enrollment' ; 
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
    'tgrpel_master_coverage_enrollment',
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
    WHERE table_nm = 'tgrpel_master_coverage_enrollment'
);


