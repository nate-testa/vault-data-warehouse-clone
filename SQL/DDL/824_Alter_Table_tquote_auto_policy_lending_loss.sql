

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_auto_policy_lending_loss'
AND COLUMN_NAME = 'quote_auto_lending_loss_sk'
)
BEGIN
	exec sp_rename 'edw_core.tquote_auto_policy_lending_loss.quote_auto_lending_loss_sk','quote_auto_policy_lending_loss_sk'
END;

