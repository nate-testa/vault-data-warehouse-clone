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
	update_ts datetime2(7)
); 
END;

delete from edw_core.tedw_table_detail
where table_nm = 'customer_midterm_review_message' ; 
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts,schema_nm) 
	VALUES ('','','Base','Common','Manual','Insert/Update','Static',getdate(),getdate(),'edw_stage');
	