IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_name = 'customer_midterm_review_eligibility_feed')
BEGIN

Create table edw_integration.customer_midterm_review_eligibility_feed
(
	customer_id varchar(50),
	midterm_review_year int,
	midterm_review_process_in varchar(255),
	midterm_review_completed_dt date,
	reason_desc varchar(255) ,
    data nvarchar(max) null,
	create_ts datetime2(7),
	update_ts datetime2(7),
	etl_audit_sk int    
); 

END ; 

IF EXISTS
(SELECT 1 FROM edw_integration.tintegration_table_detail
	where table_nm = 'customer_midterm_review_eligibility_feed')
BEGIN
	delete edw_integration.tintegration_table_detail
	where table_nm = 'customer_midterm_review_eligibility_feed' ; 
END ; 

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) 
VALUES ('customer_midterm_review_eligibility_feed','Feed','This table holds customer and their elibility status for midterm review','Stored Procedure','Full Load','Daily',getdate(),getdate());