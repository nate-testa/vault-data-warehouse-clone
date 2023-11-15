CREATE TABLE edw_core.tbroker_summary(
	month_sk int NOT NULL,
	broker_sk int NOT NULL,
	customer_sk int NOT NULL,
	product_sk int not NULL,
	risk_state_sk int not NULL, 
	quote_ct int NOT NULL,
	customer_ct int NOT NULL,
	last_quote_dt date NULL,
	last_bound_dt date NULL,
	new_business_ct int NOT NULL,
	new_business_premium_amt decimal(15, 2) NULL,
	new_business_net_premium_amt decimal(15, 2) NULL,
	inforce_ct int NOT NULL,
	inforce_premium_amt decimal(15, 2) NULL,
	inforce_net_premium_amt decimal(15, 2) NULL, 
	mtd_premium_amt decimal(15, 2) NULL,
	mtd_net_premium_amt decimal(15, 2) NOT NULL,
	mtd_commission_amt decimal(15, 2) NULL,
	mtd_tax_fee_surcharge_amt decimal(15, 2) NULL,
	earned_premium_amt decimal(15, 4) NULL,
	earned_net_premium_amt decimal(15, 4) NULL,
	written_exposure decimal(15, 4) NULL,
	earned_exposure decimal(15, 4) NULL,
	one_year_claim_ct int NOT NULL,
	one_year_loss_incurred_amt decimal(15, 2) NOT NULL,
	one_year_non_cat_claim_ct int NOT NULL,
	one_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
	three_year_claim_ct int NOT NULL,
	three_year_loss_incurred_amt decimal(15, 2) NOT NULL,
	three_year_non_cat_claim_ct int NOT NULL,
	three_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
	source_system_sk int NULL,
	update_ts datetime NULL,
	etl_audit_sk int NULL,
CONSTRAINT pk_tbroker_summary PRIMARY KEY CLUSTERED 
(
	month_sk ASC,
	broker_sk ASC,
	customer_sk ASC,
	product_sk asc,
	risk_state_sk
) 
)
 
ALTER TABLE edw_core.tbroker_summary 
ADD  CONSTRAINT fk_tbs_tbroker_broker_sk FOREIGN KEY(broker_sk)
REFERENCES edw_core.tbroker (broker_sk);
 
ALTER TABLE edw_core.tbroker_summary  
ADD  CONSTRAINT fk_tbs_tcustomer_customer_sk FOREIGN KEY(customer_sk)
REFERENCES edw_core.tcustomer (customer_sk);
 
ALTER TABLE edw_core.tbroker_summary   
ADD  CONSTRAINT fk_tbs_tproduct_product_sk FOREIGN KEY(product_sk)
REFERENCES edw_core.tproduct (product_sk);
 
ALTER TABLE edw_core.tbroker_summary   
ADD  CONSTRAINT fk_tbs_tsource_system_source_system_sk FOREIGN KEY(source_system_sk)
REFERENCES edw_core.tsource_system (source_system_sk);
 
ALTER TABLE edw_core.tbroker_summary   
ADD  CONSTRAINT fk_tbs_tstate_state_sk FOREIGN KEY(risk_state_sk)
REFERENCES edw_core.tstate (state_sk);