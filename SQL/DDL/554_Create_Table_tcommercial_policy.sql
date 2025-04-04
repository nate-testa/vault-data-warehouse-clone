CREATE TABLE edw_commercial.tcommercial_policy
(
commercial_policy_sk 	      int IDENTITY(1,1) NOT NULL,
policy_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
broker_id                             varchar(255) NOT NULL,
customer_id                           varchar(255) NOT NULL,
product_cd                            varchar(255) NOT NULL,
risk_state_cd                         varchar(255) NOT NULL,
policy_term					          varchar(255) NOT NULL,
policy_status                         varchar(255) NOT NULL,
insured_nm                            varchar(255),
mailing_address_line1         varchar(255),  
mailing_address_line2         varchar(255),
mailing_address_unit_no       varchar(255),
mailing_address_city_nm       varchar(255),
mailing_address_state_cd      varchar(255),
mailing_address_zip_cd        varchar(255),
create_ts                       datetime,
update_ts                       datetime,
etl_audit_sk              		int,
source_system_sk                int
CONSTRAINT pk_tcommercial_policy PRIMARY KEY (commercial_policy_sk),
CONSTRAINT uidx_tcommercial_policy_policy_no_effective_dt UNIQUE (policy_no,effective_dt)
);

