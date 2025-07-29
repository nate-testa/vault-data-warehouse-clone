CREATE TABLE edw_integration.policy_honk_vehicle_feed (
    policy_number  varchar(255) ,
	vin  varchar(255) ,
	vehicle_make  varchar(255) ,
	vehicle_model  varchar(255) ,
	vehicle_year  varchar(255) ,
	coverage_amount_tow int,
	coverage_amount_accident int,
	coverage_soft_services varchar(255),
	create_ts datetime ,
  	update_ts datetime ,
  	etl_audit_sk int,
    CONSTRAINT pk_policy_honk_vehicle_feed PRIMARY KEY(policy_number,vin)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('policy_honk_vehicle_feed','Feed','This table provides daily policy and associated vehicles data feed to Honk','Stored Procedure','Insert/Update','Daily',getdate(),getdate());