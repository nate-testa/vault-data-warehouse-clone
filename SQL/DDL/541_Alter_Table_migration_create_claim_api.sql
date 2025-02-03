IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'migration_create_claim_api'
    AND     COLUMN_NAME = 'id'
) BEGIN ALTER TABLE edw_stage.migration_create_claim_api ADD id [int] IDENTITY(1,1) NOT NULL END