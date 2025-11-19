If not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_commercial'
and table_name = 'tcommercial_claim_tag')
begin
create table edw_commercial.tcommercial_claim_tag
(
commercial_claim_tag_sk int NOT NULL IDENTITY(1,1),
commercial_claim_sk int not null,
claim_no varchar(255) not null,
tag_nm varchar(255),
tag_created_ts DATETIME,
source_system_sk INT NOT NULL, 
etl_audit_sk INT NOT NULL,
create_ts DATETIME2(7) NOT NULL,
update_ts DATETIME2(7) NOT NULL,
CONSTRAINT pk_tcommercial_claim_tag PRIMARY KEY (commercial_claim_tag_sk),
CONSTRAINT fk_tcommercial_claim_tag_claim_sk FOREIGN KEY (commercial_claim_sk) REFERENCES  edw_commercial.tcommercial_claim(commercial_claim_sk),
CONSTRAINT fk_tcommercial_claim_tag_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
)
end ;

If not exists (
select * from edw_core.tedw_table_detail 
where table_nm='tcommercial_claim_tag'
)
begin
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tcommercial_claim_tag','Type-2 Dimension','Base','Claim','Stored Procedure','Insert','Daily',getdate(),getdate())
end;