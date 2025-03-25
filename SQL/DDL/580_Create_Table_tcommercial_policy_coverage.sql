CREATE TABLE edw_commercial.tcommercial_policy_coverage
(
commercial_policy_coverage_sk 				int IDENTITY(1,1) NOT NULL,
policy_no                     				varchar(255) NOT NULL,
effective_dt                  				date NOT NULL ,
expiration_dt   			  				date NOT NULL,
transaction_effective_dt            		date NOT NULL,
transaction_dt								date NOT NULL,
transaction_seq_no                  		int NOT NULL,
commercial_policy_history_sk 				int NOT NULL,
coverage_type								varchar(255),
coverage_type_b								varchar(255), 
revenue_amt									varchar(255),
memorandum_of_insurance_in					varchar(255),
employee_ct									varchar(255),
claim_history								varchar(255),
source_system_sk							int NOT NULL,
create_ts                     				datetime NOT NULL,
update_ts                     				datetime NOT NULL,
etl_audit_sk              					int NOT NULL,
CONSTRAINT pk_tcommercial_policy_coverage PRIMARY KEY (commercial_policy_coverage_sk),
CONSTRAINT uidx_tcommercial_policy_coverage_policy_no_effective_dt_transaction_seq_no UNIQUE (policy_no,effective_dt,transaction_seq_no),
CONSTRAINT fk_tcommercial_policy_coverage_commercial_policy_history_sk FOREIGN KEY (commercial_policy_history_sk) REFERENCES  edw_commercial.tcommercial_policy_history(commercial_policy_history_sk)
);