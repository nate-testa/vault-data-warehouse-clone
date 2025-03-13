CREATE TABLE edw_commercial.tcommercial_quote_quota_share
(
commercial_quote_quota_share_sk  	int IDENTITY(1,1) NOT NULL,
quote_no                       varchar(255) NOT NULL,
effective_dt                    date NOT NULL ,
expiration_dt   			    date NOT NULL,
transaction_seq_no              int NOT NULL,
commercial_quote_sk 	        int NOT NULL,
commercial_quote_tower_sk 	    int NOT NULL,
quota_share_unique_id			varchar(255),
company_nm				        varchar(255),
company_policy_no               varchar(255),
quota_share_pc 		            varchar(255),
per_claim_policy_limit_amt		int,
aggregate_policy_limit_amt		int,
create_ts                       datetime,
update_ts                       datetime,
etl_audit_sk              		int
CONSTRAINT pk_tcommercial_quote_quota_share PRIMARY KEY (commercial_quote_quota_share_sk),
CONSTRAINT uidx_tcommercial_quote_quota_share_quote_no_effective_dt_transaction_seq_no_quota_share_unique_id UNIQUE (quote_no,effective_dt,transaction_seq_no, quota_share_unique_id),
CONSTRAINT fk_tcommercial_quote_quota_share_commercial_quote_sk FOREIGN KEY (commercial_quote_sk) REFERENCES  edw_commercial.tcommercial_quote(commercial_quote_sk)
);