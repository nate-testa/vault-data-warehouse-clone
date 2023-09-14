--

CREATE TABLE edw_core.tbroker
(
broker_sk                int IDENTITY(1,1) NOT NULL,
broker_id                varchar(255) NOT NULL,
broker_nm                varchar(255), 
dba_nm                   varchar(255), 
broker_status            varchar(255),
broker_type              varchar(255),
entity_type              varchar(255),
tax_id_type              varchar(255),
tax_id                   varchar(255),
agency_management_system_nm varchar(255),
ivans_user_nm            varchar(255),     
ivans_y_account          varchar(255),
lexis_nexis_company_code_suffix varchar(255),
primary_contact_nm       varchar(255),
broker_phone_no                  varchar(255),
broker_email                     varchar(255),
newbusiness_contact_email        varchar(255),
renewal_contact_email            varchar(255),
policy_change_contact_email      varchar(255),
claims_contact_email         	 varchar(255),
primary_address_line_1           varchar(255),
primary_address_line_2           varchar(255),
primary_address_unit_no                  varchar(255),  
primary_address_city_nm                  varchar(255),
primary_address_state_cd                 varchar(255),
primary_address_zip_cd                   varchar(255),
primary_address_county_nm                varchar(255),
primary_address_country_nm               varchar(255),
mailing_address_same_as_primary_in       varchar(255), 
mailing_address_line_1           varchar(255),
mailing_address_line_2           varchar(255),
mailing_address_unit_no                  varchar(255),  
mailing_address_city_nm                  varchar(255),
mailing_address_state_cd                 varchar(255),
mailing_address_zip_cd                   varchar(255),
mailing_address_county_nm                varchar(255),
mailing_address_country_nm               varchar(255),
location_address_same_as_primary_in       varchar(255),
location_address_line_1           varchar(255),
location_address_line_2           varchar(255),
location_address_unit_no                  varchar(255),  
location_address_city_nm                  varchar(255),
location_address_state_cd                 varchar(255),
location_address_zip_cd                   varchar(255),
location_address_county_nm                varchar(255),
location_address_country_nm               varchar(255),
commission_address_same_as_primary_in       varchar(255),
commission_address_line_1           varchar(255),
commission_address_line_2           varchar(255),
commission_address_unit_no                  varchar(255),  
commission_address_city_nm                  varchar(255),
commission_address_state_cd                 varchar(255),
commission_address_zip_cd                   varchar(255),
commission_address_county_nm                varchar(255),
commission_address_country_nm               varchar(255),
insurance_company_nm  						varchar(255),
insurance_policy_no  						varchar(255),
insurance_policy_limit_amt  				varchar(255),
insurance_policy_effective_dt  				varchar(255),
insurance_policy_expiration_dt  			varchar(255),
company_nm						  			varchar(255),
bank_nm						  			    varchar(255),
routing_no                                  varchar(255),
account_no                                  varchar(255),
accounting_type                             varchar(255),
token_id	                                varchar(255),
commission_statement_email	                varchar(255),
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tbroker PRIMARY KEY (broker_sk),
CONSTRAINT uidx_tbroker_broker_id UNIQUE (broker_id)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker','Type-1 Dimension','Base','Broker','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   
CREATE TABLE edw_core.tbroker_commission
(
broker_commission_sk      int IDENTITY(1,1) NOT NULL,
broker_id                varchar(255) NOT NULL,
broker_sk                int NOT NULL,
state_cd                 varchar(255),
product_nm               varchar(255),
coverage_cd              varchar(255),
program_type             varchar(255),
business_type            varchar(255),
effective_dt             date,
expiration_dt            date,
commission_pc            float,
broker_commission_status              varchar(255),
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tbroker_commission PRIMARY KEY (broker_commission_sk),
CONSTRAINT fk_tbroker_commission_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_commission','Type-2 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate());   
   
CREATE TABLE edw_core.tbroker_vault_team
(
broker_vault_team_sk     int IDENTITY(1,1) NOT NULL,
broker_id                varchar(255) NOT NULL,
broker_sk                int NOT NULL,
state_cd                 varchar(255),
product_nm               varchar(255),
program_type             varchar(255),
team_member_type         varchar(255),
team_member_nm           varchar(255),
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tbroker_vault_team PRIMARY KEY (broker_vault_team_sk),
CONSTRAINT fk_tbroker_vault_team_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_vault_team','Type-1 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate());    
   
CREATE TABLE edw_core.tproducer
(
producer_sk          int IDENTITY(1,1) NOT NULL,
broker_id                varchar(255) NOT NULL,
broker_sk                int NOT NULL,
first_nm                 varchar(255),
last_nm                  varchar(255),
title                    varchar(255),
email                    varchar(255),
phone_no                 varchar(255),
national_producer_no     varchar(255),
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tproducer PRIMARY KEY (producer_sk),
CONSTRAINT fk_tproducer_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tproducer','Type-1 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate());  
   
CREATE TABLE edw_core.tbroker_license
(
broker_license_sk        int IDENTITY(1,1) NOT NULL,
broker_id                varchar(255) NOT NULL,
broker_sk                int NOT NULL,
state_cd                 varchar(255),
license_no               varchar(255),
expiration_dt            date,
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tbroker_license PRIMARY KEY (broker_license_sk),
CONSTRAINT fk_tbroker_license_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_license','Type-1 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate());     

    