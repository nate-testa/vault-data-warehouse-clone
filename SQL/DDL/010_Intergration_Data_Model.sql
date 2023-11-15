--metadata table

CREATE TABLE edw_integration.tintegration_table_detail 
(
    integration_table_detail_sk int IDENTITY(1,1) NOT NULL,
	table_nm varchar(255) ,
	table_type varchar(255) ,
 	table_desc nvarchar(max) ,
	load_method varchar(255) ,
	load_type varchar(255) ,
	load_frequency varchar(255),
	create_ts datetime NULL,
	update_ts datetime NULL,
	CONSTRAINT pk_tintegration_table_detail PRIMARY KEY (integration_table_detail_sk)
);


-- eBao Policy Search (All products)
CREATE TABLE edw_integration.claim_policy_search_api 
(
    policy_no varchar(255) ,
    effective_dt date ,
    expiration_dt date ,
    transaction_effective_dt date,
    transaction_seq_no int,
    policy_status varchar(255) , 
    insured_nm varchar(255), 
    insured_type varchar(255), 
    uw_company_nm varchar(255),
    product_nm varchar(255),
    transaction_type varchar(255),
    risk_item varchar(2000),
    source_system_nm varchar(255) ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int,
    CONSTRAINT uidx_claim_policy_search_api UNIQUE (policy_no, effective_dt, transaction_seq_no, risk_item)
--    CONSTRAINT pk_claim_policy_search_api PRIMARY KEY (policy_no, effective_dt, transaction_seq_no, risk_item)
);

CREATE INDEX idx_cpsa_policy_no ON [edw_integration].[claim_policy_search_api] ([policy_no]);
CREATE INDEX idx_cpsa_transaction_effective_dt ON [edw_integration].[claim_policy_search_api] ([transaction_effective_dt]);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_policy_search_api','API','This table provides policy details for claims registration purpose to support eBao claims API','Stored Procedure','Insert','Daily',getdate(),getdate());

-- Symbility Policy Search (Home/Condo)

