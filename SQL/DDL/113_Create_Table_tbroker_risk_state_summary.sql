CREATE TABLE [edw_core].[tbroker_risk_state_summary](
    [month_sk] [int] NOT NULL,
    [broker_sk] [int] NOT NULL,
    [risk_state_sk] [int] NOT NULL, 
    [quote_ct] [int] NOT NULL,
    [bind_ct] [int] NOT NULL,
    [ytd_new_business_ct] [int] NOT NULL,
    [ytd_new_business_net_premium_amt] [decimal](15, 2) NULL,
    [inforce_ct] [int] NOT NULL,
    [inforce_net_premium_amt] [decimal](15, 2) NULL, 
    [non_admitted_inforce_ct] [int] NOT NULL,
    [admitted_inforce_ct] [int] NOT NULL,
    [non_admitted_inforce_net_premium_amt] [decimal](15, 2) NULL,
    [admitted_inforce_net_premium_amt] [decimal](15, 2) NULL,
    [update_ts] [datetime] NULL,
    [etl_audit_sk] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [edw_core].[tbroker_risk_state_summary] ADD  CONSTRAINT [pk_tbroker_risk_state_summary] PRIMARY KEY CLUSTERED
(
    [month_sk] ASC,
    [broker_sk] ASC,
    [risk_state_sk] ASC 
)
GO
ALTER TABLE edw_core.tbroker_risk_state_summary
ADD  CONSTRAINT fk_tbrss_tbroker_broker_sk FOREIGN KEY(broker_sk)
REFERENCES edw_core.tbroker (broker_sk); 
ALTER TABLE edw_core.tbroker_risk_state_summary  
ADD  CONSTRAINT fk_tbrss_tstate_state_sk FOREIGN KEY(risk_state_sk)
REFERENCES edw_core.tstate (state_sk);


INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tbroker_risk_state_summary','Fact','Datamart','Broker','Stored Procedure','Insert','Daily',getdate(),getdate());