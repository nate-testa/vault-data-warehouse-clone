IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_stage'
AND TABLE_NAME = 'AccountObject'
AND LOWER(COLUMN_NAME) = 'IsDeletedOnRenewal'
) BEGIN ALTER TABLE edw_stage.AccountObject ADD IsDeletedOnRenewal bit NULL END ;

select * from edw_stage.AccountObject