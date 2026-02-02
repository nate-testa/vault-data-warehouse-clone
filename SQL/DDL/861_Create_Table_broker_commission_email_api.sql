-- Broker commission statement email and address information 
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[edw_integration].[broker_commission_email_api]') AND type in (N'U'))
BEGIN
CREATE TABLE edw_integration.broker_commission_email_api 
( 
broker_id  varchar(255),
broker_nm varchar(255), 
broker_city_nm varchar(255),
broker_state_cd varchar(255), 
commission_statement_email varchar(2000), 
create_ts datetime2(7),
update_ts datetime2(7) ,
etl_audit_sk int,
CONSTRAINT pk_broker_commission_email_api PRIMARY KEY(broker_id,commission_statement_email)
);
END;

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method, load_type,	load_frequency,	create_ts,update_ts)
VALUES ('broker_commission_email_api','API','This table provides broker commission statement email and address information in an API for billing team','Stored Procedure','Insert','Daily',getdate(),getdate());

