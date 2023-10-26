-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert and update broker data 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23		Mohammed Yunus					1. Created this procedure 
-- 06/29/23		Architha Gudimalla				2. Made changes to fix the errors on first run
-- 08/29/23		Mohammed Yunus					3. Procedure updated for new columns
-- 10/26/23		Mohammed Yunus					4. Procedure updated to fix customer_id error
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker]

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 

		-- Create temp table with name as sp_broker_temp
		DROP TABLE IF EXISTS edw_temp.tbroker_temp1 

		SELECT
			brk.ProducerId as broker_id,
			NULLIF(brk.[Name],'') AS broker_nm,NULLIF(brk.Dba,'') AS dba_nm,
			NULLIF(brk.[status],'') AS broker_status,NULLIF(brk.BrokerageType,'') AS broker_type,
			NULLIF(brk.EntityType,'') AS entity_type,NULLIF(brk.TaxIdNumberType,'') AS tax_id_type,NULLIF(brk.TaxIdNumber,'') AS tax_id,
			NULLIF(brk.AgencyManagementSystem,'') AS agency_management_system_nm,NULLIF(brk.IVANSUserName,'') AS ivans_user_nm,
			NULLIF(brk.IVANSYAccount,'') AS ivans_y_account,
			NULLIF(brk.[LexisNexisCompanyCodeSuffix],'') as lexis_nexis_company_code_suffix,
			CONCAT_WS(' ',br.FirstName,br.LastName) AS primary_contact_nm,
			NULLIF(brk.PrimaryPhoneNumber,'') AS broker_phone_no,
			NULLIF(brk.PrimaryEmail,'') AS broker_email,NULLIF(NewBusinessContactEmail,'') AS newbusiness_contact_email,
			NULLIF(brk.RenewalContactEmail,'') AS renewal_contact_email,
			NULLIF(brk.PolicyChangeContactEmail,'') AS policy_change_contact_email,
			NULLIF(brk.ClaimsContactEmail,'') AS claims_contact_email,
			NULLIF(brk.AddressLine1,'') AS primary_address_line_1,
			NULLIF(brk.AddressLine2,'') AS primary_address_line_2,
			NULLIF(brk.AddressLineUnit,'') AS primary_address_unit_no,
			NULLIF(brk.AddressCity,'') AS primary_address_city_nm,
			NULLIF(brk.AddressState,'') AS primary_address_state_cd,
			NULLIF(brk.AddressZipCode,'') AS primary_address_zip_cd,
			NULLIF(brk.AddressCounty,'') AS primary_address_county_nm,
			NULLIF(brk.AddressCountry,'') AS primary_address_country_nm,
			CASE
				brk.MailingAddressSameAsPrimary
				WHEN 1 THEN 'Yes'
				WHEN 0 THEN 'No'
				ELSE '' END AS mailing_address_same_as_primary_in,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine1,'') ELSE NULLIF(brk.MailingAddressLine1,'') END AS mailing_address_line_1,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine2,'') ELSE NULLIF(brk.MailingAddressLine2,'') END AS mailing_address_line_2,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLineUnit,'') ELSE NULLIF(brk.MailingAddressLineUnit,'') END AS mailing_address_unit_no,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCity,'') ELSE NULLIF(brk.MailingAddressCity,'') END AS mailing_address_city_nm,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressState,'') ELSE NULLIF(brk.MailingAddressState,'') END AS mailing_address_state_cd,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressZipCode,'') ELSE NULLIF(brk.MailingAddressZipCode,'') END AS mailing_address_zip_cd,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCounty,'') ELSE NULLIF(brk.MailingAddressCounty,'') END AS mailing_address_county_nm,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCountry,'') ELSE NULLIF(brk.MailingAddressCountry,'') END AS mailing_address_country_nm,
			CASE
				brk.LocationAddressSameAsPrimary
				WHEN 1 THEN 'Yes'
				WHEN 0 THEN 'No'
				ELSE '' END AS location_address_same_as_primary_in,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine1,'') ELSE NULLIF(brk.LocationAddressLine1,'') END AS location_address_line_1,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine2,'') ELSE NULLIF(brk.LocationAddressLine2,'') END AS location_address_line_2,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLineUnit,'') ELSE NULLIF(brk.LocationAddressLineUnit,'') END AS location_address_unit_no,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCity,'') ELSE NULLIF(brk.LocationAddressCity,'') END AS location_address_city_nm,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressState,'') ELSE NULLIF(brk.LocationAddressState,'') END AS location_address_state_cd,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressZipCode,'') ELSE NULLIF(brk.LocationAddressZipCode,'') END AS location_address_zip_cd,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCounty,'') ELSE NULLIF(brk.LocationAddressCounty,'') END AS location_address_county_nm,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCountry,'') ELSE NULLIF(brk.LocationAddressCounty,'') END AS location_address_country_nm,
			NULLIF(brk.CommissionAddressSameAsPrimary,'') AS commission_address_same_as_primary_in,
			CASE brk.MailingAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine1,'') ELSE NULLIF(brk.CommissionAddressLine1,'') END AS commission_address_line_1,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLine2,'') ELSE NULLIF(brk.CommissionAddressLine2,'') END AS commission_address_line_2,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressLineUnit,'') ELSE NULLIF(brk.CommissionAddressLineUnit,'') END AS commission_address_unit_no,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCity,'') ELSE NULLIF(brk.CommissionAddressCity,'') END AS commission_address_city_nm,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressState,'') ELSE NULLIF(brk.CommissionAddressState,'') END AS commission_address_state_cd,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressZipCode,'') ELSE NULLIF(brk.CommissionAddressZipCode,'') END AS commission_address_zip_cd,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCounty,'') ELSE NULLIF(brk.CommissionAddressCounty,'') END AS commission_address_county_nm,
			CASE brk.LocationAddressSameAsPrimary WHEN 1 THEN NULLIF(brk.AddressCountry,'') ELSE NULLIF(brk.CommissionAddressCounty,'') END AS commission_address_country_nm,
			NULLIF(brk.InsuranceCompanyName,'') AS insurance_company_nm,
			NULLIF(brk.InsurancePolicyNumber,'') AS insurance_policy_no,
			NULLIF(brk.InsurancePolicyLimit,'') as insurance_policy_limit_amt,
			NULLIF(brk.InsurancePolicyEffectiveDate,'') AS insurance_policy_effective_dt,
			NULLIF(brk.InsurancePolicyExpirationDate,'') AS insurance_policy_expiration_dt,
			NULLIF(brkbd.CompanyName,'') AS company_nm,
			NULLIF(brkbd.BankName,'') AS bank_nm,
			NULLIF(brkbd.RoutingNumber,'') AS routing_no,
			NULLIF(brkbd.AccountNumber,'') AS account_no,
			NULLIF(brkbd.TypeOfAccount,'') AS accounting_type,
			NULLIF(brkbd.TokenId,'') AS token_id,
			NULL as commission_statement_email,
			brk.CreatedDate,
			brk.UpdatedDate
		INTO edw_temp.tbroker_temp1
		FROM
			edw_stage.Brokerage brk
			left join [edw_stage].[BrokerageBankingDetail] brkbd on brkbd.BrokerageId=brk.Id
			left join edw_stage.[Broker] br on brk.PrimaryBrokerId=br.Id
		WHERE
				GREATEST(brk.CreatedDate,brk.UpdatedDate)>@last_source_extract_ts

		-- Insert and Update tuser table
		MERGE [edw_core].[tbroker] AS Target
		USING edw_temp.tbroker_temp1 AS Source
		ON CAST(Source.[broker_id] AS VARCHAR(255)) = Target.[broker_id]
		-- For Inserts
		-- location_address_same_as_primary_in 
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				broker_id,broker_nm,dba_nm,broker_status,broker_type,entity_type,tax_id_type,tax_id,
				agency_management_system_nm,ivans_user_nm,ivans_y_account,lexis_nexis_company_code_suffix,primary_contact_nm,broker_phone_no,
				broker_email,newbusiness_contact_email,renewal_contact_email,policy_change_contact_email,claims_contact_email,
				primary_address_line_1,primary_address_line_2,primary_address_unit_no,primary_address_city_nm,primary_address_state_cd,
				primary_address_zip_cd,primary_address_county_nm,primary_address_country_nm,mailing_address_same_as_primary_in,
				mailing_address_line_1,mailing_address_line_2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
				mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,location_address_same_as_primary_in,location_address_line_1,
				location_address_line_2,location_address_unit_no,location_address_city_nm,location_address_state_cd,location_address_zip_cd,
				location_address_county_nm,location_address_country_nm,commission_address_same_as_primary_in,commission_address_line_1,
				commission_address_line_2,commission_address_unit_no,commission_address_city_nm,commission_address_state_cd,
				commission_address_zip_cd,commission_address_county_nm,commission_address_country_nm,insurance_company_nm,insurance_policy_no,
				insurance_policy_limit_amt,insurance_policy_effective_dt,insurance_policy_expiration_dt,company_nm,bank_nm,routing_no,account_no,
				accounting_type,token_id,commission_statement_email,create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
				broker_id,broker_nm,dba_nm,broker_status,broker_type,entity_type,tax_id_type,tax_id,
				agency_management_system_nm,ivans_user_nm,ivans_y_account,lexis_nexis_company_code_suffix,primary_contact_nm,broker_phone_no,
				broker_email,newbusiness_contact_email,renewal_contact_email,policy_change_contact_email,claims_contact_email,
				primary_address_line_1,primary_address_line_2,primary_address_unit_no,primary_address_city_nm,primary_address_state_cd,
				primary_address_zip_cd,primary_address_county_nm,primary_address_country_nm,mailing_address_same_as_primary_in,
				mailing_address_line_1,mailing_address_line_2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
				mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,location_address_same_as_primary_in,location_address_line_1,
				location_address_line_2,location_address_unit_no,location_address_city_nm,location_address_state_cd,location_address_zip_cd,
				location_address_county_nm,location_address_country_nm,commission_address_same_as_primary_in,commission_address_line_1,
				commission_address_line_2,commission_address_unit_no,commission_address_city_nm,commission_address_state_cd,
				commission_address_zip_cd,commission_address_county_nm,commission_address_country_nm,insurance_company_nm,insurance_policy_no,
				insurance_policy_limit_amt,insurance_policy_effective_dt,insurance_policy_expiration_dt,company_nm,bank_nm,routing_no,account_no,
				accounting_type,token_id,commission_statement_email,
				getdate(),getdate(),@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.broker_id = Source.broker_id,
		Target.broker_nm = Source.broker_nm,
		Target.dba_nm = Source.dba_nm,
		Target.broker_status = Source.broker_status,
		Target.broker_type = Source.broker_type,
		Target.entity_type = Source.entity_type,
		Target.tax_id_type = Source.tax_id_type,
		Target.tax_id = Source.tax_id,
		Target.agency_management_system_nm = Source.agency_management_system_nm,
		Target.ivans_user_nm = Source.ivans_user_nm,
		Target.ivans_y_account = Source.ivans_y_account,
		Target.lexis_nexis_company_code_suffix = Source.lexis_nexis_company_code_suffix,
		Target.primary_contact_nm = Source.primary_contact_nm,
		Target.broker_phone_no = Source.broker_phone_no,
		Target.broker_email = Source.broker_email,
		Target.newbusiness_contact_email = Source.newbusiness_contact_email,
		Target.renewal_contact_email = Source.renewal_contact_email,
		Target.policy_change_contact_email = Source.policy_change_contact_email,
		Target.claims_contact_email = Source.claims_contact_email,
		Target.primary_address_line_1 = Source.primary_address_line_1,
		Target.primary_address_line_2 = Source.primary_address_line_2,
		Target.primary_address_unit_no = Source.primary_address_unit_no,
		Target.primary_address_city_nm = Source.primary_address_city_nm,
		Target.primary_address_state_cd = Source.primary_address_state_cd,
		Target.primary_address_zip_cd = Source.primary_address_zip_cd,
		Target.primary_address_county_nm = Source.primary_address_county_nm,
		Target.primary_address_country_nm = Source.primary_address_country_nm,
		Target.mailing_address_same_as_primary_in = Source.mailing_address_same_as_primary_in,
		Target.mailing_address_line_1 = Source.mailing_address_line_1,
		Target.mailing_address_line_2 = Source.mailing_address_line_2,
		Target.mailing_address_unit_no = Source.mailing_address_unit_no,
		Target.mailing_address_city_nm = Source.mailing_address_city_nm,
		Target.mailing_address_state_cd = Source.mailing_address_state_cd,
		Target.mailing_address_zip_cd = Source.mailing_address_zip_cd,
		Target.mailing_address_county_nm = Source.mailing_address_county_nm,
		Target.mailing_address_country_nm = Source.mailing_address_country_nm,
		Target.location_address_same_as_primary_in = Source.location_address_same_as_primary_in,
		Target.location_address_line_1 = Source.location_address_line_1,
		Target.location_address_line_2 = Source.location_address_line_2,
		Target.location_address_unit_no = Source.location_address_unit_no,
		Target.location_address_city_nm = Source.location_address_city_nm,
		Target.location_address_state_cd = Source.location_address_state_cd,
		Target.location_address_zip_cd = Source.location_address_zip_cd,
		Target.location_address_county_nm = Source.location_address_county_nm,
		Target.location_address_country_nm = Source.location_address_country_nm,
		Target.commission_address_same_as_primary_in = Source.commission_address_same_as_primary_in,
		Target.commission_address_line_1 = Source.commission_address_line_1,
		Target.commission_address_line_2 = Source.commission_address_line_2,
		Target.commission_address_unit_no = Source.commission_address_unit_no,
		Target.commission_address_city_nm = Source.commission_address_city_nm,
		Target.commission_address_state_cd = Source.commission_address_state_cd,
		Target.commission_address_zip_cd = Source.commission_address_zip_cd,
		Target.commission_address_county_nm = Source.commission_address_county_nm,
		Target.commission_address_country_nm = Source.commission_address_country_nm,
		Target.insurance_company_nm = Source.insurance_company_nm,
		Target.insurance_policy_no = Source.insurance_policy_no,
		Target.insurance_policy_limit_amt = Source.insurance_policy_limit_amt,
		Target.insurance_policy_effective_dt = Source.insurance_policy_effective_dt,
		Target.insurance_policy_expiration_dt = Source.insurance_policy_expiration_dt,
		Target.company_nm = Source.company_nm,
		Target.bank_nm = Source.bank_nm,
		Target.routing_no = Source.routing_no,
		Target.account_no = Source.account_no,
		Target.accounting_type = Source.accounting_type,
		Target.token_id = Source.token_id,
		Target.commission_statement_email = Source.commission_statement_email,
		Target.[update_ts] = getdate();
		
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(br.CreatedDate,br.UpdatedDate)) FROM edw_temp.tbroker_temp1 br),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

