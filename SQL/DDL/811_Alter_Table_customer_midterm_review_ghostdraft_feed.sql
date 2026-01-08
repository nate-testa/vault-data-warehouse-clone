IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'primary_home_monoline_in')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD primary_home_monoline_in varchar(255);
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'non_primary_home_monoline_in')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed ADD non_primary_home_monoline_in varchar(255);
END; 

IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'monoline_home_in')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed drop column monoline_home_in;
END; 

IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'customer_email')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed drop column customer_email;
END; 

IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'customer_nm')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed drop column customer_nm;
END; 

IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_ghostdraft_feed'
        AND LOWER(COLUMN_NAME) = 'customer_phone_no')
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_ghostdraft_feed drop column customer_phone_no;
END; 

