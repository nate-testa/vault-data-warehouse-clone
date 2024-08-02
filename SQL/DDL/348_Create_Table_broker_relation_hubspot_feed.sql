CREATE TABLE edw_integration.broker_relation_hubspot_feed
( 
    parent_broker_id varchar(255) NOT NULL,
    child_broker_id varchar(255) NOT NULL,   
    relationship_type varchar(255) NOT NULL, 
    create_ts datetime NOT NULL,
    update_ts datetime NOT NULL,
    etl_audit_sk int NOT NULL, 
CONSTRAINT pk_broker_relation_hubspot_feed PRIMARY KEY(parent_broker_id,child_broker_id)
); 

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,load_frequency,create_ts,update_ts)
VALUES ('broker_relation_hubspot_feed','Feed','This table provides broker hierarchy data to Hubspot','Stored Procedure','Full Load','Daily',getdate(),getdate());