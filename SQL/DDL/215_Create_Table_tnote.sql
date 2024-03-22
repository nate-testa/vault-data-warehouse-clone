
CREATE TABLE edw_core.tnote (
	note_sk int IDENTITY(1,1) NOT NULL,
	policy_no varchar(255) ,
	object_type varchar(255),
	user_first_nm varchar(255),
	user_last_nm varchar(255),
	user_sk int,
	note_desc nvarchar(max),
	note_created_ts datetime,
	note_updated_ts datetime,	
	customer_sk int,
	broker_sk int,
	producer_sk int,
	externally_shared_in varchar(1),
	flagged_in varchar(1),
	source_system_sk int ,
	create_ts datetime ,
	update_ts datetime ,
	etl_audit_sk int ,
    note_id varchar(255) ,
	CONSTRAINT pk_tnote PRIMARY KEY (note_sk),
	CONSTRAINT [uidx_tnote_note_id] UNIQUE NONCLUSTERED 
	(
	[note_id] ASC
)
);
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tnote','Type-2 Dimension','Base','Common','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
