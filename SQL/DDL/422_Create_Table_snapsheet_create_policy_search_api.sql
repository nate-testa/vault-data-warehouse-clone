CREATE TABLE edw_integration.snapsheet_create_policy_search_api
(
	snapsheet_policy_search_api_sk int IDENTITY(1,1) NOT NULL,
	policy_no varchar(255),
	policy_type varchar(255),
	status varchar(255),
	product_code varchar(255),
	inception_date datetime,
	policy_entities nvarchar(max),
	expiration_dt date,
	transaction_effective_dt date,
	transaction_seq_no int,
	transaction_type varchar(255),
	source_system_nm varchar(255),
	api_process_date datetime,
	api_status varchar(255),
	api_error_description varchar(2000),
	create_ts datetime,
	update_ts datetime,
	etl_audit_sk int
	CONSTRAINT PK_snapsheet_create_policy_search_api PRIMARY KEY (snapsheet_policy_search_api_sk)
);