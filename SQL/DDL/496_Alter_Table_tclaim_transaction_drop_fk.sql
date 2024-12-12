IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'fk_tclaim_transaction_claim_payment_sk'
      AND parent_object_id = OBJECT_ID('[edw_core].[tclaim_transaction]')
)
BEGIN
    ALTER TABLE [edw_core].[tclaim_transaction]
    DROP CONSTRAINT [fk_tclaim_transaction_claim_payment_sk];
END;
