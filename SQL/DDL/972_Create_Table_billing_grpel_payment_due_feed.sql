IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_name = 'billing_grpel_payment_due_feed')
BEGIN

CREATE TABLE edw_integration.billing_grpel_payment_due_feed
( 
company varchar(255),
group_account varchar(255) NOT NULL,
group_name varchar(255),
effective_date date  NOT NULL,
expiration_date date  NOT NULL,
payor_type varchar(255),
product varchar(255),
total_premium decimal(15,2),
payments_made decimal(15,2),
balance_due_as_of_month_end decimal(15,2),
month_end date,
create_ts datetime2(7) ,
update_ts datetime2(7) ,
etl_audit_sk int,
CONSTRAINT pk_billing_grpel_payment_due_feed PRIMARY KEY(group_account,month_end)
);
END; 

IF EXISTS
(SELECT 1 FROM edw_integration.tintegration_table_detail
	where table_nm = 'billing_grpel_payment_due_feed')
BEGIN
	delete edw_integration.tintegration_table_detail
	where table_nm = 'billing_grpel_payment_due_feed' ; 
END ; 

INSERT INTO edw_integration.tintegration_table_detail (table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts)
VALUES ('billing_grpel_payment_due_feed','Feed','This table provides payment amount due for group excess policies at month end','Stored Procedure','Insert','Monthly',getdate(),getdate());