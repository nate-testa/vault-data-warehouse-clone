-- Workday Written Premium

 CREATE TABLE edw_integration.policy_yacht_commission_feed 
 (
  accounting_month varchar(255) ,
  insured_nm varchar(255) ,
  policy_number varchar(255),
  risk_state varchar(255),
  company varchar(255),
  policy_term  varchar(255),
  payment_collected decimal(15,2),
  commission_premium_collected decimal(15,2),
  commission_pct decimal(15,2),
  commission_paid_this_period decimal(15,2),
  commission_paid_to_date decimal(15,2),
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  CONSTRAINT pk_policy_yacht_commission_feed PRIMARY KEY (accounting_month,policy_number,policy_term)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('policy_yacht_commission_feed','Feed','This table provides monthly yacht commissions data','Stored Procedure','Insert','Monthly',getdate(),getdate());