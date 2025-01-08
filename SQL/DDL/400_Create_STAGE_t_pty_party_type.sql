-- edw_stage.t_pty_party_type definition

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 't_pty_party_type' AND schema_name(schema_id) = 'edw_stage')
BEGIN
CREATE TABLE edw_stage.t_pty_party_type (
  PARTY_TYPE varchar(3) NOT NULL,
  TYPE_NAME varchar(40) DEFAULT NULL,
  IS_ORG_PARTY char(1) NOT NULL,
  DESCRIPTION varchar(255) DEFAULT NULL,
  PARTY_CATE decimal(2,0) DEFAULT NULL,
  RECORD_USAGE decimal(1,0) DEFAULT NULL,
  PRIMARY KEY (PARTY_TYPE)
) ; 
END ; 