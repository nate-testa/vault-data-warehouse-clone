
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());