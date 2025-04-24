if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_core'
and table_name = 'tclaim_tag')
begin
create table edw_core.tclaim_tag(
    claim_tag_sk int NOT NULL IDENTITY(1,1),
claim_sk varchar(255) ,
claim_no varchar(255) ,
tag_nm varchar(255),
tag_created_ts DATETIME NOT NULL,
tag_updated_ts DATETIME NOT NULL, 
source_system_sk INT NOT NULL, 
etl_audit_sk INT NOT NULL,
create_ts DATETIME2(7) ,
update_ts DATETIME2(7) ,
CONSTRAINT pk_tclaim_tag PRIMARY KEY (claim_tag_sk),
CONSTRAINT fk_tclaim_tag_claim_sk FOREIGN KEY (claim_sk) REFERENCES  edw_core.tclaim(claim_sk),
CONSTRAINT fk_tclaim_tag_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
)
end ; 