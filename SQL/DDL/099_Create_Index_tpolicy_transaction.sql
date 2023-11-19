IF NOT EXISTS 
(
    SELECT * 
FROM sys.indexes 
WHERE name='idx_tpolicy_transaction_policy_sk' AND object_id = OBJECT_ID('edw_core.tpolicy_transaction')
)
BEGIN
CREATE INDEX idx_tpolicy_transaction_policy_sk on edw_core.tpolicy_transaction(policy_sk)
END;

IF NOT EXISTS 
(
    SELECT * 
FROM sys.indexes 
WHERE name='idx_tpolicy_transaction_calendar_month_sk' AND object_id = OBJECT_ID('edw_core.tpolicy_transaction')
)
BEGIN
CREATE INDEX idx_tpolicy_transaction_calendar_month_sk on edw_core.tpolicy_transaction(calendar_month_sk)
END;

IF NOT EXISTS 
(
    SELECT * 
FROM sys.indexes 
WHERE name='IX_tpolicy_transaction_transaction_dt_sk' AND object_id = OBJECT_ID('edw_core.tpolicy_transaction')
)
BEGIN
CREATE INDEX [IX_tpolicy_transaction_transaction_dt_sk] ON edw_core.tpolicy_transaction (transaction_dt_sk)
END;

IF NOT EXISTS 
(
    SELECT * 
FROM sys.indexes 
WHERE name='IX_tpolicy_transaction_effective_dt_sk' AND object_id = OBJECT_ID('edw_core.tpolicy_transaction')
)
BEGIN
CREATE INDEX [IX_tpolicy_transaction_effective_dt_sk] ON edw_core.tpolicy_transaction (effective_dt_sk)
END;



 

 




