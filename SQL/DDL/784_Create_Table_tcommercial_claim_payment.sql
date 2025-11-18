IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_commercial'
and TABLE_name = 'tcommercial_claim_payment')
BEGIN
CREATE TABLE [edw_commercial].[tcommercial_claim_payment]
(
	[commercial_claim_payment_sk] [int] IDENTITY(1,1) NOT NULL,
	[claim_no] [varchar](255) NULL,
	[commercial_claim_sk] [int] NULL,
	[commercial_claim_feature_sk] [int] NULL,
	[payment_sequence_no] [int] NULL,
	[payment_no] [varchar](255) NULL,
	[payment_status] [varchar](255) NULL,
	[claim_type_cd] [varchar](255) NULL,
	[cost_category] [varchar](255) NULL,	
	[settle_payee_id] [int] NULL, -- no
	[payee_nm] [varchar](255) NULL,
	[party_role_nm] [varchar](255) NULL,
	[paid_amt] [decimal](15, 2) NULL,
	[payee_address] [varchar](2000) NULL,
	[remark] [nvarchar](max) NULL,
	[payment_submitter_nm] [varchar](255) NULL,
	[payment_approver_nm] [varchar](255) NULL,
	[payment_submitted_dt] [date] NULL,
	[payment_approver_dt] [date] NULL,
	[payment_category_nm] [varchar](255) NULL,
	[partial_final_payment_desc] [varchar](255) NULL,
	[party_subtype_role_nm] [varchar](255) NULL,
	[source_system_sk] [int] NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,	
	CONSTRAINT pk_tcommercial_claim_payment PRIMARY KEY (commercial_claim_payment_sk),
	CONSTRAINT uidx_tcommercial_claim_payment_commercialclaimfeaturesk_paymentno_paymentsequenceno UNIQUE (payment_sequence_no),
	CONSTRAINT fk_tcommercial_claim_payment_claim_sk FOREIGN KEY (commercial_claim_sk) REFERENCES edw_commercial.tcommercial_claim(commercial_claim_sk),
	CONSTRAINT fk_tcommercial_claim_payment_source_system_sk FOREIGN KEY (source_system_sk) REFERENCES  edw_core.tsource_system(source_system_sk)
)
END