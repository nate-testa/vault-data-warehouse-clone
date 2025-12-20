IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_stage'
AND TABLE_NAME = 'customer_midterm_review_message'
AND COLUMN_NAME = 'sequence_id'
) 
BEGIN 
    ALTER TABLE edw_stage.customer_midterm_review_message ADD sequence_id varchar(255) NULL
END ; 

IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_stage'
AND TABLE_NAME = 'customer_midterm_review_message'
AND COLUMN_NAME = 'line_ct'
) 
BEGIN 
    ALTER TABLE edw_stage.customer_midterm_review_message ADD line_ct int NULL
END ; 