CREATE TABLE edw_commercial.tcommercial_quote_coverage
(
commercial_quote_coverage_sk 				int IDENTITY(1,1) NOT NULL,
quote_no                     				varchar(255) NOT NULL,
effective_dt                  				date NOT NULL ,
expiration_dt   			  				date NOT NULL,
transaction_seq_no                  		int NOT NULL,
commercial_quote_history_sk 				int NOT NULL,
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
CONSTRAINT pk_tcommercial_quote_coverage PRIMARY KEY (commercial_quote_coverage_sk),
CONSTRAINT uidx_tcommercial_quote_coverage_policy_no_effective_dt_transaction_seq_no UNIQUE (quote_no,effective_dt,transaction_seq_no),
CONSTRAINT fk_tcommercial_quote_coverage_commercial_quote_history_sk FOREIGN KEY (commercial_quote_history_sk) REFERENCES  edw_commercial.tcommercial_quote_history(commercial_quote_history_sk)
);