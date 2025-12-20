IF NOT EXISTS (
SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='edw_integration'
AND TABLE_NAME = 'customer_midterm_review_eligibility_feed'
AND COLUMN_NAME = 'recommendation_message_id_seq_line_ct'
) 
BEGIN 
    ALTER TABLE edw_integration.customer_midterm_review_eligibility_feed ADD recommendation_message_id_seq_line_ct varchar(255) NULL
END ;  