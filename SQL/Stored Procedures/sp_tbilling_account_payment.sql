-- =================================================================================================
-- Description: This stored procedure insert and update info related to Billing Account.
---------------------------------------------------------------------------------------------------
-- Change date |Author					|	Change Description
---------------------------------------------------------------------------------------------------
-- 08/18/23		Yunus Mohammed		    1. Create the proc
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tbilling_account_payment]
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

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tbilling_account_payment_temp1;
        SELECT
            ba.billingaccount_no,
            ba.billingaccount_sk,
            accg.PolicyNumber as grpel_master_policy_no,
            'Payment' AS transaction_type,
            accp.LineItemCategory as receivable_cd,
            accp.Amount as payment_amt,
            bacc.BillToType as bill_type,
            accp.PaidVia as payment_method,
            accp.PaymentDateTime as payment_dt,
            accp.PaymentFrom as payment_from_type,
            bacc.ReferenceCode,
            null as system_remark,
            accp.ReferenceCode as user_remark,
            4 AS source_system_sk,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk
        INTO edw_temp.tbilling_account_payment_temp1
        FROM 
        edw_stage.Account acc
        LEFT JOIN edw_stage.Account accg on acc.GroupAccountId = accg.Id
        INNER JOIN edw_stage.AccountInvoice accinv on acc.Id= accinv.AccountId
        INNER JOIN edw_stage.BillingAccount bacc on bacc.Id= acc.BillingAccountId
        INNER JOIN edw_stage.AccountPayment accp on accp.AccountId = acc.Id 
        LEFT JOIN edw_core.tbillingaccount ba on ba.billingaccount_no =bacc.ReferenceCode
        where
        GREATEST(accp.CreatedDate,accp.UpdatedDate) > @last_source_extract_ts

		-- Start Merge process
		MERGE edw_core.tbilling_account_payment AS Target
		USING edw_temp.tbilling_account_payment_temp1 Source
		ON Source.BillingAccountId = Target.billingaccount_no
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
                billingaccount_no, billingaccount_sk, grpel_master_policy_no, transaction_type, 
                receivable_cd, payment_amt, bill_type, payment_method, payment_dt, payment_from_type,
                system_remark, user_remark, source_system_sk,
                create_ts,update_ts, etl_audit_sk
			)
		VALUES (Source.BillingAccountId, Source.EffectiveDate, Source.ExpirationDate, Source.TransactionEffectiveDate, Source.BillToType, Source.PaymentPlan
		,Source.PaymentMethod, Source.Payor, Source.ContactPrefix, Source.ContactFirstName, Source.ContactMiddleName, Source.ContactLastName, Source.ContactSuffix
		, Source.ContactPhone, Source.birth_dt, Source.ContactEmail, Source.AddressLine1, Source.AddressLine2, Source.mailing_address_unit_no, Source.AddressCity, Source.AddressState
		, Source.AddressZipCode, Source.AddressCounty, Source.AddressCountry, Source.source_system_sk, Source.create_ts, Source.update_ts, @etl_audit_sk, IsAutoPay
		--, AutoPayMethod
		, AutoPayToken, customer_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.effective_dt = Source.EffectiveDate,
		Target.expiration_dt = Source.ExpirationDate,
		Target.transaction_dt = Source.TransactionEffectiveDate,
		Target.bill_type = Source.BillToType,
		Target.payment_plan = Source.PaymentPlan,
		Target.payment_method = Source.PaymentPlan,
		Target.payor_nm = Source.Payor,
		Target.prefix = Source.ContactPrefix,
		Target.first_nm = Source.ContactFirstName,
		Target.middle_nm = Source.ContactMiddleName,
		Target.last_nm = Source.ContactLastName,
		Target.suffix = Source.ContactSuffix,
		Target.phone_no = Source.ContactPhone,
		Target.email = Source.ContactEmail,
		Target.mailing_address_line_1 = Source.AddressLine1,
		Target.mailing_address_line_2 = Source.AddressLine2,
		Target.mailing_address_unit_no = Source.mailing_address_unit_no,
		Target.mailing_city_nm = Source.AddressCity,
		Target.mailing_state_cd = Source.AddressState,
		Target.mailing_zip_cd = Source.AddressZipCode,
		Target.mailing_county_nm = Source.AddressCounty,
		Target.mailing_country_nm = Source.AddressCountry,
		Target.update_ts = Source.update_ts,
		Target.etl_audit_sk = @etl_audit_sk,
		Target.auto_pay_in = Source.IsAutoPay,
		--Target.auto_pay_method = Source.AutoPayMethod,
		Target.auto_pay_token = Source.AutoPayToken,
		Target.customer_sk = Source.customer_sk;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate, UpdatedDate)) FROM edw_stage.BillingAccount),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tbillingaccount_temp1;
		
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
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END
GO