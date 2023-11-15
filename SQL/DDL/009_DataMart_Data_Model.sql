CREATE TABLE edw_core.tdaily_inforce_policy
(
inforce_dt_sk   int NOT NULL,
policy_sk           int NOT NULL,
customer_sk         int NOT NULL,
broker_sk           int NOT NULL,
product_sk          int NOT NULL,
premium_amt 		decimal(15,2),
net_premium_amt     decimal(15,2),
annual_premium_amt	decimal(15,2),
source_system_sk    int NOT NULL,
update_ts           datetime,
etl_audit_sk        int,
CONSTRAINT pk_tdaily_inforce_policy PRIMARY KEY (inforce_dt_sk,policy_sk),
CONSTRAINT fk_tdip_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tdip_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tdip_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tdip_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
CONSTRAINT fk_tdip_tsource_system_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tdaily_inforce_policy','Fact','Datamart','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

  
CREATE TABLE edw_core.tpolicy_summary
(
month_sk                        int,
policy_sk                       int,
customer_sk                     int,
broker_sk                       int,
product_sk                      int,
mtd_premium_amt        			decimal(15,2), 
mtd_commission_amt				decimal(15,2),			
mtd_tax_fee_surcharge_amt		decimal(15,2),
mtd_net_premium_amt	            decimal(15,2),
ytd_premium_amt         		decimal(15,2), 
ytd_commission_amt				decimal(15,2),			
ytd_tax_fee_surcharge_amt		decimal(15,2),
ytd_net_premium_amt	    		decimal(15,2),
itd_premium_amt                 decimal(15,2), 
itd_commission_amt				decimal(15,2),			
itd_tax_fee_surcharge_amt		decimal(15,2),
itd_net_premium_amt	    		decimal(15,2),
annual_premium_amt              decimal(15,2),
inforce_premium_amt             decimal(15,2),
inforce_net_premium_amt         decimal(15,2),
earned_premium_amt              decimal(15,4),
earned_net_premium_amt          decimal(15,4),
unearned_premium_amt            decimal(15,4),
unearned_net_premium_amt        decimal(15,4),
written_exposure                decimal(15,4),
earned_exposure                 decimal(15,4),
inforce_ct                      int,
source_system_sk                int,
update_ts                       datetime,
etl_audit_sk                    int,
CONSTRAINT pk_tpolicy_summary PRIMARY KEY (month_sk,policy_sk),
CONSTRAINT fk_tps_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tps_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tps_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tps_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
CONSTRAINT fk_tps_tsource_system_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

   
  
CREATE TABLE edw_core.tcustomer_summary
(
    month_sk int NOT NULL, 
    customer_sk int NOT NULL,
    total_premium_amt decimal(15, 2), 
    total_annual_premium_amt decimal(15, 2) , 
    total_inforce_ct int , 
    total_line_ct int ,
    homeowners_premium_amt decimal(15, 2) , 
    collections_premium_amt decimal(15, 2), 
    auto_premium_amt decimal(15, 2) , 
    excess_liability_premium_amt decimal(15, 2) , 
    condo_premium_amt decimal(15, 2) , 
    update_ts datetime ,
    etl_audit_sk int ,
CONSTRAINT pk_tcustomer_summary PRIMARY KEY (month_sk,customer_sk),
CONSTRAINT fk_tcs_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcustomer_summary','Fact','Datamart','Common','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
    

  
CREATE TABLE edw_core.titem_inforce
(
    month_sk int NOT NULL,
    policy_sk int NOT NULL,
    item_sk int NOT NULL,
    coverage_sk int NOT NULL,
    customer_sk int NOT NULL,
    broker_sk int NOT NULL,
    product_sk int NOT NULL,
    premium_amt decimal(15, 2) NULL,
    net_premium_amt decimal(15, 2) NULL,
    annual_premium_amt decimal(15, 2) NULL,
    source_system_sk int NOT NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
CONSTRAINT pk_titem_inforce PRIMARY KEY (month_sk,policy_sk,item_sk),
CONSTRAINT fk_tii_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tii_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk),
CONSTRAINT fk_tii_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tii_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('titem_inforce','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

   
CREATE TABLE edw_core.titem_summary(
    month_sk int NOT NULL,
    policy_sk int NOT NULL,
    item_sk int NOT NULL,
    coverage_sk int NOT NULL,
    customer_sk int NOT NULL,
    broker_sk int NOT NULL,
    product_sk int NOT NULL,
    mtd_premium_amt decimal(15, 2) NULL,
    mtd_commission_amt decimal(15, 2) NULL,
    mtd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    mtd_net_premium_amt decimal(15, 2) NULL,
    ytd_premium_amt decimal(15, 2) NULL,
    ytd_commission_amt decimal(15, 2) NULL,
    ytd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    ytd_net_premium_amt decimal(15, 2) NULL,
    itd_premium_amt decimal(15, 2) NULL,
    itd_commission_amt decimal(15, 2) NULL,
    itd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    itd_net_premium_amt decimal(15, 2) NULL,
    annual_premium_amt decimal(15, 2) NULL,
    inforce_premium_amt decimal(15, 2) NULL,
    inforce_net_premium_amt decimal(15, 2) NULL,
    earned_premium_amt decimal(15, 4) NULL,
    earned_net_premium_amt decimal(15, 4) NULL,
    unearned_premium_amt decimal(15, 4) NULL,
    unearned_net_premium_amt decimal(15, 4) NULL,
    written_exposure decimal(15, 4) NULL,
    earned_exposure decimal(15, 4) NULL,
    inforce_ct int NULL,
    source_system_sk int NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,   
CONSTRAINT pk_titem_summary PRIMARY KEY (month_sk,policy_sk,item_sk),
CONSTRAINT fk_tis_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tis_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk),
CONSTRAINT fk_tis_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tis_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('titem_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   
   
CREATE TABLE edw_core.tinternal_coverage_inforce
(
    month_sk int NOT NULL,
    policy_sk int NOT NULL,
    item_sk int NOT NULL,
    coverage_sk int NOT NULL,
    internal_coverage_sk int NOT NULL,
    customer_sk int NOT NULL,
    broker_sk int NOT NULL,
    product_sk int NOT NULL,
    premium_amt decimal(15, 2) NULL,
    net_premium_amt decimal(15, 2) NULL,
    annual_premium_amt decimal(15, 2) NULL,
    source_system_sk int NOT NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
CONSTRAINT pk_tinternal_coverage_inforce PRIMARY KEY(month_sk ,policy_sk ,item_sk ,internal_coverage_sk ),
CONSTRAINT fk_tici_tbroker_broker_sk FOREIGN KEY(broker_sk) REFERENCES edw_core.tbroker (broker_sk),
CONSTRAINT fk_tici_tcustomer_customer_sk FOREIGN KEY(customer_sk) REFERENCES edw_core.tcustomer (customer_sk),
CONSTRAINT fk_tici_tpolicy_policy_sk FOREIGN KEY(policy_sk) REFERENCES edw_core.tpolicy (policy_sk),
CONSTRAINT fk_tici_tproduct_product_sk FOREIGN KEY(product_sk) REFERENCES edw_core.tproduct (product_sk),
CONSTRAINT fk_tici_tintcov_internal_coverage_sk FOREIGN KEY(internal_coverage_sk) REFERENCES edw_core.tinternal_coverage(internal_coverage_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tinternal_coverage_inforce','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate()); 

   
CREATE TABLE edw_core.tinternal_coverage_summary
(
    month_sk int NOT NULL,
    policy_sk int NOT NULL,
    item_sk int NOT NULL,
    internal_coverage_sk int NOT NULL,
    coverage_sk int NOT NULL,
    customer_sk int NOT NULL,
    broker_sk int NOT NULL,
    product_sk int NOT NULL,
    mtd_premium_amt decimal(15, 2) NULL,
    mtd_commission_amt decimal(15, 2) NULL,
    mtd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    mtd_net_premium_amt decimal(15, 2) NULL,
    ytd_premium_amt decimal(15, 2) NULL,
    ytd_commission_amt decimal(15, 2) NULL,
    ytd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    ytd_net_premium_amt decimal(15, 2) NULL,
    itd_premium_amt decimal(15, 2) NULL,
    itd_commission_amt decimal(15, 2) NULL,
    itd_tax_fee_surcharge_amt decimal(15, 2) NULL,
    itd_net_premium_amt decimal(15, 2) NULL,
    annual_premium_amt decimal(15, 2) NULL,
    inforce_premium_amt decimal(15, 2) NULL,
    inforce_net_premium_amt decimal(15, 2) NULL,
    earned_premium_amt decimal(15, 4) NULL,
    earned_net_premium_amt decimal(15, 4) NULL,
    unearned_premium_amt decimal(15, 4) NULL,
    unearned_net_premium_amt decimal(15, 4) NULL,
    written_exposure decimal(15, 4) NULL,
    earned_exposure decimal(15, 4) NULL,
    inforce_ct int NULL,
    source_system_sk int NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL,
CONSTRAINT pk_tinternal_coverage_summary PRIMARY KEY (month_sk ,policy_sk ,item_sk ,internal_coverage_sk ),
CONSTRAINT fk_tics_tbroker_broker_sk FOREIGN KEY(broker_sk) REFERENCES edw_core.tbroker (broker_sk),
CONSTRAINT fk_tics_tcustomer_customer_sk FOREIGN KEY(customer_sk) REFERENCES edw_core.tcustomer (customer_sk),
CONSTRAINT fk_tics_tpolicy_policy_sk FOREIGN KEY(policy_sk) REFERENCES edw_core.tpolicy (policy_sk),
CONSTRAINT fk_tics_tproduct_product_sk FOREIGN KEY(product_sk) REFERENCES edw_core.tproduct (product_sk),
CONSTRAINT fk_tics_tintcov_internal_coverage_sk FOREIGN KEY(internal_coverage_sk) REFERENCES edw_core.tinternal_coverage(internal_coverage_sk)
);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tinternal_coverage_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   
   
CREATE TABLE edw_core.tpolicy_transaction_summary (
	month_sk int NOT NULL,
	policy_sk int NOT NULL,
	transaction_seq_no int NOT NULL,
	item_sk int NOT NULL,
	internal_coverage_sk int NOT NULL,
	coverage_sk int NOT NULL,
	customer_sk int NOT NULL,
	broker_sk int NOT NULL,
	product_sk int NOT NULL,
	effective_dt_sk int NOT NULL,
	transaction_effective_dt_sk int NOT NULL,
	expiration_dt_sk int NOT NULL,
	transaction_dt_sk int NOT NULL,
	policy_transaction_type_sk int NOT NULL,
	premium_amt decimal(15,2) NULL,
	earned_premium_amt decimal(15,4) NULL,
	unearned_premium_amt decimal(15,4) NULL,
	source_system_sk int NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
CONSTRAINT pk_tpolicy_transaction_summary PRIMARY KEY (month_sk,policy_sk,transaction_seq_no,item_sk,internal_coverage_sk),
CONSTRAINT fk_tpts_policy_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
CONSTRAINT fk_tpts_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
CONSTRAINT fk_tpts_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk),
CONSTRAINT fk_tpts_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
CONSTRAINT fk_tpts_tsource_system_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
);



INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tpolicy_transaction_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.trenewal_summary (
	month_sk int NOT NULL,
	policy_sk int NOT NULL,
    customer_sk int NULL,
	broker_sk int NULL,
	product_sk int NULL, 
	expiring_initial_written_premium_amt decimal(15,2) NULL,
    expiring_sixty_day_written_premium_amt decimal(15,2) NULL,
    expiring_sixty_day_commission_amt decimal(15,2) NULL,
    expiring_mid_term_cancelled_premium_amt decimal(15,2) NULL,
    expiring_written_premium_amt decimal(15,2) NULL,
    expiring_premium_renewal_accepted_amt decimal(15,2) NULL,
    expiring_non_renewal_written_premium_amt decimal(15,2) NULL,
    expiring_total_finished_square_feet  decimal(15,2) NULL,
    expiring_residence_type  varchar(255) NULL,
	expiring_sixty_day_tiv_amt decimal(15,2) NULL,
    expiring_sixty_day_cova_amt decimal(15,2) NULL,
    expiring_tiv_amt decimal(15,2) NULL, 
    expiring_tiv_post_nr_amt decimal(15,2) NULL,
    expiring_cova_amt decimal(15,2) NULL,
	flat_cancelled_ct int NOT NULL,
    non_flat_cancelled_ct int NOT NULL,
    mid_term_cancelled_ct int NOT NULL,
	expiring_ct int NOT NULL,
    non_renewal_ct int NOT NULL,
    renewal_policy_sk int,
	renewal_ct int NOT NULL,
	renewal_non_flat_cancelled_ct int NOT NULL, 
    renewal_initial_written_premium_amt decimal(15,2) NULL,
    renewal_sixty_day_written_premium_amt decimal(15,2) NULL,
    renewal_sixty_day_commission_amt decimal(15,2) NULL,
    renewal_sixty_day_tiv_amt decimal(15,2) NULL,
    renewal_sixty_day_cova_amt decimal(15,2) NULL,
    renewal_accepted_price_sqft decimal(15,2) NULL, 
    source_system_sk int NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
	CONSTRAINT pk_trenewal_summary PRIMARY KEY (month_sk,policy_sk),
    CONSTRAINT fk_trs_tbroker_broker_sk FOREIGN KEY (broker_sk) REFERENCES edw_core.tbroker(broker_sk),
    CONSTRAINT fk_trs_tcustomer_customer_sk FOREIGN KEY (customer_sk) REFERENCES edw_core.tcustomer(customer_sk),
    CONSTRAINT fk_trs_tpolicy_policy_sk FOREIGN KEY (policy_sk) REFERENCES edw_core.tpolicy(policy_sk),
    CONSTRAINT fk_trs_tproduct_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk),
    CONSTRAINT fk_trs_tsource_system_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES edw_core.tsource_system(source_system_sk)
);

 
 
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('trenewal_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate()); 

