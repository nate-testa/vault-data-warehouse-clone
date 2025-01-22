IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_integration'
and TABLE_name = 'claim_financial_transaction_action_snapsheet_api')
BEGIN
CREATE TABLE edw_integration.claim_financial_transaction_action_snapsheet_api (
settle_payee_id int not null,
[data] nvarchar(MAX) null,
create_ts datetime null,
update_ts datetime null,
etl_audit_sk  int null,
api_status varchar(255) NULL,
api_error_description varchar(2000) NULL,
api_response nvarchar(MAX) NULL,
CONSTRAINT PK_claim_financial_transaction_action_snapsheet_api PRIMARY KEY (settle_payee_id))
END;