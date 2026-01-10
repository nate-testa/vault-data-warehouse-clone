

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tauto_policy_lending_loss'
AND COLUMN_NAME = 'auto_lending_loss_sk'
)
BEGIN
	exec sp_rename 'edw_core.tauto_policy_lending_loss.auto_lending_loss_sk','auto_policy_lending_loss_sk'
END;

