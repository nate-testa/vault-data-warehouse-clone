-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures inserts and updates Customer data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 06/29/23		Architha Gudimalla				2. Made changes to fix the errors on first run
-- 07/09/23		Mohammed Yunus					3. Mailing address column names updated
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcustomer]

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

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.[tcustomer_temp1]
        SELECT 	ins.referencecode,
				NULLIF(TRIM(ins.NamedInsured),'') NamedInsured, 
				NULLIF(TRIM(ins.FirstName),'') FirstName, 
				NULLIF(TRIM(ins.MiddleName),'') MiddleName, 
				NULLIF(TRIM(ins.LastName),'') LastName, 
				NULLIF(TRIM(ins.InsuredType),'') InsuredType, 
				NULLIF(TRIM(ins.MobilePhone),'') Phone, 
				ins.BirthDate, 
				NULLIF(TRIM(ins.Occupation),'') Occupation,
				NULLIF(TRIM(ins.Prefix),'') Prefix,
				NULLIF(TRIM(ins.Title),'') Title, 
				NULLIF(TRIM(ins.Email),'') Email,  
				NULLIF(TRIM(ins.MailingAddressLine1),'') MailingAddressLine1, 
				NULLIF(TRIM(ins.MailingAddressLine2),'') MailingAddressLine2, 
				NULLIF(TRIM(ins.MailingAddressLineUnit),'') MailingAddressLineUnit, 
				NULLIF(TRIM(ins.MailingAddressCity),'') MailingAddressCity, 
				NULLIF(TRIM(ins.MailingAddressState),'') MailingAddressState, 
				NULLIF(TRIM(ins.MailingAddressZipCode),'') MailingAddressZipCode,
				NULLIF(TRIM(ins.MailingAddressCounty),'') MailingAddressCounty,
				NULLIF(TRIM(ins.MailingAddressCountry),'') MailingAddressCountry,
				ins.IsVip, CreatedDate, UpdatedDate
        INTO edw_temp.[tcustomer_temp1] 
		FROM edw_stage.[Insured] ins
		WHERE GREATEST(CreatedDate,UpdatedDate)>@last_source_extract_ts

		-- Start Merge process
		MERGE [edw_core].[tcustomer] AS Target
		USING edw_temp.[tcustomer_temp1] AS Source
		ON Source.referencecode = Target.[customer_id]
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				[customer_id], [customer_nm], [first_nm], [middle_nm], [last_nm], [Insured_type], 
				[home_phone_no], [mobile_phone_no], [birth_dt], [occupation_desc], [employer_nm], [prefix], [suffix], [title], [email], [agency_id],
				[mailing_address_line1],[mailing_address_line2],[mailing_address_unit_no],[mailing_address_city_nm],
				[mailing_address_state_cd],[mailing_address_zip_cd],[mailing_address_county_nm],[mailing_address_country_nm],
				[family_account_in], [vip_in], 
				[create_ts], [update_ts], [etl_audit_sk]
			)
		VALUES (--cast(Source.referencecode as varchar), 
				Source.referencecode,
				Source.NamedInsured, 
				Source.FirstName, 
				Source.MiddleName, 
				Source.LastName, 
				Source.InsuredType, 
				Source.Phone, 
				Source.Phone, 
				Source.BirthDate, 
				Source.Occupation,
				NULL,Source.Prefix, null,
				Source.Title, 
				Source.Email, null, 
				Source.MailingAddressLine1, 
				Source.MailingAddressLine2, 
				Source.MailingAddressLineUnit,
				Source.MailingAddressCity, 
				Source.MailingAddressState, 
				Source.MailingAddressZipCode, 
				Source.MailingAddressCounty,
				Source.MailingAddressCountry, null, 
				Source.IsVip, getdate(), getdate(), @etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
	    Target.[customer_nm]	= Source.NamedInsured,
        Target.[first_nm]	= Source.FirstName,
        Target.[middle_nm]	= Source.MiddleName,
		Target.[last_nm]	= Source.LastName,
		Target.[Insured_type]	= Source.InsuredType,
		Target.[home_phone_no]	= Source.Phone,
		Target.[mobile_phone_no]	= Source.Phone,
		Target.[birth_dt]	= Source.BirthDate,
		Target.[occupation_desc]	= Source.Occupation,
		Target.[prefix]	= Source.Prefix,
		Target.Title	= Source.Title,
		Target.[email]	= Source.Email,
		Target.[mailing_address_line1]	= Source.MailingAddressLine1,
		Target.[mailing_address_line2]	= Source.MailingAddressLine2,
		Target.[mailing_address_unit_no]	= Source.MailingAddressLineUnit,
		Target.[mailing_address_city_nm]	= Source.MailingAddressCity,
		Target.[mailing_address_state_cd]	= Source.MailingAddressState,
		Target.[mailing_address_zip_cd]	= Source.MailingAddressZipCode,
		Target.[mailing_address_county_nm] = Source.MailingAddressCounty,
		Target.[mailing_address_country_nm]	= Source.MailingAddressCountry,
		Target.[vip_in]	= Source.IsVip,
		--[employer_nm],  [suffix],  [agency_id], [unit_no], [family_account_in]
		Target.[update_ts] = getdate()
		;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.CreatedDate,t1.UpdatedDate)) FROM edw_temp.[tcustomer_temp1] t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.[tcustomer_temp1]
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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

