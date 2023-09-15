-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures update non_renewal_in and billingaccount_sk in tpolicy
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 09/08/23		Architha Gudimalla		1. Created this procedure  
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_update_non_renwal_billing]

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
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		update a
		set non_renewal_in = 'Yes' 
		from edw_core.tpolicy a
		inner join (select policynumber, EffectiveDate, RenewalStatus  from edw_stage.Account  acct  
					where	UpdatedDate > @last_source_extract_ts
					and		RenewalStatus='NonRenewed'
					) b on	a.policy_no = b.policynumber and		a.effective_dt = cast(b.EffectiveDate as date);
					
		SET @rows_affected=@@ROWCOUNT; 
	
		update a
		set billingaccount_sk = b.billingaccount_sk
		from edw_core.tpolicy a
		inner join (select acct.policynumber, acct.EffectiveDate, acct.BillingAccountId , ba.ReferenceCode, tb.billingaccount_sk
					from edw_stage.Account  acct 
					inner join edw_stage.BillingAccount ba on ba.id = acct.BillingAccountId
					inner join edw_core.tbillingaccount tb on tb.billingaccount_no = ba.ReferenceCode
					where	acct.UpdatedDate > @last_source_extract_ts
					) b on	a.policy_no = b.policynumber and		a.effective_dt = cast(b.EffectiveDate as date);  

		SET @rows_affected=@rows_affected+@@ROWCOUNT; 
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UpdatedDate) FROM edw_stage.Account),@last_source_extract_ts); 
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk

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


