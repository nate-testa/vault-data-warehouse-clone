CREATE TABLE edw_integration.producer_hubspot_feed 
(  
    broker_id varchar(255) NOT NULL,
    producer_id varchar(255) NOT NULL,
    email varchar(255) , 
    first_nm varchar(255) , 
    last_nm varchar(255) , 
    phone_no varchar(255), 
    broker_status varchar(255), 
    title varchar(255), 
    producer_role varchar(255), 
    producer_status varchar(255), 
    create_ts datetime NOT NULL,
    update_ts datetime NOT NULL,
    etl_audit_sk int NOT NULL, 
CONSTRAINT pk_producer_hubspot_feed PRIMARY KEY(broker_id,producer_id)
); 

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,load_frequency,create_ts,update_ts)
VALUES ('producer_hubspot_feed','Feed','This table provides broker user/producer data to Hubspot','Stored Procedure','Full Load','Daily',getdate(),getdate());