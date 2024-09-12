CREATE TABLE [edw_stage].[hubspot_company_goals](
	[agency_code] [varchar](255) NOT NULL,
	[last_activity_date] [datetime] NOT NULL,
	[target_2024_gross_nb_premium_ytd] [decimal](15, 2) NULL,
	[target_monthly_nb_quote_commitment_$] [decimal](15, 2) NULL,
	[target_monthly_nb_policy_counts] [int] NULL,
	[target_2024_policy_inforce_renewal_rentention_pct] [decimal](15, 2) NULL,
	[pct_target_growth_2024_inforce_premium_over_last_year] [decimal](15, 2) NULL,
	[pct_target_growth_2024_nb_premium_over_last_year] [decimal](15, 2) NULL, 
	CONSTRAINT pk_hubspot_company_goals PRIMARY KEY (agency_code) 
)  