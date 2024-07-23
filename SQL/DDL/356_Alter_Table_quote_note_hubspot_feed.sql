CREATE TABLE edw_integration.quote_note_hubspot_feed
( 
  quote_no varchar(255) NOT NULL,
  note_desc nvarchar(max) null,
  note_created_ts datetime null,
  note_updated_ts datetime null,
  note_id varchar(255) not null,
  create_ts datetime NOT NULL,
  update_ts datetime NOT NULL,
  etl_audit_sk int NOT NULL, 
CONSTRAINT pk_quote_note_hubspot_feed PRIMARY KEY(note_id)
); 

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,load_frequency,create_ts,update_ts)
VALUES ('quote_note_hubspot_feed','Feed','This table provides notes data to Hubspot','Stored Procedure','Insert/Update','Daily',getdate(),getdate());