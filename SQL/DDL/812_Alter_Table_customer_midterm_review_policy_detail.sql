IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_policy_detail'
        AND LOWER(COLUMN_NAME) = 'renewal_effective_date')
BEGIN
	EXEC sp_rename 
		'edw_integration.customer_midterm_review_policy_detail.renewal_effective_date',
		'effective_dt',
		'COLUMN';
END; 

IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'customer_midterm_review_policy_detail'
        AND LOWER(COLUMN_NAME) = 'renewal_expiration_date')
BEGIN
	EXEC sp_rename 
		'edw_integration.customer_midterm_review_policy_detail.renewal_expiration_date',
		'expiration_dt',
		'COLUMN';
END; 