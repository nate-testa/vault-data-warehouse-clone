CREATE TABLE edw_core.tquote_marine_boat_yacht_location 
(
quote_marine_boat_yacht_location_sk           int NOT NULL IDENTITY(1,1),
quote_no                  varchar(255) NOT NULL ,
effective_dt              date NOT NULL ,
expiration_dt			  date NOT NULL ,
transaction_seq_no		  int NOT NULL ,
quote_history_sk		  int NOT NULL ,
address_line_1             varchar(255),
address_line_2             varchar(255),
unit_no				       varchar(255),
city_nm                    varchar(255),
state_cd                   varchar(255),
zip_cd                     varchar(255),
county_nm                  varchar(255), 
country_nm                 varchar(255), 
longitude                  varchar(255), 
latitude                   varchar(255), 
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
CONSTRAINT pk_tquote_marine_boat_yacht_location PRIMARY KEY (quote_marine_boat_yacht_location_sk),
CONSTRAINT uidx_tquote_marine_boat_yacht_location_quote_no_effective_dt_transseqno UNIQUE (quote_no,effective_dt,transaction_seq_no)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_marine_boat_yacht_location','Type-2 Dimension','Base','Marine','Stored Procedure','Insert','Daily',getdate(),getdate());