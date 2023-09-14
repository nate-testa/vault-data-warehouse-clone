CREATE TABLE edw_core.taslob 
(
  aslob_sk   int NOT NULL IDENTITY(1,1),
  aslob_cd   varchar(255),
  aslob_desc varchar(255),
  product_cd varchar(255),
  coverage_cd varchar(255),
  update_ts  datetime,
 CONSTRAINT pk_taslob PRIMARY KEY (aslob_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('taslob','Type-1 Dimension','Base','Claim','Manual','Insert/Update','Static',getdate(),getdate());

-- dwh_core.tcatastrophe definition

CREATE TABLE edw_core.tcatastrophe 
(
  catastrophe_sk int NOT NULL IDENTITY(1,1),
  catastrophe_cd  	varchar(255),
  catastrophe_nm 	varchar(255),
  catastrophe_desc 	nvarchar(max),
  source_system_sk           int,
  create_ts                  datetime,
  update_ts                  datetime,
  etl_audit_sk               int,
 CONSTRAINT pk_tcatastrophe PRIMARY KEY (catastrophe_sk),
 CONSTRAINT uidx_tcatastrophe_catastrophe_cd UNIQUE (catastrophe_cd)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcatastrophe','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());


-- dwh_core.tcause_of_loss definition

CREATE TABLE edw_core.tcause_of_loss 
(
  cause_of_loss_sk int NOT NULL IDENTITY(1,1),
  cause_of_loss_cd varchar(255),
  cause_of_loss_desc varchar(255),
  source_system_sk           int,
  create_ts                  datetime,
  update_ts                  datetime,
  etl_audit_sk               int,
 CONSTRAINT pk_tcause_of_loss PRIMARY KEY (cause_of_loss_sk),
 CONSTRAINT uidx_tcause_of_loss_cause_of_loss_cd UNIQUE (cause_of_loss_cd)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcause_of_loss','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   
   
CREATE TABLE edw_core.tsub_cause_of_loss (
  sub_cause_of_loss_sk int NOT NULL IDENTITY(1,1),
  cause_of_loss_cd varchar(255)  ,
  cause_of_loss_desc varchar(255)  ,
  sub_cause_of_loss_cd varchar(255) ,
  sub_cause_of_loss_desc varchar(255),
  source_system_sk int  ,
  create_ts datetime  ,
  update_ts datetime  ,
  etl_audit_sk               int,
CONSTRAINT pk_tsub_cause_of_loss PRIMARY KEY (sub_cause_of_loss_sk),
CONSTRAINT uidx_tsub_cause_of_loss_sub_cause_of_loss_cd UNIQUE (sub_cause_of_loss_cd)
);  

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tsub_cause_of_loss','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

-- dwh_core.tclaim definition

  
CREATE TABLE edw_core.tclaim (
  claim_sk int NOT NULL IDENTITY(1,1),
  claim_no varchar(255) ,
  loss_dt date ,
  report_dt date ,
  policy_no varchar(255) ,
  policy_effective_dt date ,
  policy_sk int,
  cause_of_loss_sk int ,
  sub_cause_of_loss_sk int,
  loss_desc nvarchar(max) ,
  claim_status varchar(255) ,
  source_claim_status varchar(255) ,
  catastrophe_sk int ,
  product_sk int ,
  underwriting_company_nm varchar(255) ,
  loss_address varchar(255) ,
  loss_city_nm varchar(255) ,
  loss_state_cd varchar(255) ,
  loss_zip_cd varchar(255) ,
  loss_country_nm varchar(255) ,
  broker_id varchar(255) ,
  customer_id varchar(255) ,
  contact_nm varchar(255),
  contact_type varchar(255),
  contact_phone varchar(255),
  contact_person_email varchar(255),
  loss_reserve_amt decimal(15,2) ,
  expense_reserve_amt decimal(15,2) ,
  adjusting_other_reserve_amt decimal(15,2) ,
  subro_reserve_amt decimal(15,2) ,
  salvage_reserve_amt decimal(15,2) ,
  salvage_expense_reserve_amt decimal(15,2) ,
  subro_expense_reserve_amt decimal(15,2) ,
  loss_paid_amt decimal(15,2) ,
  expense_paid_amt decimal(15,2) ,
  adjusting_other_paid_amt decimal(15,2) ,
  subro_recovery_amt decimal(15,2) ,
  salvage_recovery_amt decimal(15,2) ,
  salvage_expense_paid_amt decimal(15,2) ,
  subro_expense_paid_amt decimal(15,2) ,
  refund_indemnity_paid_amt decimal(15,2) ,
  refund_expense_paid_amt decimal(15,2) ,
  source_system_sk int,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk  int,
 CONSTRAINT pk_tclaim PRIMARY KEY (claim_sk),
 CONSTRAINT uidx_tclaim_claim_no UNIQUE (claim_no),
 CONSTRAINT fk_tclaim_cause_of_loss_sk FOREIGN KEY (cause_of_loss_sk) REFERENCES  edw_core.tcause_of_loss(cause_of_loss_sk),
 CONSTRAINT fk_tclaim_sub_cause_of_loss_sk FOREIGN KEY (sub_cause_of_loss_sk) REFERENCES  edw_core.tsub_cause_of_loss(sub_cause_of_loss_sk),
 CONSTRAINT fk_tclaim_catastrophe_sk FOREIGN KEY (catastrophe_sk) REFERENCES  edw_core.tcatastrophe(catastrophe_sk),
 CONSTRAINT fk_tclaim_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
 CONSTRAINT fk_tclaim_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk),
 CONSTRAINT fk_tclaim_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk)
 );

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

-- dwh_core.tclaim_feature definition

CREATE TABLE edw_core.tclaim_feature (
  claim_feature_sk int NOT NULL IDENTITY(1,1),
  claim_sk int ,
  claim_no varchar(255) ,
  subclaim_type_nm varchar(255) ,
  subclaim_seq_no varchar(255) ,
  claim_coverage_cd bigint ,
  claim_coverage_desc varchar(255) ,
  claimant_nm varchar(255) ,
  damage_severity varchar(255) ,
  damage_type varchar(255) ,
  possible_subrogation_in varchar(1) ,
  possible_salvage_in varchar(1) ,
  total_loss_in varchar(1) ,
  litigation_in varchar(1) ,
  product_sk int ,
  claim_feature_status varchar(255) ,
  aslob_sk int ,
  claim_adjuster_nm varchar(255) ,
  risk_item varchar(255),
  item_sk int,
  coverage_sk int,
  loss_reserve_amt decimal(15,2) ,
  expense_reserve_amt decimal(15,2) ,
  adjusting_other_reserve_amt decimal(15,2) ,
  subro_reserve_amt decimal(15,2) ,
  salvage_reserve_amt decimal(15,2) ,
  salvage_expense_reserve_amt decimal(15,2) ,
  subro_expense_reserve_amt decimal(15,2) ,
  loss_paid_amt decimal(15,2) ,
  expense_paid_amt decimal(15,2) ,
  adjusting_other_paid_amt decimal(15,2) ,
  subro_recovery_amt decimal(15,2) ,
  salvage_recovery_amt decimal(15,2) ,
  salvage_expense_paid_amt decimal(15,2) ,
  subro_expense_paid_amt decimal(15,2) ,
  refund_indemnity_paid_amt decimal(15,2) ,
  refund_expense_paid_amt decimal(15,2) ,
  source_system_sk int ,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk  int,
 CONSTRAINT pk_tclaim_feature PRIMARY KEY (claim_feature_sk),
 CONSTRAINT uidx_tclaim_feature_claimno_subclaimseqno_claimcoveragecd UNIQUE (claim_no,subclaim_seq_no,claim_coverage_cd),
 CONSTRAINT fk_tclaim_feature_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
 CONSTRAINT fk_tclaim_feature_claim_sk FOREIGN KEY (claim_sk) REFERENCES  edw_core.tclaim(claim_sk),
 CONSTRAINT fk_tclaim_feature_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
)
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_feature','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

CREATE TABLE edw_core.tclaim_status 
(
  claim_status_sk int NOT NULL IDENTITY(1,1),
  claim_status varchar(255) ,
  claim_status_category_nm varchar(255) ,
  update_ts datetime ,
CONSTRAINT pk_tclaim_status PRIMARY KEY (claim_status_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_status','Type-1 Dimension','Base','Claim','Manual','Insert/Update','Static',getdate(),getdate());


CREATE TABLE edw_core.tclaim_transaction_type 
(
  claim_transaction_type_sk int NOT NULL IDENTITY(1,1),
  claim_transaction_type_cd varchar(255) ,
  claim_transaction_type_nm varchar(255) ,
  update_ts datetime ,
 CONSTRAINT pk_tclaim_transaction_type PRIMARY KEY (claim_transaction_type_sk)
);
   
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_transaction_type','Type-1 Dimension','Base','Claim','Manual','Insert/Update','Static',getdate(),getdate());
   
CREATE TABLE edw_core.tclaim_payment (
  claim_payment_sk int NOT NULL IDENTITY(1,1),
  claim_no varchar(255) ,
  claim_sk int ,
  claim_feature_sk int ,
  payment_sequence_no int ,
  payment_no varchar(255) ,
  payment_status varchar(255) ,
  claim_type_cd varchar(255) ,
  settle_payee_id int ,
  payee_id int ,
  payee_nm varchar(255) ,
  party_role_nm varchar(255) ,
  paid_amt decimal(15,2) ,
  payee_address varchar(2000) ,
  remark varchar(2000) ,
  payment_submitter_nm varchar(255) ,
  payment_approver_nm varchar(255) ,
  payment_submitted_dt date ,
  payment_approver_dt date ,
  payment_category_nm varchar(255) ,
  partial_final_payment_desc varchar(255) ,
  source_system_sk int ,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_payment PRIMARY KEY (claim_payment_sk),
  CONSTRAINT uidx_tclaim_payment_claimfeaturesk_paymentno_paymentsequenceno UNIQUE (payment_sequence_no),
  CONSTRAINT fk_tclaim_payment_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim(claim_sk),
  CONSTRAINT fk_tclaim_payment_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
);

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_payment','Type-1 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   
   
CREATE TABLE edw_core.tclaim_transaction (
  claim_transaction_sk int NOT NULL IDENTITY(1,1),
  claim_sk int ,
  claim_feature_sk int ,
  product_sk int ,
  policy_sk int,
  broker_sk int,
  customer_sk int,
  defense_cost_in varchar(1) ,
  transaction_dt_sk int ,
  transaction_ts datetime ,
  claim_payment_sk int ,
  claim_transaction_type_sk int ,
  feature_status_sk int ,
  loss_reserve_amt decimal(15,2) ,
  expense_reserve_amt decimal(15,2) ,
  adjusting_other_reserve_amt decimal(15,2) ,
  subro_reserve_amt decimal(15,2) ,
  salvage_reserve_amt decimal(15,2) ,
  salvage_expense_reserve_amt decimal(15,2) ,
  subro_expense_reserve_amt decimal(15,2) ,
  loss_paid_amt decimal(15,2) ,
  expense_paid_amt decimal(15,2) ,
  adjusting_other_paid_amt decimal(15,2) ,
  subro_recovery_amt decimal(15,2) ,
  salvage_recovery_amt decimal(15,2) ,
  salvage_expense_paid_amt decimal(15,2) ,
  subro_expense_paid_amt decimal(15,2) ,
  refund_indemnity_paid_amt decimal(15,2) ,
  refund_expense_paid_amt decimal(15,2) ,
  source_system_sk int ,
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_transaction PRIMARY KEY (claim_transaction_sk),
  CONSTRAINT fk_tclaim_transaction_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim(claim_sk),
  CONSTRAINT fk_tclaim_transaction_claim_feature_sk FOREIGN KEY (claim_feature_sk) REFERENCES  edw_core.tclaim_feature(claim_feature_sk),
  CONSTRAINT fk_tclaim_transaction_product_sk FOREIGN KEY (product_sk) REFERENCES  edw_core.tproduct(product_sk),
  CONSTRAINT fk_tclaim_transaction_transaction_dt_sk FOREIGN KEY (transaction_dt_sk) REFERENCES  edw_core.tdate(date_sk),
  CONSTRAINT fk_tclaim_transaction_claim_payment_sk FOREIGN KEY (claim_payment_sk) REFERENCES  edw_core.tclaim_payment(claim_payment_sk),
  CONSTRAINT fk_tclaim_transaction_claim_transaction_type_sk FOREIGN KEY (claim_transaction_type_sk) REFERENCES  edw_core.tclaim_transaction_type(claim_transaction_type_sk),
  CONSTRAINT fk_tclaim_transaction_claim_feature_status_sk FOREIGN KEY (feature_status_sk) REFERENCES  edw_core.tclaim_status(claim_status_sk), 
  CONSTRAINT fk_tclaim_transaction_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk),
  CONSTRAINT fk_tclaim_transaction_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
  CONSTRAINT fk_tclaim_transaction_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
  CONSTRAINT fk_tclaim_transaction_customer_sk FOREIGN KEY (customer_sk) REFERENCES  edw_core.tcustomer(customer_sk)
  )
 ;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_transaction','Fact','Base','Claim','Stored Procedure','Insert','Daily',getdate(),getdate());
   
   
CREATE TABLE edw_core.tclaim_diary 
(
  claim_diary_sk int NOT NULL IDENTITY(1,1),
  claim_no varchar(255) ,
  claim_sk int  ,
  subclaim_seq_no varchar(255),
  diary_type varchar(255),
  diary_title varchar(255),
  diary_content nvarchar(max),
  status_desc varchar(255),
  diary_priority varchar(255),
  diary_created_by_nm varchar(255),
  diary_created_ts datetime,
  assign_to varchar(255),
  due_dt date,
  source_system_sk int,
  create_ts datetime,
  update_ts datetime,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_diary PRIMARY KEY (claim_diary_sk),
  CONSTRAINT fK_tclaim_diary_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim (claim_sk)
)
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_diary','Type-2 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
   

CREATE TABLE edw_core.tclaim_note 
(
  claim_note_sk int NOT NULL IDENTITY(1,1),
  claim_no varchar(255)  ,
  claim_sk int  ,
  subclaim_seq_no varchar(255),
  content_desc nvarchar(max),
  category_nm varchar(255),
  send_message_to varchar(255),
  note_created_by_nm varchar(255),
  note_created_ts datetime ,
  user_type varchar(255),
  overview_desc varchar(500) ,
  source_system_sk int,
  create_ts datetime,
  update_ts datetime,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_note PRIMARY KEY (claim_note_sk),
  CONSTRAINT fK_tclaim_note_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim (claim_sk)
) 
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_note','Type-2 Dimension','Base','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());
  
CREATE TABLE edw_core.tclaim_feature_summary 
(
  month_sk int NOT NULL,
  claim_sk int ,
  claim_feature_sk int NOT NULL,
  product_sk int ,
  policy_sk int,
  broker_sk int,
  customer_sk int,
  loss_reserve_amt decimal(15,2) ,
  itd_loss_reserve_amt decimal(15,2) ,
  expense_reserve_amt decimal(15,2) ,
  itd_expense_reserve_amt decimal(15,2) ,
  adjusting_other_reserve_amt decimal(15,2) ,
  itd_adjusting_other_reserve_amt decimal(15,2) ,
  subro_reserve_amt decimal(15,2) ,
  itd_subro_reserve_amt decimal(15,2) ,
  salvage_reserve_amt decimal(15,2) ,
  itd_salvage_reserve_amt decimal(15,2) ,
  salvage_expense_reserve_amt decimal(15,2) ,
  itd_salvage_expense_reserve_amt decimal(15,2) ,
  subro_expense_reserve_amt decimal(15,2) ,
  itd_subro_expense_reserve_amt decimal(15,2) ,
  loss_paid_amt decimal(15,2) ,
  itd_loss_paid_amt decimal(15,2) ,
  expense_paid_amt decimal(15,2) ,
  itd_expense_paid_amt decimal(15,2) ,
  adjusting_other_paid_amt decimal(15,2) ,
  itd_adjusting_other_paid_amt decimal(15,2) ,
  subro_recovery_amt decimal(15,2) ,
  itd_subro_recovery_amt decimal(15,2) ,
  salvage_recovery_amt decimal(15,2) ,
  itd_salvage_recovery_amt decimal(15,2) ,
  salvage_expense_paid_amt decimal(15,2) ,
  itd_salvage_expense_paid_amt decimal(15,2) ,
  subro_expense_paid_amt decimal(15,2) ,
  itd_subro_expense_paid_amt decimal(15,2) ,
  refund_indemnity_paid_amt decimal(15,2) ,
  itd_refund_indemnity_paid_amt decimal(15,2) ,
  refund_expense_paid_amt decimal(15,2) ,
  dcc_expense_paid_amt decimal(15,2) ,
  itd_refund_expense_paid_amt decimal(15,2) ,
  feature_open_ct int ,
  feature_closed_ct int ,
  feature_closed_with_pay_ct int ,
  feature_closed_without_pay_ct int ,
  itd_total_incurred_amt decimal(15,2) ,
  itd_total_paid_amt decimal(15,2) ,
  itd_total_reserve_amt decimal(15,2) ,
  itd_dcc_expense_paid_amt decimal(15,2) ,
  itd_dcc_expense_paid_on_close_amt decimal(15,2) ,
  itd_loss_incurred_gt_250k_ct int ,
  itd_loss_incurred_gt_500k_ct int ,
  itd_refund_paid_amt decimal(15,2) ,
  aslob_sk int,
  source_system_sk int ,
  update_ts datetime ,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_feature_summary PRIMARY KEY (month_sk,claim_feature_sk),
  CONSTRAINT fk_tclaim_feature_summary_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk),
  CONSTRAINT fk_tclaim_feature_summary_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES edw_core.tsource_system(source_system_sk),
  CONSTRAINT fk_tclaim_feature_summary_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
  CONSTRAINT fk_tclaim_feature_summary_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
  CONSTRAINT fk_tclaim_feature_summary_customer_sk FOREIGN KEY (customer_sk) REFERENCES edw_core.tcustomer(customer_sk),
  CONSTRAINT fk_tclaim_feature_summary_claim_feature_sk FOREIGN KEY (claim_feature_sk) REFERENCES edw_core.tclaim_feature(claim_feature_sk),
  CONSTRAINT fk_tclaim_feature_summary_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim(claim_sk),
  CONSTRAINT fk_tclaim_feature_summary_month_sk FOREIGN KEY (month_sk) REFERENCES edw_core.tdate(date_sk)
) 
;


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_feature_summary','Fact','Datamart','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());


