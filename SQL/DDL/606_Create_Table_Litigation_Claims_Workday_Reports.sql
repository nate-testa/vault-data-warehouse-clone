CREATE TABLE edw_integration.claim_litigation_workday_reserve_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  reserve_type varchar(255),
  reserve_amount decimal(15,2),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  insuredname varchar(255) , 
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_litigation_workday_reserve_feed','Feed','This table provides MTD litigation claims reserves file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());

   
   -- Workday PRISM Claims Reserves ITD

 CREATE TABLE edw_integration.claim_litigation_workday_itd_reserve_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  reserve_type varchar(255),
  reserve_amount decimal(15,2),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  insuredname varchar(255) , 
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_litigation_workday_itd_reserve_feed','Feed','This table provides ITD litigation claims reserves file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());
    

-- Workday PRISM Claims Payments

 CREATE TABLE edw_integration.claim_litigation_workday_payment_feed 
 (
  company varchar(255),
  claim_no varchar(255),
  policy_no varchar(255),
  transaction_date date,
  policyeffectivedate date,
  claimlossdate date,
  claimreporteddate date,
  address varchar(255),
  city varchar(255) ,
  state varchar(255) ,
  zip varchar(255) ,
  causeofloss varchar(255) ,
  catastrophecode varchar(255),
  catastrophename varchar(255),
  product varchar(255),
  policycoveragetype varchar(255),
  paymenttype varchar(255),
  payeename varchar(255),
  paymentamount  decimal(15,2),
  settlementtype varchar(255),
  accident_year int,
  risk_state  varchar(255) ,
  aslob varchar(255) ,
  transaction_id varchar(255) ,
  monthend date,
  sub_cause_of_loss_code varchar(255) ,
  sub_cause_of_loss_name varchar(255) ,
  claim_status varchar(255) , 
  loss_status varchar(255) , 
  create_ts datetime ,
  update_ts datetime ,
  etl_audit_sk int,
  party_subtype_role_nm varchar(255)
);

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('claim_litigation_workday_payment_feed','Feed','This table provides MTD litigation claims payments file to Workday','Stored Procedure','Insert','Monthly',getdate(),getdate());
