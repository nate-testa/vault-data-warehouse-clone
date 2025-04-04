
CREATE TABLE edw_commercial.tcommercial_quote_subjectivity
(
commercial_quote_subjectivity_sk       int IDENTITY(1,1) NOT NULL,
quote_no                     varchar(255) NOT NULL,
effective_dt                  date         NOT NULL ,
expiration_dt   			  date         NOT NULL,
transaction_seq_no                  int NOT NULL,
commercial_quote_history_sk 	int NOT NULL,
required_for					  varchar(255),
description						varchar(2000),
completed_in					varchar(255),
create_ts                     datetime NOT NULL,
update_ts                     datetime NOT NULL,
etl_audit_sk              		int NOT NULL,
source_system_sk                int NOT NULL,
CONSTRAINT pk_tcommercial_quote_subjectivity PRIMARY KEY (commercial_quote_subjectivity_sk),
CONSTRAINT fk_tcommercial_quote_subjectivity_commercial_quote_history_sk FOREIGN KEY (commercial_quote_history_sk) REFERENCES  edw_commercial.tcommercial_quote_history(commercial_quote_history_sk)
);