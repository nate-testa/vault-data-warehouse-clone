IF NOT EXISTS
(SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'edw_integration'
AND TABLE_NAME = 'commercial_claim_renewal_rating_api')
BEGIN
CREATE TABLE [edw_integration].[commercial_claim_renewal_rating_api]
(
[DateOfLoss] [varchar](255) NULL,
[PolicyNumber] [varchar](255) NULL,
[Litigation] [varchar](255) NULL,
[LitigationComplete] [varchar](255) NULL,
[ClaimNumber] [varchar](255) NOT NULL,
[ClaimStatus] [varchar](255) NULL,
[Claimant] [varchar](255) NULL,
[LastUpdate] [varchar](255) NULL,
[CauseOfLoss] [varchar](255) NULL,
[FactOfLoss] [varchar](255) NULL,
[AdditionalFactOfLoss] [varchar](255) NULL,
[LargeLoss] [varchar](255) NULL,
[CurrentIndemnityReserve] [decimal](15, 2) NULL,
[TotalIndemnityPayment] [decimal](15, 2) NULL,
[CurrentExpenseReserve] [decimal](15, 2) NULL,
[TotalExpensePayment] [decimal](15, 2) NULL,
[CurrentLegalDefenseReserve] [decimal](15, 2) NULL,
[TotalLegalDefensePayment] [decimal](15, 2) NULL,
[TotalIncurredPayment] [decimal](15, 2) NULL,
[AdjusterName] [varchar](255) NULL,
[create_ts] [datetime] NULL,
[update_ts] [datetime] NULL,
[etl_audit_sk] [int] NULL
)
END
IF EXISTS
    (
        SELECT 1 FROM edw_integration.tintegration_table_detail
        where table_nm = 'commercial_claim_renewal_rating_api'
    )
BEGIN
    delete FROM edw_integration.tintegration_table_detail
    where table_nm = 'commercial_claim_renewal_rating_api'
END
INSERT INTO edw_integration.tintegration_table_detail (
    table_nm,
    table_type,
    table_desc,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'commercial_claim_renewal_rating_api',
    'API',
    'This table provides claim details for renewal rating of commercial lines policies',
    'Stored Procedure',
    'Insert',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_integration.tintegration_table_detail
    WHERE table_nm = 'commercial_claim_renewal_rating_api'
)
