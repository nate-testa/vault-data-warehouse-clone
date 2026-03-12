IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tquote_grpel_master_coverage_enrollment')
BEGIN
CREATE TABLE edw_core.tquote_grpel_master_coverage_enrollment
(
quote_grpel_master_coverage_enrollment_sk             Int NOT NULL IDENTITY(1,1),
quote_grpel_master_coverage_sk                        Int NOT NULL,
grpel_master_quote_no                          Varchar(255) NOT NULL,
effective_dt                                    Date NOT NULL,
expiration_dt                                   Date NOT NULL,
enrollment_created_user_nm                      Varchar(255),
enrollment_created_ts                           Datetime2(7) ,
enrollment_initial_start_dt                     Date ,
enrollment_period_in_days                       Int,
enrollment_frequency                            Varchar(255),
override_enrollment_to_open_in                  Varchar(255),
source_system_sk                                Int NOT NULL,
create_ts                                       Datetime2(7),
update_ts                                       Datetime2(7),
etl_audit_sk                                    Int,
CONSTRAINT pk_tquote_grpel_master_coverage_enrollment PRIMARY KEY (quote_grpel_master_coverage_enrollment_sk ),
CONSTRAINT uidx_tquote_grpel_master_coverage_enrollment_qtno_effdt_created_ts UNIQUE (grpel_master_quote_no,effective_dt,enrollment_created_ts ),
CONSTRAINT fk_tquote_grpel_master_coverage_enrollment_quote_no FOREIGN KEY (quote_grpel_master_coverage_sk) REFERENCES  edw_core.tquote_grpel_master_coverage(quote_grpel_master_coverage_sk)

);
END


IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_master_coverage_enrollment')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tquote_grpel_master_coverage_enrollment' ; 
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
    'tquote_grpel_master_coverage_enrollment',
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
    WHERE table_nm = 'tquote_grpel_master_coverage_enrollment'
);


