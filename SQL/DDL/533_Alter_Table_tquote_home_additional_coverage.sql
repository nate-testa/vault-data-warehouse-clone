
IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_additional_coverage'
    AND     COLUMN_NAME = 'theft_or_loss_general_conditions_endorsement_in'
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD theft_or_loss_general_conditions_endorsement_in varchar(255);


IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_home_additional_coverage'
    AND     COLUMN_NAME = 'theft_or_loss_general_conditions_endorsement_in'
) BEGIN ALTER TABLE edw_core.tquote_home_additional_coverage ADD theft_or_loss_general_conditions_endorsement_in varchar(255);
