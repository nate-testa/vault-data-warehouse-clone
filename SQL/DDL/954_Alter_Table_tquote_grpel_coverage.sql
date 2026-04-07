IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_coverage'
AND COLUMN_NAME = 'no_of_high_performance_vehicles'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage drop column no_of_high_performance_vehicles
   END ;

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_coverage'
AND COLUMN_NAME = 'no_of_boats_yachts'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage drop column no_of_boats_yachts
   END ;

IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_coverage'
AND COLUMN_NAME = 'reputational_injury_coverage_limit_amt'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_coverage drop column reputational_injury_coverage_limit_amt
   END ;
    