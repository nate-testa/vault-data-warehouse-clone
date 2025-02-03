IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'claim_policy_search_snapsheet_api'
    AND     COLUMN_NAME = 'id'
) BEGIN ALTER TABLE edw_integration.claim_policy_search_snapsheet_api
ADD id [int] IDENTITY(1,1) NOT NULL END