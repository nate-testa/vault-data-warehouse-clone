IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_eligibility_feed'
        AND LOWER(COLUMN_NAME) = 'latest_review_in')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_eligibility_feed ADD latest_review_in varchar(255);
END; 