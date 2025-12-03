IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_commercial' 
               AND TABLE_NAME = 'tcommercial_validation_sql')
BEGIN
CREATE TABLE edw_commercial.tcommercial_validation_sql (
  commercial_validation_sql_sk int IDENTITY(1,1) NOT NULL,
  commercial_validation_sql_desc varchar(255) ,
  source_sql varchar(4000) ,
  target_sql varchar(4000) ,
  active_in varchar(1) ,
  frequency_desc varchar(255) ,
  create_ts datetime NOT NULL,
  update_ts datetime NOT NULL,
   CONSTRAINT pk_tcommercial_validation_sql PRIMARY KEY (commercial_validation_sql_sk)
) END