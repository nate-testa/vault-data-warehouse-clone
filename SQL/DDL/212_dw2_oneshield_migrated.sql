IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'dw2_oneshield_migrated'
    AND     COLUMN_NAME = 'priorpolicynumber'
) BEGIN 
ALTER TABLE edw_stage.dw2_oneshield_migrated ADD priorpolicynumber varchar(255);
END; 