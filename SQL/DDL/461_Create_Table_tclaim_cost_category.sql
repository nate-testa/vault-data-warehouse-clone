CREATE TABLE edw_core.tclaim_cost_category 
(
  claim_cost_category_sk int NOT NULL IDENTITY(1,1),
  claim_cost_category_nm varchar(255) ,
  create_ts datetime,
  update_ts datetime ,
 CONSTRAINT pk_tclaim_cost_category PRIMARY KEY (claim_cost_category_sk)
);
   
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_cost_category','Type-1 Dimension','Base','Claim','Manual','Insert/Update','Static',getdate(),getdate());
