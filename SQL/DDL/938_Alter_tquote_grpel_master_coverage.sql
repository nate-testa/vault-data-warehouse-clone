
   IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_master_coverage'
AND COLUMN_NAME = 'enrollment_initial_start_dt'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_master_coverage drop column enrollment_initial_start_dt
   END ;
    


   IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_master_coverage'
AND COLUMN_NAME = 'enrollment_preiod_in_days'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_master_coverage drop column enrollment_preiod_in_days;
   END ;    


   IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_master_coverage'
AND COLUMN_NAME = 'enrollment_frequency'
)
BEGIN
    ALTER TABLE edw_core.tquote_grpel_master_coverage drop column enrollment_frequency;
END ;


   IF EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_core'
AND TABLE_NAME = 'tquote_grpel_master_coverage'
AND COLUMN_NAME = 'override_enrollment_to_open_in'
)
   BEGIN
    ALTER TABLE edw_core.tquote_grpel_master_coverage drop column override_enrollment_to_open_in;
END ;
