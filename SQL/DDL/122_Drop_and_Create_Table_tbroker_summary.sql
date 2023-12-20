IF OBJECT_ID('[edw_core].[tbroker_summary]', 'U') IS NOT NULL
DROP TABLE [edw_core].[tbroker_summary]
GO

CREATE TABLE edw_core.tbroker_summary
(
    month_sk int NOT NULL,
    broker_sk int NOT NULL,
	customer_sk int NOT NULL,
	product_sk int NOT NULL,
	state_sk int NOT NULL, 
	uw_company_cd varchar(255) not null,
    -- 
    prior_ytd_submission_ct int,
    ytd_submission_ct int NOT NULL, 
    prior_qtd_submission_ct int,
    qtd_submission_ct int NOT NULL, 
    prior_mtd_submission_ct int,
    mtd_submission_ct int NOT NULL, 
    --
    prior_ytd_quote_net_premium_amt decimal(15,2) NULL,
    ytd_quote_net_premium_amt decimal(15,2) NULL,
	prior_qtd_quote_net_premium_amt decimal(15,2) NULL,
    qtd_quote_net_premium_amt decimal(15,2) NULL,
	prior_mtd_quote_net_premium_amt decimal(15,2) NULL,
    mtd_quote_net_premium_amt decimal(15,2) NULL,
    --
	prior_ytd_quote_ct int NOT NULL,
    ytd_quote_ct int NOT NULL,
    prior_qtd_quote_ct int NOT NULL,
    qtd_quote_ct int NOT NULL,
    prior_mtd_quote_ct int NOT NULL,
    mtd_quote_ct int NOT NULL,
    --
    last_quote_dt date NULL,
    last_bound_dt date NULL,
    --
    prior_customer_ct int NOT NULL,
    customer_ct int NOT NULL,
	prior_total_line_ct int NOT NULL,
    total_line_ct int NOT NULL, 
    --
	prior_ytd_new_business_ct int NOT NULL,
    ytd_new_business_ct int NOT NULL,
    prior_qtd_new_business_ct int NOT NULL,
    qtd_new_business_ct int NOT NULL,
    prior_mtd_new_business_ct int NOT NULL,
    mtd_new_business_ct int NOT NULL,
    --
    prior_ytd_new_business_net_premium_amt decimal(15, 2) not NULL,
    ytd_new_business_net_premium_amt decimal(15, 2) not NULL,
    prior_qtd_new_business_net_premium_amt decimal(15, 2) not NULL,
    qtd_new_business_net_premium_amt decimal(15, 2) not NULL,
    prior_mtd_new_business_net_premium_amt decimal(15, 2) not NULL,
    mtd_new_business_net_premium_amt decimal(15, 2) not NULL,
    --
    prior_mtd_gross_new_business_net_premium_amt decimal(15, 2) not NULL,
    mtd_gross_new_business_net_premium_amt decimal(15, 2) not NULL,
    --
    prior_mtd_written_premium_amt decimal(15, 2) not NULL,
    mtd_written_premium_amt decimal(15, 2) not NULL,
    --
    prior_inforce_ct int NOT NULL,
    prior_inforce_net_premium_amt decimal(15, 2) not NULL,
	inforce_ct int NOT NULL,
    inforce_net_premium_amt decimal(15, 2) NOT NULL,  
    --
    one_year_claim_ct int NOT NULL,
    one_year_loss_incurred_amt decimal(15, 2) NOT NULL,
    one_year_non_cat_claim_ct int NOT NULL,
    one_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
    one_year_earned_net_premium_amt decimal(15, 4) NOT NULL,
    one_year_earned_exposure decimal(15, 4) NOT NULL,
    one_year_loss_incurred_capped_amt decimal(15, 2) NOT NULL,
    one_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NOT NULL, 
    --
    three_year_claim_ct int NOT NULL,
    three_year_loss_incurred_amt decimal(15, 2) NOT NULL,
    three_year_non_cat_claim_ct int NOT NULL,
    three_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
    three_year_earned_net_premium_amt decimal(15, 4) NOT NULL,
    three_year_earned_exposure decimal(15, 4) NOT NULL,
    three_year_loss_incurred_capped_amt decimal(15, 2) NOT NULL,
    three_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NOT NULL, 
    --
	policy_expiring_ct int NOT NULL,
	policy_renewal_ct int NOT NULL,
	policy_expiring_premium_amt decimal(15, 2) NOT NULL,
	policy_renewal_premium_amt decimal(15, 2) NOT NULL, 
    --
    update_ts datetime NULL,
    etl_audit_sk int NULL
);
 
ALTER TABLE edw_core.tbroker_summary ADD CONSTRAINT pk_tbroker_summary PRIMARY KEY CLUSTERED
(
    month_sk,
    broker_sk,
	customer_sk,
	product_sk,
	state_sk,
	uw_company_cd
);

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
ADD  CONSTRAINT fk_tbs_tstate_state_sk FOREIGN KEY(state_sk)
REFERENCES edw_core.tstate (state_sk);

CREATE NONCLUSTERED INDEX [IX_tbroker_summary_month_sk] ON [edw_core].tbroker_summary
(
	month_sk ASC
) ;
