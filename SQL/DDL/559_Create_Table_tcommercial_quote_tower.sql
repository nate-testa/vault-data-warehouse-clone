CREATE TABLE edw_commercial.tcommercial_quote_tower
(
commercial_quote_tower_sk 	int IDENTITY(1,1) NOT NULL,
quote_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
transaction_seq_no                  int NOT NULL,
commercial_quote_sk 	    int NOT NULL,
tower_type						varchar(255),
tower_unique_id 				varchar(255),
company_nm				varchar(255),
company_policy_no 		varchar(255),
company_policy_effective_dt	date,
company_policy_expiration_dt	date,
per_claim_policy_limit_amt		int,
aggregate_policy_limit_amt		int,
per_claim_attachment_amt		int, 
aggregate_attachment_amt		int,
per_claim_retention_amt			int,
aggregate_retention_amt			int,
thereafter_retention_amt	int,
create_ts                     datetime,
update_ts                     datetime,
etl_audit_sk              		int
CONSTRAINT pk_tcommercial_quote_tower PRIMARY KEY (commercial_quote_tower_sk),
CONSTRAINT uidx_tcommercial_quote_tower_quote_no_effective_dt_transaction_seq_no_tower_no UNIQUE (quote_no,effective_dt,transaction_seq_no, tower_unique_id),
CONSTRAINT fk_tcommercial_quote_tower_commercial_quote_sk FOREIGN KEY (commercial_quote_sk) REFERENCES  edw_commercial.tcommercial_quote(commercial_quote_sk)
);