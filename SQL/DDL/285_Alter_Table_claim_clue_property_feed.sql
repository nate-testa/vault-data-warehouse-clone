IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE type = 'UQ' -- 'C' is for check constraints, 'PK' for primary keys, 'UQ' for unique constraints, 'F' for foreign keys
    AND name = 'uidx_claim_clue_property_feed'
)
BEGIN
    ALTER TABLE [edw_integration].[claim_clue_property_feed]  DROP CONSTRAINT  uidx_claim_clue_property_feed
END
ELSE
BEGIN
ALTER TABLE [edw_integration].[claim_clue_property_feed] ADD  CONSTRAINT [uidx_claim_clue_property_feed] UNIQUE NONCLUSTERED 
(
	[claimNumber] ASC,
    [causeOfLoss] ASC,
	[report_start_date] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END
