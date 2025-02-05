IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_loss_history'
    AND     COLUMN_NAME = 'source_of_water'
) BEGIN ALTER TABLE edw_core.tquote_loss_history ADD source_of_water varchar(255)END
--

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_loss_history'
    AND     COLUMN_NAME = 'source_of_fire'
) BEGIN ALTER TABLE edw_core.tquote_loss_history ADD source_of_fire varchar(255)END

-- 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_loss_history'
    AND     COLUMN_NAME = 'include_in_rating_override_in'
) BEGIN ALTER TABLE edw_core.tquote_loss_history ADD include_in_rating_override_in varchar(255)END
--