 IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'trenewal_summary_v1')
BEGIN

CREATE TABLE [edw_stage].[trenewal_summary_v1](
	[month_sk] [int] NOT NULL,
	[policy_sk] [int] NOT NULL,
	[customer_sk] [int] NULL,
	[broker_sk] [int] NULL,
	[product_sk] [int] NULL,
	[expiring_initial_written_premium_amt] [decimal](15, 2) NULL,
	[expiring_sixty_day_written_premium_amt] [decimal](15, 2) NULL,
	[expiring_sixty_day_commission_amt] [decimal](15, 2) NULL,
	[expiring_mid_term_cancelled_premium_amt] [decimal](15, 2) NULL,
	[expiring_written_premium_amt] [decimal](15, 2) NULL,
	[expiring_premium_renewal_accepted_amt] [decimal](15, 2) NULL,
	[expiring_non_renewal_written_premium_amt] [decimal](15, 2) NULL,
	[expiring_total_finished_square_feet] [decimal](15, 2) NULL,
	[expiring_residence_type] [varchar](255) NULL,
	[expiring_sixty_day_tiv_amt] [decimal](15, 2) NULL,
	[expiring_sixty_day_cova_amt] [decimal](15, 2) NULL,
	[expiring_tiv_amt] [decimal](15, 2) NULL,
	[expiring_tiv_post_nr_amt] [decimal](15, 2) NULL,
	[expiring_cova_amt] [decimal](15, 2) NULL,
	[flat_cancelled_ct] [int] NOT NULL,
	[non_flat_cancelled_ct] [int] NOT NULL,
	[mid_term_cancelled_ct] [int] NOT NULL,
	[expiring_ct] [int] NOT NULL,
	[non_renewal_ct] [int] NOT NULL,
	[renewal_policy_sk] [int] NULL,
	[renewal_ct] [int] NOT NULL,
	[renewal_non_flat_cancelled_ct] [int] NOT NULL,
	[renewal_initial_written_premium_amt] [decimal](15, 2) NULL,
	[renewal_sixty_day_written_premium_amt] [decimal](15, 2) NULL,
	[renewal_sixty_day_commission_amt] [decimal](15, 2) NULL,
	[renewal_sixty_day_tiv_amt] [decimal](15, 2) NULL,
	[renewal_sixty_day_cova_amt] [decimal](15, 2) NULL,
	[renewal_accepted_price_sqft] [decimal](15, 2) NULL,
	[source_system_sk] [int] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
	[uw_company_cd] [varchar](255) NULL,
	[wip_renewal_quote_ct] [int] NULL,
	[offered_or_not_taken_quote_ct] [int] NULL,
	[renewal_quote_sk] [int] NULL,
	[expiring_customer_other_inforce_ct] [int] NULL,
	[expiring_pending_non_renewal_written_premium_amt] [decimal](15, 2) NULL,
	[renewal_tiv_amt] [decimal](15, 2) NULL,
	[renewal_cova_amt] [decimal](15, 2) NULL,
	[renewal_total_finished_square_feet] [decimal](15, 2) NULL,
	[expiring_mid_term_endorsement_premium_amt] [decimal](15, 2) NULL,
	[expiring_price_sqft] [decimal](15, 2) NULL,
	[issued_price_sqft] [decimal](15, 2) NULL,
	[renewal_offered_price_sqft] [decimal](15, 2) NULL,
	[cancellation_reason_desc] [varchar](255) NULL,
	[renewal_quote_written_premium_amt] [decimal](15, 2) NULL,
	[renewal_quote_tiv_amt] [int] NULL,
	[renewal_quote_dwelling_limit_amt] [int] NULL,
	[renewal_quote_other_structures_limit_amt] [int] NULL,
	[renewal_quote_contents_limit_amt] [int] NULL,
	[renewal_quote_loss_of_use_limit_amt] [varchar](255) NULL,
	[product_nm] [varchar](255) NULL,
	[renewal_quote_note_desc] [nvarchar](max) NULL,
	[pending_non_renewal_ct] [int] NULL,
	[renewal_quote_agency_primary_location_state_cd] [varchar](255) NULL,
	[expiring_sixty_day_rate_on_line] [decimal](15, 2) NULL,
	[renewal_sixty_day_rate_on_line] [decimal](15, 2) NULL,
	[renewal_quote_rate_on_line] [decimal](15, 2) NULL,
	[expiring_rate_on_line] [decimal](15, 2) NULL,
	[accepted_renewal_ct] [int] NULL,
	[not_accepted_renewal_ct] [int] NULL,
	[outstanding_renewal_ct] [int] NULL,
	[offered_quote_ct] [int] NULL,
	[prior_issued_ct] [int] NULL,
	[in_progress_renewal_ct] [int] NULL,
	[closed_with_no_offer_renewal_ct] [int] NULL,
	[offered_quote_premium_amt] [decimal](15, 2) NULL,
	[prior_issued_premium_amt] [decimal](15, 2) NULL,
	expired_with_no_submission_ct int,
 CONSTRAINT [pk_trenewal_summary_v1] PRIMARY KEY CLUSTERED 
(
	[month_sk] ASC,
	[policy_sk] ASC
)ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY] 

ALTER TABLE [edw_stage].[trenewal_summary_v1]  WITH CHECK ADD  CONSTRAINT [fk_trs_tbroker_broker_sk] FOREIGN KEY([broker_sk])
REFERENCES [edw_core].[tbroker] ([broker_sk]) 

ALTER TABLE [edw_stage].[trenewal_summary_v1] CHECK CONSTRAINT [fk_trs_tbroker_broker_sk] 

ALTER TABLE [edw_stage].[trenewal_summary_v1]  WITH CHECK ADD  CONSTRAINT [fk_trs_tcustomer_customer_sk] FOREIGN KEY([customer_sk])
REFERENCES [edw_core].[tcustomer] ([customer_sk]) 

ALTER TABLE [edw_stage].[trenewal_summary_v1] CHECK CONSTRAINT [fk_trs_tcustomer_customer_sk] 

ALTER TABLE [edw_stage].[trenewal_summary_v1]  WITH CHECK ADD  CONSTRAINT [fk_trs_tpolicy_policy_sk] FOREIGN KEY([policy_sk])
REFERENCES [edw_core].[tpolicy] ([policy_sk]) 

ALTER TABLE [edw_stage].[trenewal_summary_v1] CHECK CONSTRAINT [fk_trs_tpolicy_policy_sk] 

ALTER TABLE [edw_stage].[trenewal_summary_v1]  WITH CHECK ADD  CONSTRAINT [fk_trs_tproduct_product_sk] FOREIGN KEY([product_sk])
REFERENCES [edw_core].[tproduct] ([product_sk]) 

ALTER TABLE [edw_stage].[trenewal_summary_v1] CHECK CONSTRAINT [fk_trs_tproduct_product_sk] 

ALTER TABLE [edw_stage].[trenewal_summary_v1]  WITH CHECK ADD  CONSTRAINT [fk_trs_tsource_system_source_system_sk] FOREIGN KEY([source_system_sk])
REFERENCES [edw_core].[tsource_system] ([source_system_sk]) 

ALTER TABLE [edw_stage].[trenewal_summary_v1] CHECK CONSTRAINT [fk_trs_tsource_system_source_system_sk] 

end


