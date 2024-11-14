IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote'
    AND     COLUMN_NAME = 'issued_quote_history_sk'
) BEGIN ALTER TABLE edw_core.tquote ADD issued_quote_history_sk int END; 