CREATE TABLE edw_core.tclaim_summary 
(
  month_sk int NOT NULL,
  claim_sk int NOT NULL,
  product_sk int ,
  policy_sk int,
  broker_sk int,
  customer_sk int,
  loss_reserve_amt decimal(15,2) ,
  itd_loss_reserve_amt decimal(15,2) ,
  expense_reserve_amt decimal(15,2) ,
  itd_expense_reserve_amt decimal(15,2) ,
  adjusting_other_reserve_amt decimal(15,2) ,
  itd_adjusting_other_reserve_amt decimal(15,2) ,
  subro_reserve_amt decimal(15,2) ,
  itd_subro_reserve_amt decimal(15,2) ,
  salvage_reserve_amt decimal(15,2) ,
  itd_salvage_reserve_amt decimal(15,2) ,
  salvage_expense_reserve_amt decimal(15,2) ,
  itd_salvage_expense_reserve_amt decimal(15,2) ,
  subro_expense_reserve_amt decimal(15,2) ,
  itd_subro_expense_reserve_amt decimal(15,2) ,
  loss_paid_amt decimal(15,2) ,
  itd_loss_paid_amt decimal(15,2) ,
  expense_paid_amt decimal(15,2) ,
  itd_expense_paid_amt decimal(15,2) ,
  adjusting_other_paid_amt decimal(15,2) ,
  itd_adjusting_other_paid_amt decimal(15,2) ,
  subro_recovery_amt decimal(15,2) ,
  itd_subro_recovery_amt decimal(15,2) ,
  salvage_recovery_amt decimal(15,2) ,
  itd_salvage_recovery_amt decimal(15,2) ,
  salvage_expense_paid_amt decimal(15,2) ,
  itd_salvage_expense_paid_amt decimal(15,2) ,
  subro_expense_paid_amt decimal(15,2) ,
  itd_subro_expense_paid_amt decimal(15,2) ,
  refund_indemnity_paid_amt decimal(15,2) ,
  itd_refund_indemnity_paid_amt decimal(15,2) ,
  refund_expense_paid_amt decimal(15,2) ,
  dcc_expense_paid_amt decimal(15,2) ,
  itd_refund_expense_paid_amt decimal(15,2) ,
  open_claim_ct int ,
  closed_claim_ct int ,
  claim_closed_with_pay_ct int ,
  claim_closed_without_pay_ct int ,
  itd_total_incurred_amt decimal(15,2) ,
  itd_total_paid_amt decimal(15,2) ,
  itd_total_reserve_amt decimal(15,2) ,
  itd_dcc_expense_paid_amt decimal(15,2) ,
  itd_dcc_expense_paid_on_close_amt decimal(15,2) ,
  itd_loss_incurred_gt_250k_ct int ,
  itd_loss_incurred_gt_500k_ct int ,
  itd_refund_paid_amt decimal(15,2) ,
  source_system_sk int ,
  update_ts datetime ,
  etl_audit_sk  int,
  CONSTRAINT pk_tclaim_summary PRIMARY KEY (month_sk,claim_sk),
  CONSTRAINT fk_tclaim_summary_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk),
  CONSTRAINT fk_tclaim_summary_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES edw_core.tsource_system(source_system_sk),
  CONSTRAINT fk_tclaim_summary_policy_sk FOREIGN KEY (policy_sk) REFERENCES  edw_core.tpolicy(policy_sk),
  CONSTRAINT fk_tclaim_summary_broker_sk FOREIGN KEY (broker_sk) REFERENCES  edw_core.tbroker(broker_sk),
  CONSTRAINT fk_tclaim_summary_customer_sk FOREIGN KEY (customer_sk) REFERENCES edw_core.tcustomer(customer_sk),
  CONSTRAINT fk_tclaim_summary_claim_sk FOREIGN KEY (claim_sk) REFERENCES edw_core.tclaim(claim_sk),
  CONSTRAINT fk_tclaim_summary_month_sk FOREIGN KEY (month_sk) REFERENCES edw_core.tdate(date_sk)
) 
;

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tclaim_summary','Fact','Datamart','Claim','Stored Procedure','Insert/Update','Daily',getdate(),getdate());