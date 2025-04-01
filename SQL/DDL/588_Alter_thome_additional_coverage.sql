
IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA = 'edw_core'
    AND     TABLE_NAME = 'thome_additional_coverage'
    AND     COLUMN_NAME = 'automatic_seismic_shutoff_valve_in'
)
BEGIN
    ALTER TABLE edw_core.thome_additional_coverage ADD automatic_seismic_shutoff_valve_in varchar(255) NULL
END