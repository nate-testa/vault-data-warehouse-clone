
CREATE TABLE edw_core.tproduct (
  product_sk int IDENTITY(1,1) NOT NULL,
  product_cd varchar(255) DEFAULT NULL,
  product_nm varchar(255) DEFAULT NULL,
  ebao_product_cd varchar(255) DEFAULT NULL,
  update_ts datetime DEFAULT NULL ,
  CONSTRAINT pk_tproduct PRIMARY KEY (product_sk)
);

EXEC sys.sp_addextendedproperty 'MS_Description', N'Product code', 'schema', N'edw_core', 'table', N'tproduct', 'column', N'product_cd';
EXEC sys.sp_addextendedproperty 'MS_Description', N'Product description', 'schema', N'edw_core', 'table', N'tproduct', 'column', N'product_desc';
EXEC sys.sp_addextendedproperty 'MS_Description', N'Surrogate key', 'schema', N'edw_core', 'table', N'tproduct', 'column', N'product_sk';
EXEC sys.sp_addextendedproperty 'MS_Description', N'eBao product code', 'schema', N'edw_core', 'table', N'tproduct', 'column', N'ebao_product_cd';
EXEC sys.sp_addextendedproperty 'MS_Description', N'Last update timestamp', 'schema', N'edw_core', 'table', N'tproduct', 'column', N'update_ts';
EXEC sys.sp_addextendedproperty 'MS_Description', N'This is a reference table consists of product types and their description', 'schema', N'edw_core', 'table', N'tproduct';

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tproduct','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.tsource_system (
  source_system_sk int IDENTITY(1,1) NOT NULL,
  source_system_nm varchar(255) NOT NULL,
  update_ts datetime ,
  CONSTRAINT pk_tsource_system PRIMARY KEY (source_system_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tsource_system','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.tdate (
  date_sk int IDENTITY(1,1) NOT NULL,
  actual_dt date NOT NULL,
  calendar_year int NOT NULL,
  yearmonth int NOT NULL,
  month_nm varchar(255) NOT NULL,
  day_nm varchar(255) NOT NULL,
  year_quarter varchar(6)  NOT NULL,
  accounting_month int  NULL,
  month_end_in   varchar(255) NOT NULL DEFAULT 'N',
  create_ts datetime ,
  update_ts datetime ,
  CONSTRAINT pk_tdate PRIMARY KEY (date_sk),
  CONSTRAINT uidx_tdate_actual_dt UNIQUE (actual_dt),
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tdate','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.tstate (
  state_sk int IDENTITY(1,1) NOT NULL,
  state_cd varchar(255) NOT NULL,
  state_nm varchar(255) NOT NULL,
  update_ts datetime ,
  CONSTRAINT pk_tstate PRIMARY KEY (state_sk),
  CONSTRAINT uidx_tstate_state_cd UNIQUE (state_cd),
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tstate','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.tcustomer  
(
customer_sk               int IDENTITY(1,1) NOT NULL,
customer_id               varchar(255) NOT NULL,
customer_nm               varchar(255),
first_nm                  varchar(255),
middle_nm                 varchar(255),
last_nm                   varchar(255),
insured_type              varchar(255),
home_phone_no             varchar(255),
mobile_phone_no           varchar(255),
birth_dt                  date,
occupation_desc           varchar(255),
employer_nm               varchar(255),
prefix                    varchar(255),
suffix                    varchar(255),
title                     varchar(255),  
email                     varchar(255),
agency_id                 varchar(255),
mailing_address_line1         varchar(255),  
mailing_address_line2         varchar(255),
mailing_address_unit_no       varchar(255),
mailing_address_city_nm       varchar(255),
mailing_address_state_cd      varchar(255),
mailing_address_zip_cd        varchar(255), 
mailing_address_county_nm     varchar(255),
mailing_address_country_nm    varchar(255),
family_account_in         varchar(255),
vip_in                    varchar(255),  
create_ts                 datetime,
update_ts                 datetime,
etl_audit_sk              int,
CONSTRAINT pk_tcustomer PRIMARY KEY (customer_sk),
CONSTRAINT uidx_tcustomer_customer_id UNIQUE (customer_id)
);

   
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcustomer','Type-1 Dimension','Base','Common','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.tinternal_coverage
(
internal_coverage_sk      int IDENTITY(1,1) NOT NULL,
internal_coverage_cd      varchar(255) NOT NULL,
product_cd                varchar(255) NOT NULL,
internal_coverage_desc    varchar(255) ,
aslob_cd                  varchar(255) ,
internal_coverage_category_nm  varchar(255) ,
create_ts                 datetime,
update_ts                 datetime,
CONSTRAINT pk_tinternal_coverage PRIMARY KEY (internal_coverage_sk),
CONSTRAINT uidx_tinternal_coverage UNIQUE (internal_coverage_cd,product_cd)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tinternal_coverage','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.tpolicy_transaction_type (
  policy_transaction_type_sk int IDENTITY(1,1) NOT NULL,
  policy_transaction_type_cd varchar(255) NOT NULL,
  policy_transaction_type_nm varchar(255) NOT NULL,
  update_ts datetime DEFAULT NULL,
  CONSTRAINT pk_tpolicy_transaction_type PRIMARY KEY (policy_transaction_type_sk),
  CONSTRAINT uidx_tpolicy_transaction_type_policy_transaction_type_cd UNIQUE (policy_transaction_type_cd)
) ;


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_transaction_type','Type-1 Dimension','Base','Policy','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.ttax_fee_surcharge 
(
tax_fee_surcharge_sk   int IDENTITY(1,1) NOT NULL,
tax_fee_surcharge_cd   varchar(255) NOT NULL,
tax_fee_surcharge_desc varchar(255) NOT NULL,
tax_fee_surcharge_category_nm varchar(255),
create_ts              datetime,   
update_ts              datetime    
CONSTRAINT pk_ttax_fee_surcharge PRIMARY KEY (tax_fee_surcharge_sk),
CONSTRAINT uidx_ttax_fee_surcharge_tax_fee_surcharge_cd UNIQUE (tax_fee_surcharge_cd)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('ttax_fee_surcharge','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());


CREATE TABLE edw_core.tuser 
(
user_sk          int IDENTITY(1,1) NOT NULL,
user_id          varchar(255) NOT NULL,
first_nm         varchar(255),
last_nm          varchar(255),
email            varchar(255),
phone_no         varchar(255),
address_line1    varchar(255),
address_line2    varchar(255),
city_nm          varchar(255),
state_cd         varchar(255),
zip_cd           varchar(255),
branch_nm        varchar(255),
create_ts  		 datetime,
update_ts        datetime ,
etl_audit_sk      int
CONSTRAINT pk_tuser PRIMARY KEY (user_sk),
CONSTRAINT uidx_tuser_user_id UNIQUE (user_id)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tuser','Type-1 Dimension','Base','Common','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.tpolicy_status
(
policy_status_sk       int IDENTITY(1,1) NOT NULL,
policy_status_cd       varchar(255) NOT NULL,
policy_status_desc     varchar(255) NOT NULL,
update_ts              datetime,
CONSTRAINT pk_tpolicy_status PRIMARY KEY (policy_status_sk),
CONSTRAINT uidx_tpolicy_status_policy_status_cd UNIQUE (policy_status_cd)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_status','Type-1 Dimension','Base','Policy','Manual','Insert/Update','Static',getdate(),getdate());

CREATE TABLE edw_core.tpolicy
(
policy_sk                     int IDENTITY(1,1) NOT NULL,
policy_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
broker_id                     varchar(255) NOT NULL,
customer_id                   varchar(255) NOT NULL,
product_cd                    varchar(255) NOT NULL,
risk_state_cd                 varchar(255) NOT NULL,
insured_nm                    varchar(255),
insured_type                  varchar(255),
policy_term 	              varchar(255),
latest_term_in                varchar(255),
uw_company_nm                 varchar(255),
program_type			      varchar(255),
policy_status                 varchar(255),
cancellation_effective_dt     date,
original_policy_no            varchar(255),
original_policy_effective_dt  date,
mailing_address_line1         varchar(255),  
mailing_address_line2         varchar(255),
mailing_address_unit_no       varchar(255),
mailing_address_city_nm       varchar(255),
mailing_address_state_cd      varchar(255),
mailing_address_zip_cd        varchar(255), 
mailing_address_county_nm     varchar(255),
mailing_address_country_nm    varchar(255),
non_renewal_in     		      varchar(255),
prior_policy_no               varchar(255),
billingaccount_sk             int,
source_system_sk              int NOT NULL,
create_ts                     datetime,
update_ts                     datetime,
etl_audit_sk                  int,
CONSTRAINT pk_tpolicy PRIMARY KEY (policy_sk),
CONSTRAINT uidx_tpolicy_policy_no_effective_dt UNIQUE (policy_no,effective_dt)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());


CREATE TABLE edw_core.tpolicy_insured
(
policy_insured_sk             int IDENTITY(1,1) NOT NULL,
policy_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
transaction_effective_dt      date NOT NULL,
transaction_seq_no            int NOT NULL,
transaction_dt                date,
policy_history_sk             int,
insured_nm                    varchar(255),
dba_nm                        varchar(255),
first_nm                      varchar(255),             
middle_nm                     varchar(255),
last_nm                       varchar(255),
insured_type                  varchar(255),
primary_insured_in			  varchar(255),	
coinsured_in                  varchar(255),
birth_dt                      date, 
home_phone_no                 varchar(255), 
mobile_phone_no               varchar(255), 
title                         varchar(255),
prefix                        varchar(255),
suffix                        varchar(255), 
mailing_address_line_1        varchar(255),  
mailing_address_line_2        varchar(255),
mailing_address_unit_no       varchar(255),
mailing_address_city_nm       varchar(255),
mailing_address_state_cd      varchar(255),
mailing_address_zip_cd        varchar(255), 
mailing_address_county_nm     varchar(255),
mailing_address_country_nm    varchar(255),
include_on_dec_in             varchar(255),
email                         varchar(255),
employer_nm                    varchar(255), 
insurance_score                varchar(255),
insurance_score_cd1            varchar(255),
insurance_score_desc1          varchar(255),
insurance_score_cd2            varchar(255),
insurance_score_desc2          varchar(255),
insurance_score_cd3            varchar(255),
insurance_score_desc3          varchar(255),
insurance_score_cd4            varchar(255),
insurance_score_desc4          varchar(255),
subscriber_contribution_end_dt   date,
source_system_sk              int NOT NULL,
create_ts                     datetime,
update_ts                     datetime,
etl_audit_sk                  int,
CONSTRAINT pk_tpolicy_insured PRIMARY KEY (policy_insured_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_insured','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

ALTER TABLE edw_core.tpolicy_insured ADD occupation_desc varchar(255);

CREATE TABLE edw_core.tpolicy_history
(
policy_history_sk                   int IDENTITY(1,1) NOT NULL,
policy_no                           varchar(255) NOT NULL,
effective_dt                        date NOT NULL,
expiration_dt                       date NOT NULL,
transaction_effective_dt            date NOT NULL,
transaction_seq_no                  int NOT NULL,
latest_transaction_in               varchar(255),
policy_sk                           int,
broker_sk                           int,
customer_sk                         int,
product_sk                          int,
broker_id                           varchar(255),
customer_id                         varchar(255), 
underwriter_nm                      varchar(255),
producer_nm                         varchar(255),
transaction_type                    varchar(255),
transaction_ts                      datetime,
transaction_desc                    varchar(4000),
cancellation_reason_desc            varchar(4000),
policy_change_summary               nvarchar(max),
premium_amt                 		decimal(15,2),
net_premium_amt                     decimal(15,2),
tax_fee_surcharge_amt               decimal(15,2),
commission_amt                      decimal(15,2),
annual_premium_amt                  decimal(15,2),
transaction_initiated_by            varchar(255),
transaction_issued_by               varchar(255),
collection_policy_credit_in         varchar(255),
excess_liability_policy_credit_in   varchar(255),
auto_policy_credit_in               varchar(255),
home_policy_credit_in               varchar(255),  
prior_address_in             varchar(255),
prior_address_line_1        varchar(255),  
prior_address_line_2        varchar(255),
prior_address_unit_no       varchar(255),
prior_address_city_nm       varchar(255),
prior_address_state_cd      varchar(255),
prior_address_zip_cd        varchar(255), 
prior_address_county_nm     varchar(255),
prior_address_country_nm    varchar(255),
source_system_sk                    int NOT NULL,
create_ts                           datetime,
update_ts                           datetime,
etl_audit_sk                        int,
CONSTRAINT pk_tpolicy_history PRIMARY KEY (policy_history_sk),
CONSTRAINT uidx_tpolicy_history_polno_effdt_transeq UNIQUE (policy_no,effective_dt,transaction_seq_no),
CONSTRAINT fk_tph_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tph_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tph_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_history','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

-- eligibilty questions
-- policy transaction sub type

CREATE TABLE edw_core.tpolicy_transaction
(
policy_transaction_sk           int IDENTITY(1,1) NOT NULL,
policy_sk                       int NOT NULL,
effective_dt_sk                 int NOT NULL,
expiration_dt_sk                int NOT NULL,
transaction_effective_dt_sk     int NOT NULL,
transaction_seq_no	            int NOT NULL,
broker_sk                       int NOT NULL,
customer_sk                     int NOT NULL,
premium_amt             		decimal(15,2),
net_premium_amt                 decimal(15,2),
commission_amt                  decimal(15,2), 
annual_premium_amt              decimal(15,2),
tax_fee_surcharge_amt           decimal(15,2),
item_sk                         int,
coverage_sk                     int,
vehicle_coverage_sk             int,
transaction_dt_sk               int NOT NULL,  
calendar_month_sk               int NOT NULL,
accouting_month_sk              int NOT NULL,
product_sk                      int NOT NULL,
policy_transaction_type_sk		int NOT NULL,
internal_coverage_sk            int,
source_system_sk                int NOT NULL,
policy_status_sk                int NOT NULL,
tax_fee_surcharge_sk            int,
user_sk                         int,
create_ts                       datetime,
update_ts                       datetime,
etl_audit_sk                    int,
CONSTRAINT pk_tpolicy_transaction PRIMARY KEY (policy_transaction_sk),
CONSTRAINT fk_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
CONSTRAINT fk_tsource_system_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_transaction','Fact','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tloss_history
(
loss_history_sk            int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
loss_seq_no                int,
property_or_liability      varchar(255),
source_nm	               varchar(255),
claim_status               varchar(255),
claimant_nm                varchar(255),
file_no                    varchar(255),
loss_dt                    date,
loss_indentifier           varchar(255),
type_of_loss               varchar(255),
sub_cause_of_loss_desc      varchar(255),
loss_desc                  varchar(255),
policy_type                varchar(255),
cat_loss_in                varchar(255),
cat_cd                     varchar(255),
disputed_in                varchar(255),
include_in_rating_in        varchar(255),
loss_address_line_1        varchar(255),
loss_address_line_2        varchar(255),
loss_address_unit_no        varchar(255),
loss_address_city_nm                    varchar(255),
loss_address_state_cd                   varchar(255),
loss_address_zip_cd                     varchar(255),
coverage_desc              varchar(255),
indemnity_reserve_amt      decimal(15,2),
expense_reserve_amt        decimal(15,2),
indemnity_paid_amt         decimal(15,2),
expense_paid_amt           decimal(15,2),
total_incurred_amt         decimal(15,2),
source_system_sk                 int NOT NULL,
create_ts                        datetime,
update_ts                        datetime,
etl_audit_sk                        int,
CONSTRAINT pk_tloss_history PRIMARY KEY (loss_history_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tloss_history','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

   
CREATE TABLE edw_core.tadditional_interest
(
additional_interest_sk     int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
additional_interest_seq_no int,
product_cd    varchar(255) ,        
interest_type varchar(255) ,
entity_type varchar(255) ,
entity_nm varchar(255) ,
property_desc varchar(4000) ,
first_nm varchar(255) ,
last_nm varchar(255) ,
vehicle_desc varchar(2000),
vehicle_ownership  varchar(255), 
loss_payee_nm varchar(255), 
additional_interest_nm varchar(255),
address_line_1 varchar(255) ,
address_line_2 varchar(255) ,
unit_no       varchar(255) ,
city_nm varchar(255) ,
county_nm varchar(255) ,
state_cd varchar(255) ,
zip_cd varchar(255) ,
country_nm varchar(255) ,
commercial_exposures_in varchar(255) ,
watercraft_or_employ_crew_in  varchar(255) ,
/*valuable_bank_vaulted_jewelry_in varchar(255) ,
valuable_coins_in varchar(255) ,
valuable_collectibles_in varchar(255) ,
valuable_fine_arts_in varchar(255) ,
valuable_furs_in varchar(255) ,
valuable_guns_in varchar(255) ,
valuable_worldwide_jewelry_in varchar(255) ,
valuable_miscellaneous_in varchar(255) ,
valuable_musical_instruments_in varchar(255) ,
scheduled_classes varchar(255) ,
scheduled_items_in varchar(255) ,
valuable_silver_in varchar(255) ,
valuable_stamps_in varchar(255) ,
valuable_article_class_in varchar(255) ,
valuable_article_item_in varchar(255) ,
valuable_wearable_collectibles_in varchar(255) ,
*/
source_system_sk int ,
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int ,
CONSTRAINT pk_tadditional_interest PRIMARY KEY (additional_interest_sk)
);



INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tadditional_interest','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tbillingaccount
(
billingaccount_sk     int NOT NULL IDENTITY(1,1),
billingaccount_no          varchar(255),
effective_dt               date,
expiration_dt              date,
transaction_dt             date,
bill_type                 varchar(255),
payment_plan              varchar(255), 
payment_method            varchar(255), 
payor_nm                  varchar(255),
prefix                    varchar(255),
first_nm                  varchar(255),
middle_nm                 varchar(255),
last_nm                   varchar(255),
suffix                    varchar(255),
phone_no                  varchar(255),
birth_dt                  date,
email                     varchar(255), 
mailing_address_line_1 				varchar(255),
mailing_address_line_2 				varchar(255),
mailing_address_unit_no 			varchar(255),
mailing_city_nm						varchar(255),
mailing_state_cd 					varchar(255),
mailing_zip_cd 						varchar(255),
mailing_county_nm 					varchar(255),
mailing_country_nm 					varchar(255),
source_system_sk 			int ,
create_ts 					datetime ,
update_ts 					datetime ,
etl_audit_sk 				int,
CONSTRAINT pk_tbillingaccount PRIMARY KEY (billingaccount_sk),
CONSTRAINT uidx_tbillingaccount_billingaccount_no UNIQUE (billingaccount_no)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbillingaccount','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());  