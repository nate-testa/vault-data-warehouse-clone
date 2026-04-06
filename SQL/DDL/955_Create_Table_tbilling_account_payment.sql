IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_core' 
               AND TABLE_NAME = 'tbilling_account_payment')
BEGIN
CREATE TABLE edw_core.tbilling_account_payment
(
             
billing_account_payment_sk        int IDENTITY(1,1) NOT NULL,
billingaccount_no          varchar(255) NOT NULL,
billingaccount_sk		   int NOT NULL,
grpel_master_policy_no 	   varchar(255) NOT NULL,
transaction_type           varchar(255) NULL, 
receivable_cd              varchar(255) NULL, 
payment_amt                decimal(15,2) NULL,
bill_type                  varchar(255) NULL,
payment_method             varchar(255) NULL,
payment_dt                 datetime2(7) NULL,    
payment_from_type      	   varchar(255) NULL,
system_remark              nvarchar(max),
user_remark                nvarchar(max),
source_system_sk           int NOT NULL,
create_ts                  datetime2(7) NOT NULL,
update_ts                  datetime2(7) NOT NULL,
etl_audit_sk               int NOT NULL,
CONSTRAINT pk_billing_account_payment PRIMARY KEY (billing_account_payment_sk)
);
END
IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tbilling_account_payment')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tbilling_account_payment' ; 
END ; 
INSERT INTO edw_core.tedw_table_detail (
    table_nm,
    table_type,
    table_category_nm,
    domain_nm,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'tbilling_account_payment',
    'Type-1 Dimension',
    'Base',
    'Policy',
    'Stored Procedure',
    'Insert/Update',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tbilling_account_payment'
);
