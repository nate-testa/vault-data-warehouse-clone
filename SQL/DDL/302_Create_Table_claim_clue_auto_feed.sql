IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE  TABLE_SCHEMA='edw_integration'
    AND TABLE_NAME = 'claim_clue_auto_feed' 
) 
BEGIN 
PRINT 'Table exists'
END
ELSE
BEGIN
CREATE TABLE [edw_integration].[claim_clue_auto_feed](
	[PolicyHolderNamePrefix] [char](4) NULL,
	[PolicyHolderNameLast] [char](20) NULL,
	[PolicyHolderNameFirst] [char](20) NULL,
	[PolicyHolderNameMiddle] [char](15) NULL,
	[PolicyHolderNameSuffix] [char](3) NULL,
	[PolicyHolderMailAddrHseNum] [char](9) NULL,
	[PolicyHolderMailAddressStreetName] [char](20) NULL,
	[PolicyHolderMailAddressAptNum] [char](5) NULL,
	[PolicyHolderMailAddressCity] [char](20) NULL,
	[PolicyHolderMailAddressState] [char](2) NULL,
	[PolicyHolderMailAddressZip] [char](5) NULL,
	[PolicyHolderMailAddressZipPlus4] [char](4) NULL,
	[Filler_reservedForFutureUse1] [char](10) NULL,
	[PolicyHolderSSN] [char](9) NULL,
	[PolicyHolderDOB] [char](8) NULL,
	[PolicyHolderDriversLicenseNum] [char](25) NULL,
	[PolicyHolderDriversLicenseState] [char](2) NULL,
	[PolicyHolderSex] [char](1) NULL,
	[Filler_reservedForFutureUse2] [char](28) NULL,
	[PolicyHolder2NamePrefix] [char](4) NULL,
	[PolicyHolder2NameLast] [char](20) NULL,
	[PolicyHolder2NameFirst] [char](20) NULL,
	[PolicyHolder2NameMiddle] [char](15) NULL,
	[PolicyHolder2NameSuffix] [char](3) NULL,
	[PolicyHolder2SSN] [char](9) NULL,
	[PolicyHolder2DOB] [char](8) NULL,
	[PolicyHolder2DriversLicenseNum] [char](25) NULL,
	[PolicyHolder2DriversLicenseState] [char](2) NULL,
	[PolicyHolder2Sex] [char](1) NULL,
	[Filler_reservedForFutureUse3] [char](18) NULL,
	[VehicleOperatorNamePrefix] [char](4) NULL,
	[VehicleOperatorNameLast] [char](20) NULL,
	[VehicleOperatorNameFirst] [char](20) NULL,
	[VehicleOperatorNameMiddle] [char](15) NULL,
	[VehicleOperatorNameSuffix] [char](3) NULL,
	[VehicleOperatorAddrHseNum] [char](9) NULL,
	[VehicleOperatorAddrStreetName] [char](20) NULL,
	[VehicleOperatorAddrAptNum] [char](5) NULL,
	[VehicleOperatorAddrCity] [char](20) NULL,
	[VehicleOperatorAddrState] [char](2) NULL,
	[VehicleOperatorAddrZipCode] [char](5) NULL,
	[VehicleOperatorAddrZipPlus4] [char](4) NULL,
	[Filler_reservedForFutureUse4] [char](10) NULL,
	[VehicleOperatorSSN] [char](9) NULL,
	[VehicleOperatorDOB] [char](8) NULL,
	[VehicleOperatorDriversLicenseNum] [char](25) NULL,
	[VehicleOperatorDriversLicenseState] [char](2) NULL,
	[VehicleOperatorSex] [char](1) NULL,
	[VehicleOperatorRelationship] [char](1) NULL,
	[Filler_reservedForFutureUse5] [char](28) NULL,
	[contribCompany] [char](5) NULL,
	[PolicyNumber] [char](20) NULL,
	[PolicyType] [char](2) NULL,
	[Filler_reservedForFutureUse6] [char](18) NULL,
	[ClaimNumber] [char](20) NULL,
	[ClaimType] [char](2) NULL,
	[ClaimDate] [char](8) NULL,
	[ClaimAmount] [char](9) NULL,
	[ClaimReportingStatus] [char](1) NULL,
	[InsuredVehicleVIN] [char](25) NULL,
	[InsuredVehicleModelYear] [char](4) NULL,
	[InsuredVehicleMakeModel] [char](40) NULL,
	[InsuredVehicleDisposition] [char](1) NULL,
	[ClaimDisposition] [char](1) NULL,
	[FaultIndicator] [char](1) NULL,
	[DateofFirstPayment] [char](8) NULL,
	[CAIndicator1] [char](1) NULL,
	[CAIndicator2] [char](1) NULL,
	[CAIndicator3] [char](1) NULL,
	[CAIndicator4] [char](1) NULL,
	[Filler_reservedForFutureUse7] [char](24) NULL,
	[RecordVersionNumber] [char](1) NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL,
	[report_start_date] [datetime] NULL,
	[report_end_date] [datetime] NULL
) ON [PRIMARY]
END

IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE type = 'UQ' -- 'C' is for check constraints, 'PK' for primary keys, 'UQ' for unique constraints, 'F' for foreign keys
    AND name = 'uidx_claim_clue_auto_feed'
)
BEGIN
    ALTER TABLE [edw_integration].[claim_clue_auto_feed]  DROP CONSTRAINT  uidx_claim_clue_auto_feed
END
ELSE
BEGIN
ALTER TABLE [edw_integration].[claim_clue_auto_feed] ADD  CONSTRAINT [uidx_claim_clue_auto_feed] UNIQUE NONCLUSTERED 
(
[ClaimNumber] ASC,
[ClaimType] ASC,
[report_start_date] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END