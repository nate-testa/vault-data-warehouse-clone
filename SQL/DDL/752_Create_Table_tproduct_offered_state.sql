IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_core'
AND TABLE_name = 'tproduct_offered_state')
BEGIN

	CREATE TABLE edw_core.tproduct_offered_state
	(   
		product_offered_state_sk int IDENTITY(1,1) NOT NULL,
		state_cd varchar(255) NOT NULL,
		homeowners_in varchar(255),
		condo_in varchar(255),
		auto_in varchar(255),
		pel_in varchar(255),
		collections_in varchar(255),
		collections_on_endorsement_in varchar(255),
		marine_in varchar(255),
		update_ts datetime2(7),
		CONSTRAINT pk_product_offered_state PRIMARY KEY (product_offered_state_sk),
		CONSTRAINT uidx_product_offered_state UNIQUE (state_cd)
	);
END; 

IF EXISTS
(SELECT 1 FROM edw_integration.tintegration_table_detail
	where table_nm = 'tproduct_offered_state')
BEGIN
	delete edw_integration.tintegration_table_detail
	where table_nm = 'tproduct_offered_state' ; 
END ; 
 
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts,schema_nm) 
	VALUES ('tproduct_offered_state','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate(),'edw_core');
