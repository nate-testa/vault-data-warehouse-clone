CREATE TABLE edw_integration.policy_honk_policyholder_feed (
    policy_number  varchar(255) ,
	first_name  varchar(255) ,
	last_name  varchar(255) ,
	address  varchar(255) ,
	city  varchar(255) ,
	state  varchar(255) ,
	postal_code varchar(255),
	create_ts datetime ,
  	update_ts datetime ,
  	etl_audit_sk int,
    CONSTRAINT pk_policy_honk_policyholder_feed PRIMARY KEY(policy_number,first_name,last_name)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('policy_honk_policyholder_feed','Feed','This table provides daily policy holders data feed to Honk','Stored Procedure','Insert/Update','Daily',getdate(),getdate());