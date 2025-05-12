IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_note'
    AND     COLUMN_NAME = 'category_nm'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_note.category_nm', 'note_type', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_note'
    AND     COLUMN_NAME = 'user_type'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_note.user_type', 'contact_type', 'COLUMN' END;

-------------------------------

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_note'
    AND     COLUMN_NAME = 'claim_feature_sk'
) BEGIN ALTER TABLE edw_core.tclaim_note ADD claim_feature_sk int END;