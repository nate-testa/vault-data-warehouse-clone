IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_integration'
and TABLE_name = 'policy_claim_search_dms_api')
BEGIN

CREATE TABLE [edw_integration].[policy_claim_search_dms_api](
    [policy_no] [varchar](255) NOT NULL,
    [claim_no] [varchar](255) NOT NULL,
    [create_ts] [datetime] ,
    [update_ts] [datetime] ,
    [etl_audit_sk] [int] NULL ,
    CONSTRAINT pk_policy_claim_search_dms_api PRIMARY KEY (claim_no)
)
END ;  

INSERT INTO edw_integration.tintegration_table_detail(table_nm,table_type,table_desc,load_method,load_type,load_frequency,create_ts,update_ts) VALUES ('policy_claim_search_dms_api','API','This table outlines the claim numbers related to the ingestion of policy documents into the DMS, facilitating the DMS Policy Search API','Stored Procedure','Insert/Update','Daily',getdate(),getdate());