IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_policy_detail'
        AND LOWER(COLUMN_NAME) = 'customer_since_dt')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_policy_detail ADD customer_since_dt date;
END; 

