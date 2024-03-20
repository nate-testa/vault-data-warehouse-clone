IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tinternal_coverage_inforce'
    AND     COLUMN_NAME = 'commission_amt'
) BEGIN ALTER TABLE edw_core.tinternal_coverage_inforce ADD commission_amt decimal (15,2) null END;