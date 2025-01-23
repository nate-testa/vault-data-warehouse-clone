IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote'
    AND     COLUMN_NAME = 'uw_company_original_policy_effective_dt'
) BEGIN ALTER TABLE edw_core.tquote ADD uw_company_original_policy_effective_dt date END; 