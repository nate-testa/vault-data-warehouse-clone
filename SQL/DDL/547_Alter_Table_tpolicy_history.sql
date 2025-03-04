IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tpolicy_history'
    AND     COLUMN_NAME = 'transaction_status'
) BEGIN ALTER TABLE edw_core.tpolicy_history ADD transaction_status varchar(255) END 
 