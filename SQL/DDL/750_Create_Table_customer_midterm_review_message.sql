drop table if exists  edw_stage.customer_midterm_review_message ;  

	create table edw_stage.customer_midterm_review_message
	(
		message_id varchar(255),
		message_desc nvarchar(max),
		create_ts datetime2(7),
		update_ts datetime2(7)
	) ; 
	