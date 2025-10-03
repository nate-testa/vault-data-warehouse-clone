
	drop table if exists edw_integration.customer_midterm_review_eligibility_feed ; 

	Create table edw_integration.customer_midterm_review_eligibility_feed
	(
		customer_id varchar(50),
		midterm_review_year int,
		midterm_review_process_in varchar(255),
		reason_desc varchar(255),
        data nvarchar(max) null,
		create_ts datetime2(7),
		update_ts datetime2(7),
		etl_audit_sk int    
	); 