CREATE TABLE edw_commercial.tcommercial_policy_subjectivity
(
commercial_policy_subjectivity_sk       int IDENTITY(1,1) NOT NULL,
commercial_policy_sk 	int NOT NULL,
policy_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
transaction_effective_dt            date NOT NULL,
transaction_seq_no                  int NOT NULL,
required_for					  varchar(255),
description						nvarchar(2000),
completed_in					varchar(255),
create_ts                     datetime,
update_ts                     datetime,
etl_audit_sk              		int,
CONSTRAINT pk_tcommercial_policy_subjectivity PRIMARY KEY (commercial_policy_subjectivity_sk),
CONSTRAINT fk_tcommercial_policy_subjectivity_commercial_policy_sk FOREIGN KEY (commercial_policy_sk) REFERENCES  edw_commercial.tcommercial_policy(commercial_policy_sk)
);