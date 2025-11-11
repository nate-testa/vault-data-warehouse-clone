IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'account_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD account_id UNIQUEIDENTIFIER NULL;
END; 