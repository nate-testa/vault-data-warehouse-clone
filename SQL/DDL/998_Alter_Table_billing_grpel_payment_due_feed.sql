IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'billing_grpel_payment_due_feed'
      AND COLUMN_NAME = 'total_premium'
)
BEGIN
    exec sp_rename 'edw_integration.billing_grpel_payment_due_feed.total_premium','total_participant_premium';
END;

IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'billing_grpel_payment_due_feed'
      AND COLUMN_NAME = 'payments_made'
)
BEGIN
    exec sp_rename 'edw_integration.billing_grpel_payment_due_feed.payments_made','payments_received';
END;

IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'billing_grpel_payment_due_feed'
      AND COLUMN_NAME = 'balance_due_as_of_month_end'
)
BEGIN
    exec sp_rename 'edw_integration.billing_grpel_payment_due_feed.balance_due_as_of_month_end','net_amount_due_to_vault';
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'billing_grpel_payment_due_feed'
      AND COLUMN_NAME = 'group_minimum_premium'
)
BEGIN
    ALTER TABLE edw_integration.billing_grpel_payment_due_feed ADD group_minimum_premium DECIMAL(15,2);
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_integration'
      AND TABLE_NAME = 'billing_grpel_payment_due_feed'
      AND COLUMN_NAME = 'broker_commission'
)
BEGIN
    ALTER TABLE edw_integration.billing_grpel_payment_due_feed ADD broker_commission DECIMAL(15,2);
END;
