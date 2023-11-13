CREATE TABLE [edw_core].[tquote]
(
	[quote_sk] [int] IDENTITY(1,1) NOT NULL,
	[quote_no] [varchar](255) NOT NULL,
	[effective_dt] [date] NOT NULL,
	[expiration_dt] [date] NOT NULL,
	[broker_id] [varchar](255) NOT NULL,
	[customer_id] [varchar](255) NOT NULL,
	[product_cd] [varchar](255) NOT NULL,
	[risk_state_cd] [varchar](255) NOT NULL,
	[insured_nm] [varchar](255) NULL,
	[insured_type] [varchar](255) NULL,
	[uw_company_nm] [varchar](255) NULL,
	[program_type] [varchar](255) NULL,
	 quote_term [varchar](255) NULL,
	[quote_status] [varchar](255) NULL,
	 quote_source_status [varchar](255) ,
	[original_policy_no] [varchar](255) NULL,
	[original_policy_effective_dt] [date] NULL,
	[mailing_address_line1] [varchar](255) NULL,
	[mailing_address_line2] [varchar](255) NULL,
	[mailing_address_unit_no] [varchar](255) NULL,
	[mailing_address_city_nm] [varchar](255) NULL,
	[mailing_address_state_cd] [varchar](255) NULL,
	[mailing_address_zip_cd] [varchar](255) NULL,
	[mailing_address_county_nm] [varchar](255) NULL,
	[mailing_address_country_nm] [varchar](255) NULL,
	[prior_policy_no] [varchar](255) NULL,
	[billingaccount_sk] [int] NULL,
	[prior_term_policy_no] [varchar](255) NULL,
	 quote_create_ts datetime2(7) , 
 	first_offered_quote_ts datetime2(7) , 
 	policy_sk int, 
 	prior_term_policy_sk int,
 	first_offered_quote_history_sk int,
 	bind_dt date,
	migrated_in varchar(255),
	[source_system_sk] [int] NOT NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
    CONSTRAINT [pk_tquote] PRIMARY KEY (quote_sk),
    CONSTRAINT uidx_tquote_quote_no UNIQUE (quote_no)
) ;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote','Type-1 Dimension','Base','Quote','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE [edw_core].[tquote_history](
	[quote_history_sk] [int] IDENTITY(1,1) NOT NULL,
	[quote_no] [varchar](255) NOT NULL,
	[effective_dt] [date] NOT NULL,
	[expiration_dt] [date] NOT NULL,
	[transaction_effective_dt] [date] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[latest_transaction_in] [varchar](255) NULL,
	[quote_sk] [int] NULL,
	[broker_sk] [int] NULL,
	[customer_sk] [int] NULL,
	[product_sk] [int] NULL,
	[broker_id] [varchar](255) NULL,
	[customer_id] [varchar](255) NULL,
	[underwriter_nm] [varchar](255) NULL,
	[producer_nm] [varchar](255) NULL,
	[transaction_type] [varchar](255) NULL,
    [transaction_status] [varchar](255) NULL,
	not_taken_reason_desc [varchar](2000) NULL,
	[transaction_created_ts] datetime2(7) NULL,
	[transaction_updated_ts] datetime2(7) NULL,
	[transaction_desc] [varchar](4000) NULL,
	bind_dt  date,
	created_by_nm  [varchar](255) NULL,
	referred_by_nm  [varchar](255) NULL,
	reviewed_by_nm [varchar](255) NULL,
	approval_note  nvarchar(max),
	deny_note nvarchar(max),
	[policy_change_summary] [nvarchar](max) NULL,
	[premium_amt] [decimal](15, 2) NULL,
	[net_premium_amt] [decimal](15, 2) NULL,
	[tax_fee_surcharge_amt] [decimal](15, 2) NULL,
	[commission_amt] [decimal](15, 2) NULL,
	[annual_premium_amt] [decimal](15, 2) NULL,
	[collection_policy_credit_in] [varchar](255) NULL,
	[excess_liability_policy_credit_in] [varchar](255) NULL,
	[auto_policy_credit_in] [varchar](255) NULL,
	[home_policy_credit_in] [varchar](255) NULL,
	[prior_address_in] [varchar](255) NULL,
	[prior_address_line_1] [varchar](255) NULL,
	[prior_address_line_2] [varchar](255) NULL,
	[prior_address_unit_no] [varchar](255) NULL,
	[prior_address_city_nm] [varchar](255) NULL,
	[prior_address_state_cd] [varchar](255) NULL,
	[prior_address_zip_cd] [varchar](255) NULL,
	[prior_address_county_nm] [varchar](255) NULL,
	[prior_address_country_nm] [varchar](255) NULL,
	[source_system_sk] [int] NOT NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
	[commission_pc] [float] NULL,
	[override_commission_pc] [float] NULL,
	[commission_retention] [varchar](255) NULL,
    CONSTRAINT [pk_tquote_history] PRIMARY KEY (quote_history_sk),
    CONSTRAINT [uidx_tquote_history_quoteno_effdt_transeq] UNIQUE (quote_no,effective_dt,transaction_seq_no),
    CONSTRAINT fk_tquote_history_quote_sk FOREIGN KEY (quote_sk) REFERENCES  edw_core.tquote(quote_sk),
CONSTRAINT fk_tqh_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tqh_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_history','Type-2 Dimension','Base','Quote','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.tquote_transaction_status_history
(
quote_transaction_status_history_sk int IDENTITY(1,1) NOT NULL,
quote_no varchar(255) NOT NULL,
effective_dt date NOT NULL,
transaction_seq_no int NOT NULL,
quote_history_sk int NOT NULL,
quote_sk int NOT NULL,
user_sk  int ,
user_nm varchar(255),
transaction_type varchar(255),
transaction_status varchar(255),
transaction_ts datetime2(7),
source_system_sk int NULL,
create_ts datetime NULL,
update_ts datetime NULL,
etl_audit_sk int NULL,
CONSTRAINT pk_tquote_transaction_status_history PRIMARY KEY (quote_transaction_status_history_sk),
CONSTRAINT fk_tquote_transaction_status_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk),
CONSTRAINT fk_tquote_transaction_status_quote_sk FOREIGN KEY (quote_sk) REFERENCES edw_core.tquote(quote_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_transaction_status_history','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE edw_core.tquote_status_history
(
quote_status_history_sk int IDENTITY(1,1) NOT NULL,
quote_no varchar(255) NOT NULL,
effective_dt date NOT NULL,
quote_sk int NOT NULL,
user_sk  int ,
user_nm  varchar(255),
transaction_type varchar(255),
transaction_status varchar(255),
transaction_ts datetime2(7),
source_system_sk int NULL,
create_ts datetime NULL,
update_ts datetime NULL,
etl_audit_sk int NULL,
CONSTRAINT pk_tquote_status_history PRIMARY KEY (quote_status_history_sk),
CONSTRAINT fk_tquote_status_history_quote_sk FOREIGN KEY (quote_sk) REFERENCES edw_core.tquote(quote_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_status_history','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tquote_additional_interest (
	quote_additional_interest_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	additional_interest_seq_no int NOT NULL,
	product_cd varchar(255) ,
	interest_type varchar(255) ,
	entity_type varchar(255) ,
	entity_nm varchar(255) ,
	property_desc varchar(4000) ,
	first_nm varchar(255) ,
	last_nm varchar(255) ,
	vehicle_desc varchar(2000) ,
	vehicle_ownership varchar(255) ,
	loss_payee_nm varchar(255) ,
	additional_interest_nm varchar(255) ,
	address_line_1 varchar(255) ,
	address_line_2 varchar(255) ,
	unit_no varchar(255) ,
	city_nm varchar(255) ,
	county_nm varchar(255) ,
	state_cd varchar(255) ,
	zip_cd varchar(255) ,
	country_nm varchar(255) ,
	commercial_exposures_in varchar(255) ,
	watercraft_or_employ_crew_in varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_additional_interest PRIMARY KEY (quote_additional_interest_sk),
    CONSTRAINT fk_tquote_additional_interest_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
        
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_additional_interest','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

    -- edw_core.tquote_loss_history definition


CREATE TABLE edw_core.tquote_loss_history (
	quote_loss_history_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255)  NOT NULL ,
	effective_dt date  NOT NULL,
	expiration_dt date  NOT NULL,
	transaction_seq_no int NULL,
	quote_history_sk int NULL,
	loss_seq_no int NOT NULL,
	property_or_liability varchar(255) ,
	source_nm varchar(255) ,
	claim_status varchar(255) ,
	claimant_nm varchar(255) ,
	file_no varchar(255) ,
	loss_dt date NULL,
	loss_indentifier varchar(255) ,
	type_of_loss varchar(255) ,
	sub_cause_of_loss_desc varchar(255) ,
	loss_desc nvarchar(MAX) ,
	policy_type varchar(255) ,
	cat_loss_in varchar(255) ,
	cat_cd varchar(255) ,
	disputed_in varchar(255) ,
	include_in_rating_in varchar(255) ,
	loss_address_line_1 varchar(255) ,
	loss_address_line_2 varchar(255) ,
	loss_address_unit_no varchar(255) ,
	loss_address_city_nm varchar(255) ,
	loss_address_state_cd varchar(255) ,
	loss_address_zip_cd varchar(255) ,
	coverage_desc varchar(255) ,
	indemnity_reserve_amt decimal(15,2) NULL,
	expense_reserve_amt decimal(15,2) NULL,
	indemnity_paid_amt decimal(15,2) NULL,
	expense_paid_amt decimal(15,2) NULL,
	total_incurred_amt decimal(15,2) NULL,
	source_system_sk int NOT NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_loss_history PRIMARY KEY (quote_loss_history_sk),
	CONSTRAINT fk_tquote_loss_history_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_loss_history','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE edw_core.tquote_mortgagee (
	quote_mortgage_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	mortgagee_no int NOT NULL,
	mortgagee_nm varchar(255) ,
	mortgagee_type varchar(255) ,
	bill_mortgagee_in varchar(255) ,
	email varchar(255) ,
	fax_no varchar(255) ,
	phone_no varchar(255) ,
	isao_atima varchar(255) ,
	isao_atima_other varchar(255) ,
	loan_no varchar(255) ,
	address_line_1 varchar(255) ,
	address_line_2 varchar(255) ,
	unit_no varchar(255) ,
	city_nm varchar(255) ,
	state_cd varchar(255) ,
	zip_cd varchar(255) ,
	county_nm varchar(255) ,
	country_nm varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_mortgagee PRIMARY KEY (quote_mortgage_sk),
	CONSTRAINT fk_tquote_mortgagee_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_mortgagee','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE [edw_core].[tquote_insured](
	[quote_insured_sk] [int] IDENTITY(1,1) NOT NULL,
	[quote_no] [varchar](255) NOT NULL,
	[effective_dt] [date] NOT NULL,
	[transaction_seq_no] [int] NOT NULL,
	[quote_history_sk] [int] NOT NULL,
	[insured_nm] [varchar](255) NULL,
	[dba_nm] [varchar](255) NULL,
	[first_nm] [varchar](255) NULL,
	[middle_nm] [varchar](255) NULL,
	[last_nm] [varchar](255) NULL,
	[insured_type] [varchar](255) NULL,
	[primary_insured_in] [varchar](255) NULL,
	[coinsured_in] [varchar](255) NULL,
	[birth_dt] [date] NULL,
	[home_phone_no] [varchar](255) NULL,
	[mobile_phone_no] [varchar](255) NULL,
	[title] [varchar](255) NULL,
	[prefix] [varchar](255) NULL,
	[suffix] [varchar](255) NULL,
	[mailing_address_line_1] [varchar](255) NULL,
	[mailing_address_line_2] [varchar](255) NULL,
	[mailing_address_unit_no] [varchar](255) NULL,
	[mailing_address_city_nm] [varchar](255) NULL,
	[mailing_address_state_cd] [varchar](255) NULL,
	[mailing_address_zip_cd] [varchar](255) NULL,
	[mailing_address_county_nm] [varchar](255) NULL,
	[mailing_address_country_nm] [varchar](255) NULL,
	[include_on_dec_in] [varchar](255) NULL,
	[email] [varchar](255) NULL,
	[employer_nm] [varchar](255) NULL,
	[insurance_score] [varchar](255) NULL,
	[insurance_score_cd1] [varchar](255) NULL,
	[insurance_score_desc1] [varchar](255) NULL,
	[insurance_score_cd2] [varchar](255) NULL,
	[insurance_score_desc2] [varchar](255) NULL,
	[insurance_score_cd3] [varchar](255) NULL,
	[insurance_score_desc3] [varchar](255) NULL,
	[insurance_score_cd4] [varchar](255) NULL,
	[insurance_score_desc4] [varchar](255) NULL,
	[subscriber_contribution_end_dt] [date] NULL,
	[source_system_sk] [int] NOT NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
	[occupation_desc] [varchar](255) NULL,
	CONSTRAINT pk_tquote_insured PRIMARY KEY (quote_insured_sk),
	CONSTRAINT fk_tquote_insured_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
) ;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_insured','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE edw_core.tquote_transaction
(
	quote_transaction_sk int IDENTITY(1,1) NOT NULL,
	quote_sk int NOT NULL,
	quote_history_sk int NOT NULL,
	effective_dt_sk int NOT NULL,
	expiration_dt_sk int NOT NULL,
	transaction_effective_dt_sk int NOT NULL,
	transaction_seq_no int NOT NULL,
	broker_sk int NOT NULL,
	customer_sk int NOT NULL,
	premium_amt decimal(15, 2) NULL,
	net_premium_amt decimal(15, 2) NULL,
	commission_amt decimal(15, 2) NULL,
	annual_premium_amt decimal(15, 2) NULL,
	tax_fee_surcharge_amt decimal(15, 2) NULL,
	item_sk int NULL,
	coverage_sk int NULL,
	vehicle_coverage_sk int NULL,
	transaction_dt_sk int NOT NULL,
	product_sk int NOT NULL,
	--quote_transaction_type_sk int NOT NULL,
	internal_coverage_sk int NULL,
	source_system_sk int NOT NULL,
	--quote_status_sk int NOT NULL,
	tax_fee_surcharge_sk int NULL,
	user_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	ceded_premium_amt decimal(15, 2) NULL,
	ceded_annual_premium_amt decimal(15, 2) NULL,
CONSTRAINT pk_tquote_transaction PRIMARY KEY (quote_transaction_sk),
CONSTRAINT fk_tquote_transaction_policy_sk FOREIGN KEY (quote_sk) REFERENCES  edw_core.tquote(quote_sk),
CONSTRAINT fk_tquote_transaction_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tquote_transaction_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tquote_transaction_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
CONSTRAINT fk_tquote_transaction_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk),
CONSTRAINT fk_tquote_transaction_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
) 
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_transaction','Fact','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());