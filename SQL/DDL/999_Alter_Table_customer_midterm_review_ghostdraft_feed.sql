IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'secondary_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD secondary_recommendation_message_1_id varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'primary_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD primary_recommendation_message_1_id varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'security_system_single_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD security_system_single_recommendation_message_1_id varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'security_system_multi_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD security_system_multi_recommendation_message_1_id varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'low_temp_single_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD low_temp_single_recommendation_message_1_id varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'low_temp_multi_recommendation_message_1_id')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD low_temp_multi_recommendation_message_1_id varchar(255);
END; 

