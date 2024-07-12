IF NOT EXISTS 
(
    SELECT * 
FROM sys.indexes 
WHERE name='idx_tpolicy_transaction_create_ts' AND object_id = OBJECT_ID('edw_core.tpolicy_transaction')
)
BEGIN
CREATE INDEX idx_tpolicy_transaction_create_ts ON edw_core.tpolicy_transaction(create_ts)
END;

---This is a TEST

--- This is Test2