

CREATE TABLE edw_core.tetl_audit (
  etl_audit_sk int IDENTITY(1,1) NOT NULL,
  process_nm varchar(255) ,  process_start_ts datetime,
  process_end_ts datetime,
  record_ct int,
  status_desc varchar(255),
  error_message_desc varchar(2000),
  parameter_desc varchar(255),
  CONSTRAINT pk_tetl_audit PRIMARY KEY (etl_audit_sk)
);




CREATE TABLE edw_core.tetl_control (
  etl_control_sk int IDENTITY(1,1) NOT NULL,
  process_nm varchar(255),
  last_source_extract_ts datetime2 ,
  update_ts datetime ,
  CONSTRAINT pk_tetl_control PRIMARY KEY (etl_control_sk),
  CONSTRAINT uidx_tetl_control_process_nm UNIQUE (process_nm)
);



CREATE TABLE edw_core.tvalidation_sql (
  validation_sql_sk int IDENTITY(1,1) NOT NULL,
  validation_sql_desc varchar(255) ,
  source_sql varchar(4000) ,
  target_sql varchar(4000) ,
  active_in varchar(1) ,
  frequency_desc varchar(255) ,
  create_ts datetime NOT NULL,
  update_ts datetime NOT NULL,
   CONSTRAINT pk_tvalidation_sql PRIMARY KEY (validation_sql_sk)
) ;



CREATE TABLE edw_core.tvalidation_result (
  validation_result_sk int IDENTITY(1,1) NOT NULL,
  validation_sql_sk int,
  process_run_start_ts datetime,
  process_run_end_ts datetime,
  source_sql varchar(4000),
  target_sql varchar(4000),
  source_value decimal(15,2),
  target_value decimal(15,2),
  status_desc varchar(255),
  CONSTRAINT pk_tvalidation_result PRIMARY KEY (validation_result_sk),
  CONSTRAINT fk_tvalidation_result_validation_sql_sk FOREIGN KEY (validation_sql_sk) REFERENCES  edw_core.tvalidation_sql(validation_sql_sk)
);


CREATE TABLE edw_core.tedw_table_detail
(
edw_table_detail_sk       int IDENTITY(1,1) NOT NULL,
table_nm                  varchar(255),
table_type   		     varchar(255),
table_category_nm         varchar(255),
domain_nm                 varchar(255),
load_method               varchar(255),
load_type                 varchar(255),
load_frequency            varchar(255),
create_ts                 datetime,
update_ts                 datetime
CONSTRAINT pk_tedw_table_detail PRIMARY KEY (edw_table_detail_sk)
);

CREATE TABLE edw_core.treconciliation 
(
reconciliation_sk     int IDENTITY(1,1) NOT NULL,
transaction_start_dt  date ,
transaction_end_dt    date ,
source_record_ct      int ,
source_amt            decimal(15,2) ,
target_record_ct      int ,
target_amt            decimal(15,2) ,
datamart_nm           varchar(255) ,
status_desc           varchar(255) ,
source_system_nm      varchar(255) ,
create_ts             datetime ,
update_ts             datetime ,
CONSTRAINT pk_treconciliation PRIMARY KEY (reconciliation_sk)
);




