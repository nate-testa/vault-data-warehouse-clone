select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp_claim_clue_auto_feed%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_claim_clue_auto_feed');
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_claim_clue_auto_feed');
-- TRUNCATE TABLE [edw_integration].[claim_clue_auto_feed];
SELECT COUNT(1) FROM [edw_integration].[claim_clue_auto_feed];--7320
-- EXEC [edw_core].[sp_claim_clue_auto_feed];
EXEC sp_help '[edw_integration].[claim_clue_auto_feed]';


-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:352 Error Message:String or binary data would be truncated in table 'vault_edw.edw_temp.claim_clue_auto_feed_temp1', column 'PolicyHolderMailAddressZipPlus4'. Truncated value: '0'.
-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:352 Error Message:String or binary data would be truncated in table 'vault_edw.edw_temp.claim_clue_auto_feed_temp1', column 'PolicyHolderMailAddressZipPlus4'. Truncated value: '0'.
-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:352 Error Message:String or binary data would be truncated in table 'vault_edw.edw_temp.claim_clue_auto_feed_temp1', column 'PolicyHolderSSN'. Truncated value: '0'.
-- Error Number:2628 Error State:1 Error Severity:16 Error Procedure:edw_core.sp_claim_clue_auto_feed Error Line:352 Error Message:String or binary data would be truncated in table 'vault_edw.edw_temp.claim_clue_auto_feed_temp1', column 'PolicyHolder2SSN'. Truncated value: '0'.



---------------------------------------------------------------------------------------

SELECT * FROM [edw_integration].[claim_clue_auto_feed] where claimReportingStatus = 'R';

select ClaimDate, * from edw_integration.claim_clue_auto_feed where ClaimNumber = '25ATCT275946277';
select * from edw_core.tclaim where claim_no = '25ATCT275946277';
-- UPDATE edw_core.tclaim SET loss_dt = '2025-07-01' where claim_no = '25ATCT275946277';

EXEC SP_HELP '[edw_temp].[claim_clue_auto_feed_temp1]';
EXEC SP_HELP '[edw_integration].[claim_clue_property_feed]';
EXEC SP_HELP '[edw_integration].[claim_clue_auto_feed]';
-- Unique Key: ClaimNumber, ClaimType, report_start_date

SELECT TOP 10 ClaimDate FROM [edw_integration].[claim_clue_auto_feed];

SELECT report_start_date, report_end_date, COUNT(1) FROM [edw_integration].[claim_clue_auto_feed] GROUP BY report_start_date, report_end_date;

SELECT claim_no, count(1) rc FROM edw_core.tclaim group by claim_no having count(1) > 1;

SELECT claimNumber, max(create_ts) as max_create_ts, COUNT(1) rc
FROM [edw_integration].[claim_clue_auto_feed]
WHERE claimReportingStatus = 'A'
GROUP BY claimNumber
HAVING COUNT(1) > 1
;

SELECT DISTINCT
    ClaimDate,
    contribCompany,
    claimNumber,
    policyNumber,
    policyType,
    '' AS ClaimType,
    '000000000' AS claimAmount,
    'R' AS claimReportingStatus,
    RecordVersionNumber
FROM [edw_integration].[claim_clue_auto_feed] WHERE ClaimNumber = '24ATUN026332889';

-------------------------------------------------------------------------------------

WITH tbl AS (
    SELECT DISTINCT
        PolicyHolderNamePrefix,
        PolicyHolderNameLast,
        PolicyHolderNameFirst,
        PolicyHolderNameMiddle,
        PolicyHolderNameSuffix,
        PolicyHolderMailAddrHseNum,
        PolicyHolderMailAddressStreetName,
        PolicyHolderMailAddressAptNum,
        PolicyHolderMailAddressCity,
        PolicyHolderMailAddressState,
        PolicyHolderMailAddressZip,
        PolicyHolderMailAddressZipPlus4,
        Filler_reservedForFutureUse1,
        PolicyHolderSSN,
        PolicyHolderDOB,
        PolicyHolderDriversLicenseNum,
        PolicyHolderDriversLicenseState,
        PolicyHolderSex,
        Filler_reservedForFutureUse2,
        PolicyHolder2NamePrefix,
        PolicyHolder2NameLast,
        PolicyHolder2NameFirst,
        PolicyHolder2NameMiddle,
        PolicyHolder2NameSuffix,
        PolicyHolder2SSN,
        PolicyHolder2DOB,
        PolicyHolder2DriversLicenseNum,
        PolicyHolder2DriversLicenseState,
        PolicyHolder2Sex,
        Filler_reservedForFutureUse3,
        VehicleOperatorNamePrefix,
        VehicleOperatorNameLast,
        VehicleOperatorNameFirst,
        VehicleOperatorNameMiddle,
        VehicleOperatorNameSuffix,
        VehicleOperatorAddrHseNum,
        VehicleOperatorAddrStreetName,
        VehicleOperatorAddrAptNum,
        VehicleOperatorAddrCity,
        VehicleOperatorAddrState,
        VehicleOperatorAddrZipCode,
        VehicleOperatorAddrZipPlus4,
        Filler_reservedForFutureUse4,
        VehicleOperatorSSN,
        VehicleOperatorDOB,
        VehicleOperatorDriversLicenseNum,
        VehicleOperatorDriversLicenseState,
        VehicleOperatorSex,
        VehicleOperatorRelationship,
        Filler_reservedForFutureUse5,
        contribCompany,
        PolicyNumber,
        PolicyType,
        Filler_reservedForFutureUse6,
        ClaimNumber,
        ' ' AS ClaimType,
        ClaimDate,
        '000000000' AS claimAmount,
        'R' AS claimReportingStatus,
        InsuredVehicleVIN,
        InsuredVehicleModelYear,
        InsuredVehicleMakeModel,
        InsuredVehicleDisposition,
        '' AS ClaimDisposition,
        FaultIndicator,
        DateofFirstPayment,
        CAIndicator1,
        CAIndicator2,
        CAIndicator3,
        CAIndicator4,
        Filler_reservedForFutureUse7,
        RecordVersionNumber,
        NULL AS transaction_ts
    FROM [edw_integration].[claim_clue_auto_feed]
)
-- SELECT COUNT(1) FROM tbl
SELECT ClaimNumber, COUNT(1) FROM tbl GROUP BY ClaimNumber HAVING COUNT(1) > 1
-- SELECT * FROM tbl WHERE ClaimNumber = 'C23AUA00897'
;