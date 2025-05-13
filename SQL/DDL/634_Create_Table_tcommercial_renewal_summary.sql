CREATE TABLE [edw_commercial].[tcommercial_renewal_summary](
    [month_sk] [int] NOT NULL,
    [commercial_policy_sk] [int] NOT NULL,
    [customer_sk] [int] NULL,
    [broker_sk] [int] NULL,
    [product_sk] [int] NULL,
    [expiring_mid_term_cancelled_premium_amt] [decimal](15, 2) NULL,
    [expiring_written_premium_amt] [decimal](15, 2) NULL,
    [expiring_non_renewal_written_premium_amt] [decimal](15, 2) NULL,
    [expiring_pending_non_renewal_written_premium_amt] [decimal](15, 2) NULL,
    [expiring_mid_term_endorsement_premium_amt] [decimal](15, 2) NULL,
    [expiring_limit_amt] [decimal](15, 2) NULL,
    [expiring_attachment_amt] [decimal](15, 2) NULL,
    [flat_cancelled_ct] [int] NOT NULL,
    [non_flat_cancelled_ct] [int] NOT NULL,
    [mid_term_cancelled_ct] [int] NOT NULL,
    [expiring_ct] [int] NOT NULL,
    [non_renewal_ct] [int] NOT NULL,
    [pending_non_renewal_ct] [int] NULL,
    [renewal_ct] [int] NOT NULL,
    [renewal_commercial_policy_sk] [int] NULL,
    [renewal_non_flat_cancelled_ct] [int] NOT NULL,
    [renewal_limit_amt] [decimal](15, 2) NULL,
    [renewal_attachment_amt] [decimal](15, 2) NULL,
    [wip_renewal_quote_ct] [int] NULL,
    [offered_or_not_taken_quote_ct] [int] NULL,
    [renewal_commercial_quote_sk] [int] NULL,
    [renewal_quote_written_premium_amt] [decimal](15,2) NULL,
    [renewal_quote_limit_amt] [int] NULL,
    [renewal_quote_attachement_amt] [int] NULL,  
    [source_system_sk] [int] NULL,
    [update_ts] [datetime] NULL,
    [etl_audit_sk] [int] NULL
 CONSTRAINT [pk_tcommercial_renewal_summary] PRIMARY KEY CLUSTERED 
(
	[month_sk] ASC,
	[commercial_policy_sk] ASC
) 
)  

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary]  WITH CHECK ADD  CONSTRAINT [fk_trs_tbroker_broker_sk] FOREIGN KEY([broker_sk])
REFERENCES [edw_core].[tbroker] ([broker_sk]) 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary] CHECK CONSTRAINT [fk_trs_tbroker_broker_sk] 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary]  WITH CHECK ADD  CONSTRAINT [fk_trs_tcustomer_customer_sk] FOREIGN KEY([customer_sk])
REFERENCES [edw_core].[tcustomer] ([customer_sk]) 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary] CHECK CONSTRAINT [fk_trs_tcustomer_customer_sk] 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary]  WITH CHECK ADD  CONSTRAINT [fk_trs_tcommercial_policy_commercial_policy_sk] FOREIGN KEY([commercial_policy_sk])
REFERENCES [edw_commercial].[tcommercial_policy] ([commercial_policy_sk]) 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary] CHECK CONSTRAINT [fk_trs_tcommercial_policy_commercial_policy_sk] 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary]  WITH CHECK ADD  CONSTRAINT [fk_trs_tproduct_product_sk] FOREIGN KEY([product_sk])
REFERENCES [edw_core].[tproduct] ([product_sk]) 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary] CHECK CONSTRAINT [fk_trs_tproduct_product_sk] 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary]  WITH CHECK ADD  CONSTRAINT [fk_trs_tsource_system_source_system_sk] FOREIGN KEY([source_system_sk])
REFERENCES [edw_core].[tsource_system] ([source_system_sk]) 

ALTER TABLE [edw_commercial].[tcommercial_renewal_summary] CHECK CONSTRAINT [fk_trs_tsource_system_source_system_sk] 


