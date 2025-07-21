--Policies
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy','Type-1 Dimension','Base','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_coverage','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_history','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_quota_share','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_subjectivity','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_tower','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_policy_transaction','Fact','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_broker_summary','Fact','Datamart','Policy','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_daily_inforce_policy','Fact','Datamart','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_renewal_summary','Fact','Datamart','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());

--Quotes

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote','Type-1 Dimension','Base','Quote','Stored Procedure','Insert/Update','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_coverage','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_history','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_quota_share','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_subjectivity','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_tower','Type-2 Dimension','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_quote_transaction','Fact','Base','Quote','Stored Procedure','Insert','Daily',getdate(),getdate());