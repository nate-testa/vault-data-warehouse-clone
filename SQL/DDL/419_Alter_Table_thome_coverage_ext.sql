IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'thome_coverage_ext'
    AND     COLUMN_NAME = 'uniqueid'
) BEGIN ALTER TABLE edw_stage.thome_coverage_ext ADD uniqueid varchar(255) END;  

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'thome_coverage_ext'
    AND     COLUMN_NAME = 'objectgroupidentifier'
) BEGIN ALTER TABLE edw_stage.thome_coverage_ext ADD objectgroupidentifier varchar(255) END;  