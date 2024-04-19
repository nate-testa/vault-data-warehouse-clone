-- Creating new table for tbroker_relation
CREATE TABLE edw_core.tbroker_relation (
	broker_relation_sk int IDENTITY(1,1) NOT NULL,
	related_broker_id varchar(255),
	related_broker_sk int,
	relationship_type varchar(255),
	relation_broker_id varchar(255),
	relation_broker_sk int,
	billing_office_in varchar(255),
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tbroker_relation PRIMARY KEY (broker_relation_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_relation','Type-1 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate());
