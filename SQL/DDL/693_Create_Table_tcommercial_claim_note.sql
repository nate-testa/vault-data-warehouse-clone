CREATE TABLE edw_commercial.tcommercial_claim_note 
(
  commercial_claim_note_sk int NOT NULL IDENTITY(1,1),
  claim_no varchar(255)  ,
  commercial_claim_sk int  ,
  content_desc nvarchar(max),
  note_type varchar(255),
  note_created_by_nm varchar(255),
  note_created_ts datetime,
  contact_type varchar(255),
  overview_desc varchar(500),
  source_system_sk int,
  create_ts datetime,
  update_ts datetime,
  etl_audit_sk  int,
  commercial_claim_feature_sk int, 
  CONSTRAINT pk_tcommercial_claim_note PRIMARY KEY (commercial_claim_note_sk),
  CONSTRAINT fK_tcommercial_claim_note_claim_sk FOREIGN KEY (commercial_claim_sk) REFERENCES edw_commercial.tcommercial_claim (commercial_claim_sk)
) 
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_claim_note','Type-2 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
  