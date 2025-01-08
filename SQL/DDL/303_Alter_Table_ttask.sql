IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'ttask'
    AND     COLUMN_NAME = 'created_by_user_sk'
) BEGIN ALTER TABLE edw_core.ttask ADD created_by_user_sk int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'ttask'
    AND     COLUMN_NAME = 'assigned_to_user_sk'
) BEGIN ALTER TABLE edw_core.ttask ADD assigned_to_user_sk int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'ttask'
    AND     COLUMN_NAME = 'completed_by_user_sk'
) BEGIN ALTER TABLE edw_core.ttask ADD completed_by_user_sk int null END; 