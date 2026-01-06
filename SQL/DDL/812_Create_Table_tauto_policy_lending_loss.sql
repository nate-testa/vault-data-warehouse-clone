CREATE TABLE edw_core.tauto_policy_lending_loss
(
auto_lending_loss_sk    int IDENTITY(1,1) NOT NULL,
    policy_no varchar(255) NOT NULL ,
	effective_dt date NOT NULL ,
    transaction_effective_dt date NOT NULL ,
    lending_loss_unique_id Varchar(255) NOT NULL,
    expiration_dt date NOT NULL ,
    transaction_dt date NOT NULL ,
    transaction_seq_no int NOT NULL ,
    policy_history_sk int NOT NULL ,
  incident_source Varchar(255),
incident_dt date,
incident_type Varchar(255),
incident_desc Varchar(255),
total_payout_amt  Decimal(15,2),
disputed_in  Varchar(255),
include_in_rate_in Varchar(255),
vehicle_operator_nm Varchar(255),
source_system_sk           int,
create_ts                  datetime,
update_ts                  datetime,
etl_audit_sk               int,
PRIMARY KEY (auto_lending_loss_sk),
CONSTRAINT fk_tauto_policy_lending_loss_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tauto_policy_lending_loss','Type-2 Dimension','Base','Auto','Stored Procedure','Insert','Daily',getdate(),getdate());


