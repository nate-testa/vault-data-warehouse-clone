CREATE TABLE edw_core.tmarine_boat_yacht
(
	marine_boat_yacht_sk int IDENTITY(1,1) NOT NULL,
	policy_no varchar(255) NOT NULL ,
	effective_dt date NOT NULL ,
	expiration_dt date NOT NULL ,
    boat_yatch_product_type varchar(255),
	boat_yatch_mep varchar(255),
	boat_yacht_make varchar(255),
	boat_yacht_model varchar(255),
	boat_yatch_type varchar(255),
	boat_yacht_year varchar(255),
	boat_yatch_hull_id varchar(255),
	boat_yatch_hull_length varchar(255),
	boat_yatch_engine_make varchar(255),
	boat_yatch_engine_model varchar(255),
	boat_yatch_no_of_engines varchar(255),
	boat_yatch_horse_power_per_engine varchar(255),
	boat_yatch_speed varchar(255),
	source_system_sk int ,
	create_ts datetime ,
	update_ts datetime ,
	etl_audit_sk int ,
	CONSTRAINT pk_tmarine_boat_yacht PRIMARY KEY (marine_boat_yacht_sk),
    CONSTRAINT uidx_tmarine_boat_yacht_policy_no_effective_dt UNIQUE (policy_no,effective_dt)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tmarine_boat_yacht','Type-1 Dimension','Base','Marine','Stored Procedure','Insert/Update','Daily',getdate(),getdate());