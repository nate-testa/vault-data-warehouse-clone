IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_core'
AND TABLE_name = 'tproduct_companion_credit')
BEGIN

	CREATE TABLE edw_core.tproduct_companion_credit
	(   
		product_companion_credit_sk int IDENTITY(1,1) NOT NULL,
		state_cd varchar(255) NOT NULL,
		product_cd varchar(255) NOT NULL,
		uw_company_cd varchar(255),
		primary_home_discount_pc varchar(255), --decimal(5,2),
		homeowners_discount_pc decimal(5,2),
		homeowners_discount_cap_amt decimal(15,2),
		auto_discount_pc decimal(5,2),
		auto_discount_cap_amt decimal(15,2),
		pel_discount_pc decimal(5,2),
		pel_discount_cap_amt decimal(15,2),
		collections_discount_pc decimal(5,2),
		collections_discount_cap_amt decimal(15,2),
		marine_discount_pc decimal(5,2),
		marine_discount_cap_amt decimal(15,2),
		update_ts datetime2(7),
		CONSTRAINT pk_product_companion_credit PRIMARY KEY (product_companion_credit_sk),
		CONSTRAINT uidx_product_companion_credit UNIQUE (state_cd, product_cd,uw_company_cd)
	);
END;

delete from edw_core.tedw_table_detail
where table_nm = 'tproduct_companion_credit' ; 
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts,schema_nm) 
	VALUES ('tproduct_companion_credit','Type-1 Dimension','Base','Common','Manual','Insert/Update','Static',getdate(),getdate(),'edw_core');

