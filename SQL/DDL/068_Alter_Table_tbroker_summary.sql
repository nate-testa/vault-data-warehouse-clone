ALTER TABLE edw_core.tbroker_summary
DROP CONSTRAINT pk_tbroker_summary;
 
ALTER TABLE edw_core.tbroker_summary
DROP CONSTRAINT fk_tbs_tstate_state_sk;
 
ALTER TABLE edw_core.tbroker_summary
ADD CONSTRAINT pk_tbroker_summary PRIMARY KEY (month_sk ASC,
	broker_sk ASC,
	customer_sk ASC,
	product_sk asc);
 
ALTER TABLE edw_core.tbroker_summary DROP COLUMN earned_premium_amt;
ALTER TABLE edw_core.tbroker_summary DROP COLUMN earned_net_premium_amt;
ALTER TABLE edw_core.tbroker_summary DROP COLUMN written_exposure;
ALTER TABLE edw_core.tbroker_summary DROP COLUMN earned_exposure; 
ALTER TABLE edw_core.tbroker_summary DROP COLUMN risk_state_sk;  
 
EXEC sp_rename 'edw_core.tbroker_summary.new_business_ct', 'ytd_new_business_ct', 'COLUMN'
EXEC sp_rename 'edw_core.tbroker_summary.new_business_premium_amt', 'ytd_new_business_premium_amt', 'COLUMN'
EXEC sp_rename 'edw_core.tbroker_summary.new_business_net_premium_amt', 'ytd_new_business_net_premium_amt', 'COLUMN'
 
ALTER TABLE edw_core.tbroker_summary add ytd_premium_amt decimal(15, 2) NULL;
ALTER TABLE edw_core.tbroker_summary add ytd_net_premium_amt decimal(15, 2) NOT NULL;
 
ALTER TABLE edw_core.tbroker_summary add one_year_earned_net_premium_amt decimal(15, 4) NULL;
ALTER TABLE edw_core.tbroker_summary add three_year_earned_net_premium_amt decimal(15, 4) NULL; 
ALTER TABLE edw_core.tbroker_summary add one_year_earned_exposure decimal(15, 4) NULL;
ALTER TABLE edw_core.tbroker_summary add three_year_earned_exposure decimal(15, 4) NULL; 
ALTER TABLE edw_core.tbroker_summary add one_year_loss_incurred_capped_amt decimal(15, 2) NULL; 
ALTER TABLE edw_core.tbroker_summary add one_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NULL; 
ALTER TABLE edw_core.tbroker_summary add three_year_loss_incurred_capped_amt decimal(15, 2) NULL; 
ALTER TABLE edw_core.tbroker_summary add three_year_non_cat_loss_incurred_capped_amt decimal(15, 2) NULL;  
 
ALTER TABLE edw_core.tbroker_summary add non_admitted_inforce_ct int NOT NULL;  
ALTER TABLE edw_core.tbroker_summary add admitted_inforce_ct int NOT NULL;  
ALTER TABLE edw_core.tbroker_summary add non_admitted_inforce_net_premium_amt decimal(15, 2) NULL;  
ALTER TABLE edw_core.tbroker_summary add admitted_inforce_net_premium_amt decimal(15, 2) NULL;