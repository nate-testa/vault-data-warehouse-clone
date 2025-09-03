IF NOT EXISTS
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_name = 'broker_claim_metal_feed')
BEGIN

CREATE TABLE [edw_integration].[broker_claim_metal_feed](
    [broker_id] [varchar](255) NOT NULL,
    [loss_ratio] [decimal](15, 2) NULL,
    [create_ts] [datetime] ,
    [update_ts] [datetime] ,
    [etl_audit_sk] [int] NULL ,
    CONSTRAINT pk_broker_claim_metal_feed PRIMARY KEY (broker_id)
)
END ;  

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) VALUES ('broker_claim_metal_feed','Feed','This table provides rolling one year loss ratio per broker','Stored Procedure','Full Load','Daily',getdate(),getdate());

