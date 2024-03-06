CREATE TABLE edw_integration.claim_product_search_api 
(
  product_cd varchar(255) NOT NULL,
  product_nm varchar(255) NOT NULL,
  ebao_product_cd varchar(255) NOT NULL,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_claim_product_search_api PRIMARY KEY (product_cd)
);

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('claim_product_search_api','API','This table provides product name and corresponding ebao product code for claim product search API','Stored Procedure','Insert','Daily',getdate(),getdate());

