
CREATE TABLE edw_core.tgrpel_location
(
grpel_location_sk           int NOT NULL IDENTITY(1,1),
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
city_nm                    varchar(255),
state_cd                   varchar(255),
zip_cd                     varchar(255),
county_nm                  varchar(255), 
country_nm                 varchar(255), 
swimming_pool_in           varchar(255),
rented_in                  varchar(255),
rental_term                varchar(255),
primary_location_in        varchar(255),
location_unique_id         varchar(255),
location_deleted_in        varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tgrpel_location PRIMARY KEY (grpel_location_sk),
CONSTRAINT uidx_tgrpel_location_polno_effdt_locno UNIQUE (policy_no,effective_dt,location_no)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tgrpel_location','Type-2 Dimension','Base','Group Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


