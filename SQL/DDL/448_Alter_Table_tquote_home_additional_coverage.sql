IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_additional_coverage'
    AND     COLUMN_NAME = 'fortified_roof_program_discount_amt'
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD fortified_roof_program_discount_amt FLOAT END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_additional_coverage'
    AND     COLUMN_NAME = 'non_program_discount_amt'
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD non_program_discount_amt FLOAT END;




