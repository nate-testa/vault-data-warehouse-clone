-- Customer Billing Portal

CREATE TABLE edw_integration.billing_account_customer_portal_api 
( 
billingaccount_no varchar(255),
first_nm varchar(255),
last_nm varchar(255),
mailing_address_line_1 varchar(255),
mailing_address_line_2 varchar(255),
mailing_city_nm varchar(255),
mailing_state_cd varchar(255),
mailing_zip_cd varchar(255),
email varchar(255),
auto_pay_in varchar(255),
birth_dt date,
effective_dt date,
expiration_dt date,
payor_nm varchar(255),
phone_no varchar(255),
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int,
CONSTRAINT pk_billing_account_customer_portal_api PRIMARY KEY (billingaccount_no)
);

INSERT INTO	edw_integration.tintegration_table_detail (table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('billing_account_customer_portal_api','API','This table provides billing details to support customer portal registration process','Stored Procedure','Insert','Daily',getdate(),getdate());



CREATE TABLE edw_integration.policy_customer_portal_api 
( 
policy_no varchar(255),
billingaccount_no varchar(255),
product_nm varchar(255),
insured_nm varchar(255),
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int,
CONSTRAINT pk_policy_customer_portal_api PRIMARY KEY (billingaccount_no,policy_no)
);

INSERT INTO	edw_integration.tintegration_table_detail (table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('policy_customer_portal_api','API','This table provides policy details for a billing account to support customer portal','Stored Procedure','Insert','Daily',getdate(),getdate());
