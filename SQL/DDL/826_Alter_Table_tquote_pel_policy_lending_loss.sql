IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_pel_policy_lending_loss'
AND COLUMN_NAME = 'quote_pel_lending_loss_sk'
)
BEGIN
	exec sp_rename 'edw_core.tquote_pel_policy_lending_loss.quote_pel_lending_loss_sk','quote_pel_policy_lending_loss_sk'
END;

