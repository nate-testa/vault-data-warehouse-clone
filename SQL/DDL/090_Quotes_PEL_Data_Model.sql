CREATE TABLE edw_core.tquote_pel_coverage 
(
	quote_pel_coverage_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	pel_limit_amt int NULL,
	uninsured_underinsured_motorist_liability_amt varchar(255),
	uninsured_underinsured_liability_amt varchar(255),
	employment_practices_liability_amt varchar(255),
	private_staff_ct int NULL,
	allegation_by_private_staff_in varchar(255),
	do_limit_amt varchar(255),
	do_continuity_dt date NULL,
	do_continuity_override_dt date NULL,
	public_profile_in varchar(255) ,
	level_of_attention varchar(255) ,
	libel_slander_exclusion_in varchar(255) ,
	political_exclusion_in varchar(255) ,
	animal_related_liability_exclusion_in varchar(255) ,
	higher_underlying_limits_endorsement_in varchar(255) ,
	addl_insured_limited_liability_in varchar(255) ,
	minimum_earned_premium_endorsement_in varchar(255) ,
	minimum_earned_premium_endorsement_limit_pc float NULL,
	premises_liability_limitation_in varchar(255) ,
	deletion_of_cosmetic_marring_exclusion_in varchar(255) ,
	manuscript_in varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_coverage PRIMARY KEY (quote_pel_coverage_sk),
	CONSTRAINT uidx_tquote_pel_coverage_qtno_effdt_transeq UNIQUE (quote_no,effective_dt,transaction_seq_no),
    CONSTRAINT fk_tquote_pel_coverage_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_coverage','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());



CREATE TABLE edw_core.tquote_pel_driver 
(
	quote_pel_driver_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	driver_no int NOT NULL,
	prefix varchar(255) ,
	first_nm varchar(255) ,
	middle_nm varchar(255) ,
	last_nm varchar(255) ,
	suffix varchar(255) ,
	birth_dt varchar(255) ,
	license_status varchar(255) ,
	license_country_nm varchar(255) ,
	license_state_cd varchar(255) ,
	license_year int NULL,
	license_no varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_driver PRIMARY KEY (quote_pel_driver_sk),
	CONSTRAINT uidx_tquote_pel_driver_qtno_effdt_transeq_drvno UNIQUE (quote_no,effective_dt,transaction_seq_no,driver_no),
    CONSTRAINT fk_tquote_pel_driver_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_driver','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());


CREATE TABLE edw_core.tquote_pel_driver_incident (
	quote_pel_driver_incident_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	quote_pel_driver_sk int NOT NULL,
	incident_no int NOT NULL,
	incident_dt date NULL,
	incident_type varchar(255) ,
	incident_desc varchar(255) ,
	include_in_rate_in varchar(255) ,
	incident_disputed_in varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_driver_incident PRIMARY KEY (quote_pel_driver_incident_sk),
	CONSTRAINT uidx_tquote_pel_driver_incident_qtno_effdt_transeq_drvsk_incno UNIQUE (quote_no,effective_dt,transaction_seq_no,quote_pel_driver_sk,incident_no),
    CONSTRAINT fk_tquote_pel_driver_incident_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_driver_incident','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tquote_pel_location 
(
	quote_pel_location_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255)NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	location_no int NOT NULL,
	address_line_1 varchar(255) ,
	address_line_2 varchar(255) ,
	unit_no varchar(255) ,
	city_nm varchar(255) ,
	state_cd varchar(255) ,
	zip_cd varchar(255) ,
	county_nm varchar(255) ,
	country_nm varchar(255) ,
	longitude varchar(255) ,
	latitude varchar(255) ,
	swimming_pool_ct int NULL,
	multi_family_dwelling_in varchar(255) ,
	vacant_unoccupied_in varchar(255) ,
	for_sale_in varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_location PRIMARY KEY (quote_pel_location_sk),
	CONSTRAINT uidx_tquote_pel_location_qtno_effdt_transeq_locno UNIQUE (quote_no,effective_dt,transaction_seq_no,location_no),
    CONSTRAINT fk_tquote_pel_location_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_location','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tquote_pel_vehicle 
(
	quote_pel_vehicle_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	vehicle_no int NOT NULL,
	vehicle_type varchar(255) ,
	vehicle_year int NULL,
	vehicle_make varchar(255) ,
	vehicle_model varchar(255) ,
	vehicle_vin varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_vehicle PRIMARY KEY (quote_pel_vehicle_sk),
	CONSTRAINT uidx_tquote_pel_vehicle_qtno_effdt_transeq_vehno UNIQUE (quote_no,effective_dt,transaction_seq_no,vehicle_no),
    CONSTRAINT fk_tquote_pel_vehicle_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_vehicle','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());

CREATE TABLE edw_core.tquote_pel_watercraft 
(
	quote_pel_watercraft_sk int IDENTITY(1,1) NOT NULL,
	quote_no varchar(255) NOT NULL,
	effective_dt date NOT NULL,
	expiration_dt date NOT NULL,
	transaction_seq_no int NOT NULL,
	quote_history_sk int NOT NULL,
	watercraft_no int NOT NULL,
	watercraft_year int NULL,
	watercraft_make varchar(255) ,
	watercraft_model varchar(255) ,
	watercraft_length varchar(255) ,
	watercraft_hull_value varchar(255) ,
	watercraft_horsepower varchar(255) ,
	vessels_owned_trust_llc_in varchar(255) ,
	vessels_with_captain_crew_in varchar(255) ,
	source_system_sk int NULL,
	create_ts datetime NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_tquote_pel_watercraft PRIMARY KEY (quote_pel_watercraft_sk),
	CONSTRAINT uidx_tquote_pel_watercraft_qtno_effdt_transeq_wcftno UNIQUE (quote_no,effective_dt,transaction_seq_no,watercraft_no),
    CONSTRAINT fk_tquote_pel_watercraft_quote_history_sk FOREIGN KEY (quote_history_sk) REFERENCES edw_core.tquote_history(quote_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_pel_watercraft','Type-2 Dimension','Base','Personal Excess Liability','Stored Procedure','Insert','Daily',getdate(),getdate());