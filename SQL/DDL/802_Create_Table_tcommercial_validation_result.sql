IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_commercial' 
               AND TABLE_NAME = 'tcommercial_validation_result')
BEGIN
CREATE TABLE edw_commercial.tcommercial_validation_result (
  commercial_validation_result_sk int IDENTITY(1,1) NOT NULL,
  commercial_validation_sql_sk int,
  process_run_start_ts datetime,
  process_run_end_ts datetime,
  source_sql varchar(4000),
  target_sql varchar(4000),
  source_value decimal(15,2),
  target_value decimal(15,2),
  status_desc varchar(255),
  CONSTRAINT pk_tcommercial_validation_result PRIMARY KEY (commercial_validation_result_sk),
  CONSTRAINT fk_tcommercial_validation_result_validation_sql_sk FOREIGN KEY (commercial_validation_sql_sk) REFERENCES  edw_commercial.tcommercial_validation_sql(commercial_validation_sql_sk)
)END