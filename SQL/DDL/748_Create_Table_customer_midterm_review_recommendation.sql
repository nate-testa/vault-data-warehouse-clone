IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_name = 'customer_midterm_review_recommendation')
BEGIN

create table edw_integration.customer_midterm_review_recommendation
(
	customer_id varchar(255),
	risk_state_cd varchar(255),
	[mailing_address_state_cd] varchar(255),
	uw_company_cd varchar(255),
	renewal_year int,
	product_nm varchar(255),
	existing_product_in varchar(255),
	existing_policy_no varchar(255),
	occupancy_type varchar(255),
	primary_home_discount_pc varchar(255), --decimal(5,2),
/*
    homeowners_discount_pc decimal(5,2),
	homeowners_discount_cap_amt decimal(15,2),
	auto_discount_pc decimal(5,2),
	auto_discount_cap_amt decimal(15,2),
	pel_discount_pc decimal(5,2),
	pel_discount_cap_amt decimal(15,2),
	collections_discount_pc decimal(5,2),
	collections_discount_cap_amt decimal(15,2),
	marine_discount_pc decimal(5,2),
	marine_discount_cap_amt decimal(15,2),
*/
	rms_recommendation varchar(255),
    wildfire_protection_recommendation varchar(255), 
    backup_generator_recommendation varchar(255), 
	product_recommendation varchar(255),
	etl_audit_sk int not null,
	create_ts datetime2(7),
	update_ts datetime2(7),
	CONSTRAINT pk_customer_midterm_review_recommendation PRIMARY KEY (customer_id, renewal_year, product_nm, existing_policy_no)
);
END;

IF EXISTS
(SELECT 1 FROM edw_integration.tintegration_table_detail
	where table_nm = 'customer_midterm_review_recommendation')
BEGIN
	delete edw_integration.tintegration_table_detail
	where table_nm = 'customer_midterm_review_recommendation' ; 
END ;   

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
VALUES ('customer_midterm_review_recommendation','Feed','This table holds customers product recommendation for midterm review','Stored Procedure','Full Load','Daily',getdate(),getdate());