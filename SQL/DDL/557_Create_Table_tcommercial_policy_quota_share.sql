CREATE TABLE edw_commercial.tcommercial_policy_quota_share
(
commercial_policy_quota_share_sk  	int IDENTITY(1,1) NOT NULL,
policy_no                       varchar(255) NOT NULL,
effective_dt                    date NOT NULL ,
expiration_dt   			    date NOT NULL,
transaction_effective_dt        date NOT NULL,
transaction_seq_no              int NOT NULL,
commercial_policy_history_sk 	int NOT NULL,
commercial_policy_tower_sk 	    int NOT NULL,
quota_share_unique_id			varchar(255),
company_nm				        varchar(255),
company_policy_no               varchar(255),
quota_share_pc 		            varchar(255),
per_claim_policy_limit_amt		int,
aggregate_policy_limit_amt		int,
quota_share_deleted_in          varchar(255),
create_ts                       datetime NOT NULL,
update_ts                       datetime NOT NULL,
etl_audit_sk              		int NOT NULL,
source_system_sk                int NOT NULL
CONSTRAINT pk_tcommercial_policy_quota_share PRIMARY KEY (commercial_policy_quota_share_sk),
CONSTRAINT uidx_tcommercial_policy_quota_share_policy_no_effective_dt_transaction_seq_no_quota_share_unique_id UNIQUE (policy_no,effective_dt,transaction_seq_no, quota_share_unique_id),
CONSTRAINT fk_tcommercial_policy_quota_share_commercial_policy_history_sk FOREIGN KEY (commercial_policy_history_sk) REFERENCES  edw_commercial.tcommercial_policy_history(commercial_policy_history_sk)
);