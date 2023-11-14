-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 10/19/2023
-- Description: This procedures insert OneShied Customer into tcustomer table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_customer]

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

		DROP TABLE IF EXISTS edw_temp.os_tcustomer_temp1
		SELECT customer_id,customer_name as customer_nm,
		CASE
			WHEN LEN(customer_name) - LEN(REPLACE(customer_name, ' ', ''))>1 THEN PARSENAME(REPLACE(customer_name, ' ', '.'), 3)
			ELSE PARSENAME(REPLACE(customer_name, ' ', '.'), 2)
		END as first_nm,
		CASE
			WHEN LEN(customer_name) - LEN(REPLACE(customer_name, ' ', ''))>1 THEN  PARSENAME(REPLACE(customer_name, ' ', '.'), 2)
			ELSE NULL
		END as middle_nm,
		PARSENAME(REPLACE(customer_name, ' ', '.'), 1) as last_nm,
		null as insured_type,customer_contact_phone as home_phone_no,null as mobile_phone_no,
		customer_date_of_birth as birth_dt,null as occupation_desc,null as employer_nm,null as prefix,null as suffix,null as title,
		customer_email_address as email,null AS agency_id,customer_address_line1 as mailing_address_line1, null as mailing_address_line2,
		null as mailing_address_unit_no,customer_address_city as mailing_address_city_nm,customer_jurisdiction as mailing_address_state_cd,
		customer_zip_postal_cd as mailing_address_zip_cd,
		null as mailing_address_county_nm,customer_address_city as mailing_address_country_nm,null as family_account_in,null as vip_in
		INTO edw_temp.os_tcustomer_temp1
		FROM edw_stage.dragon_customer

		INSERT INTO edw_core.tcustomer
		(
		customer_id,customer_nm,first_nm,middle_nm,last_nm,insured_type,home_phone_no,mobile_phone_no,birth_dt,
		occupation_desc,employer_nm,prefix,suffix,title,email,agency_id,mailing_address_line1,
		mailing_address_line2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
		mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,family_account_in,vip_in,
		create_ts,update_ts,etl_audit_sk
		)
		SELECT
			customer_id,customer_nm,first_nm,middle_nm,last_nm,insured_type,home_phone_no,mobile_phone_no,birth_dt,
		occupation_desc,employer_nm,prefix,suffix,title,email,agency_id,mailing_address_line1,
		mailing_address_line2,mailing_address_unit_no,mailing_address_city_nm,mailing_address_state_cd,
		mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,family_account_in,vip_in,
		GETDATE() AS create_ts,GETDATE() update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tcustomer_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts= '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tcustomer_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;

	END CATCH
END