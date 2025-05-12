IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'quote_note_hubspot_feed'
    AND     COLUMN_NAME = 'note_user_nm'
) BEGIN ALTER TABLE edw_integration.quote_note_hubspot_feed ADD note_user_nm varchar(255) END; 
