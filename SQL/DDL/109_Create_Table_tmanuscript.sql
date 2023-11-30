CREATE TABLE edw_core.tmanuscript
(
manuscript_sk              int NOT NULL IDENTITY(1,1),  
policy_no                  varchar(255) NOT NULL,
effective_dt               date NOT NULL,
transaction_effective_dt   date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
policy_history_sk          int NOT NULL,
manuscript_no      	       varchar(255),
manuscript_title	       nvarchar(max),
manuscript_desc	           nvarchar(max),
source_system_sk                  int NOT NULL,
create_ts                           datetime,
update_ts                           datetime,
etl_audit_sk                        int,
CONSTRAINT pk_tmanuscript PRIMARY KEY (manuscript_sk),
CONSTRAINT uidx_tmanuscript_polno_effdt_transeq_manuscript_no UNIQUE (policy_no,effective_dt,transaction_seq_no,manuscript_no),
CONSTRAINT fk_tmanuscript_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tmanuscript','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

