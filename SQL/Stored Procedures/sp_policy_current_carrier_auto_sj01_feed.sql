-- ================================================================================================= 
-- Author:		Yunus Mohammed
-- Description: This procedures inserts the sj01 data for carrier feed
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						        |	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/11/25					Yunud Mohammed			1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_current_carrier_auto_sj01_feed]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
    		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
		DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_sj01_feed_temp1;
		
        select
            'SJO1' as [RecordCode],
            np.[ContribCompanyAMBestNumber],
            np.PolicyNumber,
            np.InsuranceType,
			case
				when cast(@last_source_extract_ts as date) = '1900-01-01' then FORMAT(getdate(),'yyyyMMdd')
				else format(tad.transaction_effective_dt,'yyyyMMdd')
			end as ChangeEffectiveDate,
			--TODO: check else part
            case
                when tad.relationship_to_insured = 'Self' and driver_status = 'Active' then 'A1'
                else 'H1'
            end as [RelationshipToPolicyHolder],
            SUBSTRING(tad.last_nm ,1,28)as [NameLast],
            SUBSTRING(tad.first_nm,1,20) as [NameFirst],
            SUBSTRING(tad.middle_nm,1,15) as [NameMiddle],
            SUBSTRING(tad.suffix,1,3) as [NameSuffix],
            format(tad.birth_dt,'yyyyMMdd') as [DOB],
            '' as [SSN],
            '' as [Gender],
            '' as [DLNumber],
            '' as [DLState],
            '' as [InternalQouteback],
            '' as [Reserved1],
            '' as [SpecialProjectsIdentifier],
            '' as [SequenceNumber],
            '' as [ClientIdentifier],
            '' as [EmailAddress],
            case
				when tp.insured_type = 'Individual' then 'I'
				when tp.insured_type = 'Entity' then 'C'
			end as [IndividualOrBusinessType],
			case
				when tp.insured_type = 'Entity' then insured_nm
				else ''
			end as [BusinessOrTrustName],
            null as [FEINNumber],
            case when tp.insured_type = 'Entity' then 'OT' else '' end as [BusinessOrTrustNameAddressType],
            case when tp.insured_type = 'Entity' then 			
				SUBSTRING(tp.mailing_address_line1, 1, PATINDEX('%[^0-9]%', tp.mailing_address_line1 + 'x') - 1)
			else ''
			end as [BusinessOrTrustNameMailingAddressStreetNumber],
            case when tp.insured_type = 'Entity' then
				LEFT(TRIM(SUBSTRING(tp.mailing_address_line1, PATINDEX('%[^0-9]%', tp.mailing_address_line1), 30)), 20) 
			else
				''
			end as [BusinessOrTrustNameMailingAddressStreetName],
            case when tp.insured_type = 'Entity' then LEFT(tp.mailing_address_unit_no, 5) else '' end as [BusinessOrTrustNameMailingAddressSuiteNumber],
            case when tp.insured_type = 'Entity' then LEFT(mailing_address_city_nm,20) else '' end as [BusinessOrTrustNameMailingAddressCity],
            case when tp.insured_type = 'Entity' then LEFT(mailing_address_state_cd,2) else '' end as [BusinessOrTrustNameMailingAddressState],
            case when tp.insured_type = 'Entity' then LEFT(tp.mailing_address_zip_cd,5) else '' end as [BusinessOrTrustNameMailingAddressZipCode],
            null as [BusinessOrTrustNameMailingAddressZipCodePlus4],
            null as [BusinessOrTrustNamePhoneAreaCode],
            null as [BusinessOrTrustNamePhoneNumber],
            null as [BusinessOrTrustNamePhoneNumberExtension],
            case
				when tad.marital_status='Single' then '1'
				when tad.marital_status='Married' then '2'
				when tad.marital_status='Divorced' then '3'
				when tad.marital_status='Widowed' then '4'
				when tad.marital_status='Estranged' then '3'
			end as [MaritalStatus],
            '' as Filler1,
            np.policy_sk,
            np.policy_no ,
            np.policy_history_sk,
            tad.auto_driver_sk,
            tad.driver_no,
            tph.transaction_seq_no,
            tph.transaction_ts,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk
		into edw_temp.policy_current_carrier_auto_sj01_feed_temp1
        from
            edw_temp.policy_current_carrier_auto_np01_feed np
            inner join edw_core.tauto_driver tad on np.policy_history_sk = tad.policy_history_sk
            inner join edw_core.tpolicy tp on tp.policy_sk = np.policy_sk
            inner join edw_core.tpolicy_history tph on tp.policy_sk = tph.policy_sk and tph.policy_history_sk = tad.policy_history_sk
        where
          cast(np.create_ts as date) >@last_source_extract_ts
		  and tad.driver_deleted_in = 'No'
		-- Start Insert process
		INSERT INTO edw_integration.policy_current_carrier_auto_sj01_feed
        (
           RecordCode,ContribCompanyAMBestNumber,PolicyNumber,InsuranceType,ChangeEffectiveDate,RelationshipToPolicyHolder,
            NameLast,NameFirst,NameMiddle,NameSuffix,DOB,SSN,Gender,DLNumber,DLState,InternalQouteback,Reserved1,SpecialProjectsIdentifier,
            SequenceNumber,ClientIdentifier,EmailAddress,IndividualOrBusinessType,BusinessOrTrustName,FEINNumber,BusinessOrTrustNameAddressType,
            BusinessOrTrustNameMailingAddressStreetNumber,BusinessOrTrustNameMailingAddressStreetName,
            BusinessOrTrustNameMailingAddressSuiteNumber,BusinessOrTrustNameMailingAddressCity,
            BusinessOrTrustNameMailingAddressState,BusinessOrTrustNameMailingAddressZipCode,BusinessOrTrustNameMailingAddressZipCodePlus4,
            BusinessOrTrustNamePhoneAreaCode,BusinessOrTrustNamePhoneNumber,BusinessOrTrustNamePhoneNumberExtension,
            MaritalStatus,Filler1,policy_sk,policy_no,policy_history_sk,auto_driver_sk,driver_no,transaction_seq_no,transaction_ts,
            create_ts,update_ts,etl_audit_sk
        )

		SELECT
				RecordCode,
				ContribCompanyAMBestNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(PolicyNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(InsuranceType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InsuranceType,
				RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(ChangeEffectiveDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as ChangeEffectiveDate,
				REPLACE(REPLACE(REPLACE(ISNULL(RelationshipToPolicyHolder,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RelationshipToPolicyHolder,
				REPLACE(REPLACE(REPLACE(ISNULL(NameLast,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as NameLast,
				REPLACE(REPLACE(REPLACE(ISNULL(NameFirst,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as NameFirst,
				REPLACE(REPLACE(REPLACE(ISNULL(NameMiddle,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as NameMiddle,
				REPLACE(REPLACE(REPLACE(ISNULL(NameSuffix,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')as NameSuffix,
				RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(DOB,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as DOB,
				RIGHT('000000000'+ REPLACE(REPLACE(REPLACE(ISNULL(SSN,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),9) as SSN,
				REPLACE(REPLACE(REPLACE(ISNULL(Gender,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Gender,
				REPLACE(REPLACE(REPLACE(ISNULL(DLNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as DLNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(DLState,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as DLState,
				REPLACE(REPLACE(REPLACE(ISNULL(InternalQouteback,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InternalQouteback,
				REPLACE(REPLACE(REPLACE(ISNULL(Reserved1,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved1,
				REPLACE(REPLACE(REPLACE(ISNULL(SpecialProjectsIdentifier,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as SpecialProjectsIdentifier,
				REPLACE(REPLACE(REPLACE(ISNULL(SequenceNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as SequenceNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(ClientIdentifier,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as ClientIdentifier,
				REPLACE(REPLACE(REPLACE(ISNULL(EmailAddress,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as EmailAddress,
				REPLACE(REPLACE(REPLACE(ISNULL(IndividualOrBusinessType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as IndividualOrBusinessType,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustName,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustName,
				RIGHT('000000000'+ REPLACE(REPLACE(REPLACE(ISNULL(FEINNumber,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),9) as FEINNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameAddressType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameAddressType,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressStreetNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameMailingAddressStreetNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressStreetName,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameMailingAddressStreetName,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressSuiteNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameMailingAddressSuiteNumber,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressCity,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameMailingAddressCity,
				REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressState,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessOrTrustNameMailingAddressState,
				RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressZipCode,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as BusinessOrTrustNameMailingAddressZipCode,
				RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNameMailingAddressZipCodePlus4,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as BusinessOrTrustNameMailingAddressZipCodePlus4,
				RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNamePhoneAreaCode,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as BusinessOrTrustNamePhoneAreaCode,
				RIGHT('0000000'+ REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNamePhoneNumber,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),7) as BusinessOrTrustNamePhoneNumber,
				RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(BusinessOrTrustNamePhoneNumberExtension,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as BusinessOrTrustNamePhoneNumberExtension,
				RIGHT('0'+ REPLACE(REPLACE(REPLACE(ISNULL(MaritalStatus,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),1) as MaritalStatus,
				REPLACE(REPLACE(REPLACE(ISNULL(Filler1,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Filler1,
				policy_sk,policy_no,policy_history_sk,auto_driver_sk,driver_no,transaction_seq_no,transaction_ts,
				create_ts,update_ts,etl_audit_sk
		FROM 
			edw_temp.policy_current_carrier_auto_sj01_feed_temp1

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE(dateadd("dd",-1, cast(getdate() as date)),@last_source_extract_ts);
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) 
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_sj01_feed_temp1;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END