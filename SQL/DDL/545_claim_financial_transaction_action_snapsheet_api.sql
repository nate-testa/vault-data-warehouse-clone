IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_NAME = 'claim_financial_transaction_action_snapsheet_api' AND COLUMN_NAME = 'id')
BEGIN
    EXEC sp_rename 'edw_integration.claim_financial_transaction_action_snapsheet_api.settle_payee_id','id'
END