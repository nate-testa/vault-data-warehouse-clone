IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_create_financial_transaction_action_api_update_stage')
BEGIN
CREATE TABLE edw_stage.migration_create_financial_transaction_action_api_update_stage (
id int NOT NULL,
[data] nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
create_ts datetime NULL,
update_ts datetime NULL,
api_status varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
api_error_description varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
api_response nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
CONSTRAINT PK_migration_create_financial_transaction_action_update_stage_api PRIMARY KEY (id))
END;