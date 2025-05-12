IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tauto_policy_coverage'
    AND     COLUMN_NAME = 'sdip_points_no'
) BEGIN ALTER TABLE edw_core.tauto_policy_coverage DROP COLUMN sdip_points_no end
ELSE  
print 'Column doesnt exist' 
