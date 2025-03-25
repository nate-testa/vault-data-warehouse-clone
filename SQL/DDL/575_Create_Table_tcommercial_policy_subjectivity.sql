CREATE TABLE edw_commercial.commercial_policy_subjectivity
(
commercial_policy_subjectivity_sk       int IDENTITY(1,1) NOT NULL,
policy_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
transaction_effective_dt            date NOT NULL,
transaction_seq_no                  int NOT NULL,
commercial_policy_history_sk 	int NOT NULL,
required_for					  varchar(255),
description						nvarchar(2000),
completed_in					varchar(255),
create_ts                     datetime NOT NULL,
update_ts                     datetime NOT NULL,
etl_audit_sk              		int NOT NULL,
source_system_sk                int NOT NULL
CONSTRAINT pk_tcommercial_policy_subjectivity PRIMARY KEY (commercial_policy_subjectivity_sk),
CONSTRAINT fk_tcommercial_policy_subjectivity_commercial_policy_history_sk FOREIGN KEY (commercial_policy_history_sk) REFERENCES  edw_commercial.tcommercial_policy_history(commercial_policy_history_sk)
);