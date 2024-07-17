CREATE TABLE edw_integration.customer_hubspot_feed
( 
  policy_no varchar(255) NOT NULL,
  first_nm varchar(255) NOT NULL, 
  last_nm varchar(255) NOT NULL, 
  email varchar(255) NOT NULL, 
  risk_state_cd varchar(255) NOT NULL, 
  product_nm varchar(255) NOT NULL,  
  broker_id varchar(255) NOT NULL, 
  bdm_nm varchar(255), 
  broker_nm varchar(255) , 
  broker_phone_no varchar(255), 
  policy_status varchar(255) NOT NULL,
  create_ts datetime NOT NULL,
update_ts datetime NOT NULL,
etl_audit_sk int NOT NULL, 
CONSTRAINT pk_customer_hubspot_feed PRIMARY KEY(policy_no)
); 

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,load_frequency,create_ts,update_ts)
VALUES ('customer_hubspot_feed','Feed','This table provides customer policy data to Hubspot','Stored Procedure','Insert/Update','Daily',getdate(),getdate());