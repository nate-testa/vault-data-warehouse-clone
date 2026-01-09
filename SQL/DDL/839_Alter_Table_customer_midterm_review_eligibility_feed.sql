IF NOT EXISTS (
    SELECT *
    FROM sys.key_constraints kc
    WHERE kc.[type] = 'PK'
      AND kc.parent_object_id = OBJECT_ID('edw_integration.customer_midterm_review_eligibility_feed')
)
BEGIN
    ALTER TABLE edw_integration.customer_midterm_review_eligibility_feed
	ADD CONSTRAINT pk_customer_midterm_review_eligibility PRIMARY KEY (customer_id, midterm_review_year);
END;