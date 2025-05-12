IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_core'
and TABLE_name = 'tbroker_servicing_team_member')
BEGIN
CREATE TABLE edw_core.tbroker_servicing_team_member
(
broker_servicing_team_member_sk          int IDENTITY(1,1) NOT NULL,
broker_servicing_team_sk                int NOT NULL,
full_nm                  varchar(255),
first_nm                 varchar(255),
last_nm                  varchar(255),
email                    varchar(255),
phone_no                 varchar(255),
create_ts                datetime,
update_ts                datetime,
etl_audit_sk             int,
CONSTRAINT pk_tbroker_servicing_team_member PRIMARY KEY (broker_servicing_team_member_sk),
CONSTRAINT fk_tbroker_servicing_team_member_broker_servicing_team_sk FOREIGN KEY (broker_servicing_team_sk) REFERENCES edw_core.tbroker_servicing_team(broker_servicing_team_sk)
)
END;

If not exists (
select * from edw_core.tedw_table_detail
where table_nm='tbroker_servicing_team_member'
)
BEGIN
INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_servicing_team_member','Type-1 Dimension','Base','Broker','Stored Procedure','Full Load','Daily',getdate(),getdate())
END;