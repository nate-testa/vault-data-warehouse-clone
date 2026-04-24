IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_name = 'billing_grpel_cash_activity_feed')
BEGIN

CREATE TABLE edw_integration.billing_grpel_cash_activity_feed
( 
company varchar(255),
group_account varchar(255) NOT NULL,
group_name varchar(255),
effective_date date NOT NULL,
expiration_date date  NOT NULL,
payor_type varchar(255),
product varchar(255),
payment_from varchar(255),
category varchar(255),
paid_via varchar(255),
reference_code nvarchar(max),
payment_date date,
amount decimal(15,2),
month_end date,
create_ts datetime2(7) ,
update_ts datetime2(7) ,
etl_audit_sk int
);
END; 

IF EXISTS
(SELECT 1 FROM edw_integration.tintegration_table_detail
	where table_nm = 'billing_grpel_cash_activity_feed')
BEGIN
	delete edw_integration.tintegration_table_detail
	where table_nm = 'billing_grpel_cash_activity_feed' ; 
END ; 

INSERT INTO edw_integration.tintegration_table_detail (table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts)
VALUES ('billing_grpel_cash_activity_feed','Feed','This table provides monthly cash activity for group excess policies','Stored Procedure','Insert','Monthly',getdate(),getdate());