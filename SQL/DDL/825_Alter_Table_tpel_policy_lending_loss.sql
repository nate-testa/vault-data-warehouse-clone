

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tpel_policy_lending_loss'
AND COLUMN_NAME = 'pel_lending_loss_sk'
)
BEGIN
	exec sp_rename 'edw_core.tpel_policy_lending_loss.pel_lending_loss_sk','pel_policy_lending_loss_sk'
END;

