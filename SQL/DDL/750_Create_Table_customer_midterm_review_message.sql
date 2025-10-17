IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'customer_midterm_review_message')
BEGIN

create table edw_stage.customer_midterm_review_message
(
	message_id varchar(255),
	message_desc nvarchar(max),
	create_ts datetime2(7),
	update_ts datetime2(7),
	CONSTRAINT pk_customer_midterm_review_message PRIMARY KEY (message_id)
); 
END;