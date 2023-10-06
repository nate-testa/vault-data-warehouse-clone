SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-10-05
-- Description: This stored procedure insert and update info related to Billing Account for Integration.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_billing_account_customer_portal_api]
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
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		MERGE [edw_integration].[billing_account_customer_portal_api] as TARGET
		USING (SELECT
		[billingaccount_no]
	    ,[first_nm]
        ,[last_nm]
        ,[mailing_address_line_1]
        ,[mailing_address_line_2]
        ,[mailing_city_nm]
        ,[mailing_state_cd]
        ,[mailing_zip_cd]
        ,[email]
        ,[auto_pay_in]
        ,[birth_dt]
        ,[effective_dt]
        ,[expiration_dt]
        ,[payor_nm]
        ,[phone_no]
        ,[create_ts]
        ,[update_ts]
        ,[etl_audit_sk]
		FROM [edw_core].[tbillingaccount]
		WHERE
			GREATEST([update_ts])>@last_source_extract_ts --20230717 added
		) as SOURCE
		ON Source.billingaccount_no = Target.billingaccount_no
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			[billingaccount_no]
			,[first_nm]
			,[last_nm]
			,[mailing_address_line_1]
			,[mailing_address_line_2]
			,[mailing_city_nm]
			,[mailing_state_cd]
			,[mailing_zip_cd]
			,[email]
			,[auto_pay_in]
			,[birth_dt]
			,[effective_dt]
			,[expiration_dt]
			,[payor_nm]
			,[phone_no]
			,[create_ts]
			,[update_ts]
			,[etl_audit_sk]
			)
		VALUES (Source.[billingaccount_no],Source.[first_nm],Source.[last_nm],Source.[mailing_address_line_1],Source.[mailing_address_line_2],Source.[mailing_city_nm],Source.[mailing_state_cd],Source.[mailing_zip_cd],Source.[email],Source.[auto_pay_in],Source.[birth_dt],Source.[effective_dt],Source.[expiration_dt],Source.[payor_nm],Source.[phone_no],Source.[create_ts],Source.[update_ts],Source.[etl_audit_sk])
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.[first_nm] = Source.[first_nm],
		Target.[last_nm] = Source.[last_nm],
		Target.[mailing_address_line_1] = Source.[mailing_address_line_1],
		Target.[mailing_address_line_2] = Source.[mailing_address_line_2],
		Target.[mailing_city_nm] = Source.[mailing_city_nm],
		Target.[mailing_state_cd] = Source.[mailing_state_cd],
		Target.[mailing_zip_cd] = Source.[mailing_zip_cd],
		Target.[email] = Source.[email],
		Target.[auto_pay_in] = Source.[auto_pay_in],
		Target.[birth_dt] = Source.[birth_dt],
        Target.[effective_dt] = Source.[effective_dt],
		Target.[expiration_dt] = Source.[expiration_dt],
		Target.[payor_nm] = Source.[payor_nm],
		Target.[phone_no] = Source.[phone_no],
		Target.[update_ts] = Source.[update_ts],
		Target.[etl_audit_sk] = Source.[etl_audit_sk];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX([update_ts]) FROM [edw_core].[tbillingaccount] t1),@last_source_extract_ts);
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added


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
GO