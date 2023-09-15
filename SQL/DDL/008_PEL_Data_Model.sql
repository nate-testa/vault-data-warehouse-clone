CREATE TABLE edw_core.tpel_coverage
(
pel_coverage_sk            int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
pel_limit_amt              int,
uninsured_underinsured_motorist_liability_amt varchar(255),
uninsured_underinsured_liability_amt varchar(255),
employment_practices_liability_amt   varchar(255),
private_staff_ct                 int,
allegation_by_private_staff_in   varchar(255),
do_limit_amt                     varchar(255),
do_continuity_dt                 date,
do_continuity_override_dt        date,
public_profile_in                varchar(255),
level_of_attention              varchar(255),
-- Coverage Limitations
libel_slander_exclusion_in      varchar(255),
political_exclusion_in          varchar(255),
animal_related_liability_exclusion_in   varchar(255),
higher_underlying_limits_endorsement_in varchar(255),
addl_insured_limited_liability_in       varchar(255),
minimum_earned_premium_endorsement_in   varchar(255),
minimum_earned_premium_endorsement_limit_pc float,
premises_liability_limitation_in        varchar(255),
deletion_of_cosmetic_marring_exclusion_in   varchar(255),
manuscript_in               varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_coverage PRIMARY KEY (pel_coverage_sk),
CONSTRAINT uidx_tpel_coverage_polno_effdt_transeq UNIQUE (policy_no,effective_dt,transaction_seq_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_coverage','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

/*
CREATE TABLE tpel_additional_coverage
(
pel_additional_coverage_sk           int NOT NULL AUTO_INCREMENT,
policy_no                 			 varchar(255),
effective_dt               			 date,
source_system_sk           			 int,
create_ts                  			 datetime,
update_ts                  			 datetime,
PRIMARY KEY (pel_coverage_sk)
);
*/


CREATE TABLE edw_core.tpel_location
(
pel_location_sk           int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
location_no                int,
address_line_1             varchar(255),
address_line_2             varchar(255),
unit_no				       varchar(255),
city_nm                    varchar(255),
state_cd                   varchar(255),
zip_cd                     varchar(255),
county_nm                  varchar(255), 
country_nm                  varchar(255), 
longitude                  varchar(255), 
latitude                   varchar(255), 
swimming_pool_ct           int,
multi_family_dwelling_in   varchar(255),
vacant_unoccupied_in       varchar(255),
for_sale_in                varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_location PRIMARY KEY (pel_location_sk),
CONSTRAINT uidx_tpel_location_polno_effdt_transeq_locno UNIQUE (policy_no,effective_dt,transaction_seq_no,location_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_location','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tpel_vehicle
(
pel_vehicle_sk             int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
vehicle_no                 int,
vehicle_type               varchar(255),
vehicle_year               int,
vehicle_make               varchar(255),
vehicle_model              varchar(255),
vehicle_vin                varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_vehicle PRIMARY KEY (pel_vehicle_sk),
CONSTRAINT uidx_tpel_vehicle_polno_effdt_transeq_vehno UNIQUE (policy_no,effective_dt,transaction_seq_no,vehicle_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_vehicle','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE edw_core.tpel_driver
(
pel_driver_sk              int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
driver_no                  int,
prefix                     varchar(255),
first_nm                   varchar(255),
middle_nm                  varchar(255),
last_nm                    varchar(255),
suffix                     varchar(255),
birth_dt                   varchar(255),
license_status             varchar(255),
license_country_nm         varchar(255),
license_state_cd           varchar(255),
license_year               int,
license_no                 varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_driver PRIMARY KEY (pel_driver_sk),
CONSTRAINT uidx_tpel_driver_polno_effdt_transeq_drvno UNIQUE (policy_no,effective_dt,transaction_seq_no,driver_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_driver','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tpel_driver_incident
(
pel_driver_incident_sk              int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
pel_driver_sk              int,
incident_no                int,
incident_dt                date,
incident_type              varchar(255),
incident_desc              varchar(255),
include_in_rate_in         varchar(255), 
incident_disputed_in       varchar(255), 
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_driver_incident PRIMARY KEY (pel_driver_incident_sk),
CONSTRAINT uidx_tpel_driver_incident_polno_effdt_transeq_drvsk_incno UNIQUE (policy_no,effective_dt,transaction_seq_no,pel_driver_sk,incident_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_driver_incident','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tpel_watercraft
(
pel_watercraft_sk              int NOT NULL IDENTITY(1,1),
policy_no                  varchar(255),
effective_dt               date,
transaction_effective_dt   date,
expiration_dt              date,
transaction_dt             date,
transaction_seq_no         int,
policy_history_sk          int,
watercraft_no                  int,
watercraft_year                int,
watercraft_make                varchar(255),
watercraft_model               varchar(255),
watercraft_length              varchar(255),
watercraft_hull_value          varchar(255),
watercraft_horsepower          varchar(255),
vessels_owned_trust_llc_in     varchar(255),
vessels_with_captain_crew_in   varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tpel_watercraft PRIMARY KEY (pel_watercraft_sk),
CONSTRAINT uidx_tpel_watercraft_polno_effdt_transeq_wcftno UNIQUE (policy_no,effective_dt,transaction_seq_no,watercraft_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpel_watercraft','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

   

