-- Broker commission statement email and address information 
CREATE TABLE edw_integration.broker_commission_email_api 
( 
commission_statement_email varchar(255), 
agency_code  varchar(255),
agency_name varchar(255), 
agency_city varchar(255),
agency_state varchar(255), 
create_ts datetime ,
update_ts datetime ,
etl_audit_sk int,
CONSTRAINT pk_broker_commission_email_api PRIMARY KEY(agency_code,commission_statement_email)
);

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,	load_frequency,	create_ts,update_ts)
VALUES ('broker_commission_email_api','API','This table provides broker commission statement email and address information in an API for billing team','Stored Procedure','Insert','Daily',getdate(),getdate());
