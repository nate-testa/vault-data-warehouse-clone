IF OBJECT_ID('[edw_core].[tbroker_summary]', 'U') IS NOT NULL
DROP TABLE [edw_core].[tbroker_summary]
GO

CREATE TABLE edw_core.tbroker_summary
(
    month_sk int NOT NULL,
    broker_sk int NOT NULL,
    prior_ytd_quote_ct int NOT NULL,
    ytd_quote_ct int NOT NULL,
    last_quote_dt date NULL,
    last_bound_dt date NULL,
    prior_customer_ct int,
    customer_ct int,
	prior_total_line_ct int,
    total_line_ct int,
    prior_ytd_new_business_ct int NOT NULL,
    prior_ytd_new_business_net_premium_amt decimal(15, 2) NULL,
    ytd_new_business_ct int NOT NULL,
    ytd_new_business_net_premium_amt decimal(15, 2) NULL,
    prior_inforce_ct int NOT NULL,
    prior_inforce_net_premium_amt decimal(15, 2) NULL,
	inforce_ct int NOT NULL,
    inforce_net_premium_amt decimal(15, 2) NULL,
	au_inforce_ct int NOT NULL,
	au_inforce_net_premium_amt decimal(15, 2) NULL, 
	co_inforce_ct int NOT NULL,
	co_inforce_net_premium_amt decimal(15, 2) NULL, 
	ho_inforce_ct int NOT NULL,
	ho_inforce_net_premium_amt decimal(15, 2) NULL, 
	lux_inforce_ct int NOT NULL,
	lux_inforce_net_premium_amt decimal(15, 2) NULL, 
	pel_inforce_ct int NOT NULL,
	pel_inforce_net_premium_amt decimal(15, 2) NULL,
    non_admitted_inforce_ct int NOT NULL,
    admitted_inforce_ct int NOT NULL,
    non_admitted_inforce_net_premium_amt decimal(15, 2) NULL,
    admitted_inforce_net_premium_amt decimal(15, 2) NULL, 
    one_year_claim_ct int NOT NULL,
    one_year_loss_incurred_amt decimal(15, 2) NOT NULL,
    one_year_non_cat_claim_ct int NOT NULL,
    one_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
    one_year_earned_net_premium_amt decimal(15, 4) NULL,
    one_year_earned_exposure decimal(15, 4) NULL,
    one_year_loss_incurred_capped_amt decimal(15, 2) NULL,
    one_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NULL,
    ho_one_year_claim_ct int NOT NULL,
    ho_one_year_non_cat_claim_ct int NOT NULL,
    ho_one_year_earned_net_premium_amt decimal(15, 4) NULL,
    ho_one_year_earned_exposure decimal(15, 4) NULL,
    three_year_claim_ct int NOT NULL,
    three_year_loss_incurred_amt decimal(15, 2) NOT NULL,
    three_year_non_cat_claim_ct int NOT NULL,
    three_year_non_cat_loss_incurred_amt decimal(15, 2) NOT NULL,
    three_year_earned_net_premium_amt decimal(15, 4) NULL,
    three_year_earned_exposure decimal(15, 4) NULL,
    three_year_loss_incurred_capped_amt decimal(15, 2) NULL,
    three_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NULL,
    ho_three_year_claim_ct int NOT NULL,
    ho_three_year_non_cat_claim_ct int NOT NULL,
    ho_three_year_earned_net_premium_amt decimal(15, 4) NULL,
    ho_three_year_earned_exposure decimal(15, 4) NULL,
	policy_retention_rate decimal(15, 2) NULL,
	premium_retention_rate decimal(15, 2) NULL,
    update_ts datetime NULL,
    etl_audit_sk int NULL
);
 
ALTER TABLE edw_core.tbroker_summary ADD CONSTRAINT pk_tbroker_summary PRIMARY KEY CLUSTERED
(
    month_sk ASC,
    broker_sk ASC
);
ALTER TABLE edw_core.tbroker_summary
ADD  CONSTRAINT fk_tbs_tbroker_broker_sk FOREIGN KEY(broker_sk)
REFERENCES edw_core.tbroker (broker_sk); 