CREATE TABLE edw_integration.claim_symbility_api (
    policy_no varchar(255) ,
    effective_dt date ,
    expiration_dt date ,
    transaction_effective_dt date ,
    transaction_seq_no int ,
    insured_type varchar(255) ,
    first_nm varchar(255) ,
    last_nm varchar(255) ,
    business_nm varchar(255) , -- This will be insured_nm
    home_phone_no  varchar(255) ,
    mobile_phone_no  varchar(255) ,
    email varchar(255) ,
    aop_deductible varchar(255),
    dwelling_limit_amt int,
    built_year int,
    source_system_nm varchar(255) ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int ,
    CONSTRAINT pk_claim_symbility_api PRIMARY KEY (policy_no,effective_dt,transaction_seq_no)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_symbility_api','API','This table provides policy details for Home claims to support eBao and Symbility integration API','Stored Procedure','Insert','Daily',getdate(),getdate());
   
-- HSB HSP

  
CREATE TABLE edw_integration.policy_hsb_hsp_feed (
  reporting_date date NOT NULL,
  company_product_cd varchar(4) ,
  product_nm varchar(3) ,
  contract_no varchar(7),
  policy_no varchar(20) NOT NULL,
  homeowner_policy_effective_dt varchar(8) NOT NULL,
  homeowner_policy_expiration_dt varchar(8),
  coverage_effective_dt varchar(8),
  original_homeowner_policy_effective_dt varchar(8),
  prior_homeowner_insurance_ind varchar(1),
  insured_nm varchar(255),
  dwelling_address varchar(255),
  dwelling_city varchar(255),
  dwelling_state varchar(255),
  dwelling_zip_cd varchar(255),
  hsp_net_premium_amt decimal(15,2),
  hsp_limit_amt int,
  hsp_deductible_amt varchar(255),
  base_homeowner_premium int ,
  final_homeowner_premium int,
  policy_deductible varchar(255),
  coverage_a_value int,
  coverage_b_value int,
  coverage_c_value int,
  homeowner_policy_form_no varchar(20),
  homeowners_or_dwelling_fire_policy_form_type varchar(5),
  product_form_no varchar(20) ,
  client_product_nm varchar(20) ,
  residence_type varchar(255) ,
  usage_type varchar(10) ,
  occupancy varchar(255) ,
  year_build int,
  total_living_area int,
  no_of_units_in_dwelling int,
  heating_system_updated_yr int,
  electrical_system_updated_yr int,
  plumbing_system_updated_yr int,
  distance_to_hydrant int,
  pricing_tier varchar(20),
  insurance_score int,
  rating_territory_cd varchar(20),
  protection_class_cd varchar(20),
  previous_policy_number varchar(20),
  agent_code varchar(20),
  branch_code varchar(20),
  source_system_nm varchar(255) ,
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int,
   CONSTRAINT pk_policy_hsb_hsp_feed PRIMARY KEY (reporting_date,policy_no,homeowner_policy_effective_dt)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_hsb_hsp_feed','Feed','This table provides Inforce Home System Protection ceded premium along with policy attributes to HSB','Stored Procedure','Insert','Monthly',getdate(),getdate());

   
-- HSB SLC

CREATE TABLE edw_integration.policy_hsb_slc_feed (
  reporting_date date NOT NULL,
  company_product_cd varchar(4) ,
  product_nm varchar(3) ,
  contract_no varchar(7),
  policy_no varchar(20) NOT NULL,
  homeowner_policy_effective_dt varchar(8) NOT NULL,
  homeowner_policy_expiration_dt varchar(8),
  coverage_effective_dt varchar(8),
  original_homeowner_policy_effective_dt varchar(8),
  prior_homeowner_insurance_ind varchar(1),
  insured_nm varchar(255),
  dwelling_address varchar(255),
  dwelling_city varchar(255),
  dwelling_state varchar(255),
  dwelling_zip_cd varchar(255),
  slc_net_premium_amt decimal(15,2),
  slc_limit_amt int,
  slc_deductible_amt varchar(255),
  base_homeowner_premium int ,
  final_homeowner_premium int,
  policy_deductible varchar(255),
  coverage_a_value int,
  coverage_b_value int,
  coverage_c_value int,
  homeowner_policy_form_no varchar(20),
  homeowners_or_dwelling_fire_policy_form_type varchar(5),
  product_form_no varchar(20) ,
  client_product_nm varchar(20) ,
  residence_type varchar(255) ,
  usage_type varchar(10) ,
  occupancy varchar(255) ,
  year_build int,
  total_living_area int,
  no_of_units_in_dwelling int,
  heating_system_updated_yr int,
  electrical_system_updated_yr int,
  plumbing_system_updated_yr int,
  distance_to_hydrant int,
  pricing_tier varchar(20),
  insurance_score int,
  rating_territory_cd varchar(20),
  protection_class_cd varchar(20),
  previous_policy_number varchar(20),
  agent_code varchar(20),
  branch_code varchar(20),
  source_system_nm varchar(255) ,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_hsb_slc_feed PRIMARY KEY (reporting_date,policy_no,homeowner_policy_effective_dt)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_hsb_slc_feed','Feed','This table provides Inforce Service Line ceded premium along with policy attributes to HSB','Stored Procedure','Insert','Monthly',getdate(),getdate());
   

-- HSB Cyber
 
CREATE TABLE edw_integration.policy_hsb_cyber_feed (
  reporting_date date NOT NULL,
  company_product_cd varchar(4) ,
  product_nm varchar(3) ,
  contract_no varchar(7),
  policy_no varchar(20) NOT NULL,
  coverage_effective_dt varchar(8) NOT NULL,
  coverage_expiration_dt varchar(8),
  insured_nm varchar(255),
  dwelling_address varchar(255),
  dwelling_city varchar(255),
  dwelling_state varchar(255),
  dwelling_zip_cd varchar(255),
  hcp_net_premium_amt decimal(15,2),
  hcp_deductible_amt varchar(255),
  coverage_a_value int,
  slc_limit_amt int,
  homeowner_policy_form_no varchar(20),
  product_form_no varchar(20) ,
  client_product_nm varchar(20) ,
  dwelling_type varchar(255) ,
  base_homeowner_premium int ,
  final_homeowner_premium int,
  policy_deductible varchar(255),
  year_build int,
  total_living_area int,
  no_of_units_in_dwelling int,
  email_address varchar(255),
  home_business varchar(1),
  previous_policy_number varchar(20),
  source_system_nm varchar(255) ,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_hsb_cyber_feed PRIMARY KEY (reporting_date,policy_no,coverage_effective_dt)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_hsb_cyber_feed','Feed','This table provides Inforce Cyber ceded premium along with policy attributes to HSB','Stored Procedure','Insert','Monthly',getdate(),getdate());
   
-- Workday Written Premium

 CREATE TABLE edw_integration.policy_workday_written_premium_feed 
 (
  accounting_date date ,
  policy_image_id int ,
  policy_image_identifier_id varchar(255) ,
  policy_number varchar(255),
  product varchar(255),
  transaction_sequence int,
  company varchar(255),
  transaction_date date,
  effective_date date,
  expiration_date date,
  transaction_type varchar(255),
  producer_code int,
  agency_name varchar(255),
  number_of_installments varchar(255),
  insured_name varchar(255),
  address varchar(255),
  county varchar(255),
  city varchar(255) ,
  risk_state varchar(255) ,
  zip varchar(255) ,
  fire_protection varchar(255) ,
  category varchar(255),
  subcategory varchar(255),
  financial_category_id varchar(255),
  financial_category_name varchar(255),
  aslob varchar(255),
  amount decimal(15,2),
  deleteddate date,
  contribcutoffdate date,
  extraction_time datetime,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_workday_written_premium_feed PRIMARY KEY (accounting_date,policy_number,effective_date,transaction_sequence,financial_category_id)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_workday_written_premium_feed','Feed','This table provides MTD written premium file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());

  
CREATE TABLE edw_integration.policy_workday_unearned_premium_feed 
(
  accounting_date date ,
  policy_image_id int ,
  policy_number varchar(255),
  product varchar(255),
  company varchar(255),
  transaction_date date,
  transaction_sequence int,
  effective_date date,
  expiration_date date,
  transaction_type varchar(255),
  producer_code int,
  agency_name varchar(255),
  number_of_installments varchar(255),
  insured_name varchar(255),
  address varchar(255),
  county varchar(255),
  city varchar(255) ,
  risk_state varchar(255) ,
  zip varchar(255) ,
  fire_protection varchar(255) ,
  category varchar(255),
  subcategory varchar(255),
  financial_category_id varchar(255),
  financial_category_name varchar(255),
  aslob varchar(255),
  amount decimal(15,2),
  unearned decimal(15,2),
  contribcutoffdate date,
  extraction_time datetime,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_workday_unearned_premium_feed PRIMARY KEY (accounting_date,policy_number,effective_date,transaction_sequence,financial_category_id)
);   

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_workday_unearned_premium_feed','Feed','This table provides ITD Unearned premium file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());
   
-- Workday Ceded Premium

CREATE TABLE edw_integration.policy_workday_ceded_premium_feed (
  accounting_date date ,
  policy_image_id int ,
  policy_image_identifier_id varchar(255) ,
  policy_number varchar(255),
  product varchar(255),
  company varchar(255),
  transaction_date date,
  transaction_sequence int,
  effective_date date,
  expiration_date date,
  transaction_type varchar(255),
  producer_code int,
  agency_name varchar(255),
  number_of_installments varchar(255),
  insured_name varchar(255),
  address varchar(255),
  county varchar(255),
  city varchar(255) ,
  risk_state varchar(255) ,
  zip varchar(255) ,
  fire_protection varchar(255) ,
  coveragename varchar(255),
  amount decimal(15,2),
  deleteddate date,
  contribcutoffdate date,
  extraction_time datetime,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_workday_ceded_premium_feed PRIMARY KEY (accounting_date,policy_number,effective_date,transaction_sequence)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_workday_ceded_premium_feed','Feed','This table provides ITD ceded premium file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());

CREATE TABLE edw_integration.claim_workday_reserve_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  reserve_type varchar(255),
  reserve_amount decimal(15,2),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  insuredname varchar(255) , 
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_workday_reserve_feed','Feed','This table provides MTD claims reserves file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());

   
   -- Workday PRISM Claims Reserves ITD

 CREATE TABLE edw_integration.claim_workday_itd_reserve_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  reserve_type varchar(255),
  reserve_amount decimal(15,2),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  insuredname varchar(255) , 
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_workday_itd_reserve_feed','Feed','This table provides ITD claims reserves file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());
    

-- Workday PRISM Claims Payments

 CREATE TABLE edw_integration.claim_workday_payment_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  paymenttype varchar(255),
  payeename varchar(255),
  paymentamount  decimal(15,2),
  settlementtype varchar(255),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_workday_payment_feed','Feed','This table provides MTD claims payments file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());
