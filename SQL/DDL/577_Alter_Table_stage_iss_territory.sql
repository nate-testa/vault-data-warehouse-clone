IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'stage_iss_territory'
    AND     COLUMN_NAME = 'line'
)
BEGIN
ALTER TABLE edw_stage.stage_iss_territory ADD line varchar(255) NULL 
END ;