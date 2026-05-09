-- =================================================================================================
-- Description: This stored procedure insert and update info related to Billing Account Payment.
---------------------------------------------------------------------------------------------------
-- Change date 	|Author					|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/15/25		Yunus Mohammed		    1. Created the proc
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
            --accg.PolicyNumber as grpel_master_policy_no,
			acc.PolicyNumber as grpel_master_policy_no,
            case when accp.Amount >=0 then 'Payment' else 'Refund' end AS transaction_type,
            accp.LineItemCategory as receivable_cd,
            accp.Amount as payment_amt,
            bacc.BillToType as bill_type,
            accp.PaidVia as payment_method,
            accp.PaymentDateTime as payment_dt,
            accp.PaymentFrom as payment_from_type,
            bacc.ReferenceCode,
            null as system_remark,
            accp.ReferenceCode as user_remark,
			accp.Id as payment_id, 
			accp.ReversalOfId as reversal_of_payment_id,
            4 AS source_system_sk,
            getdate() as create_ts,
            getdate() as update_ts,
            @etl_audit_sk as etl_audit_sk,
			accp.CreatedDate,
			accp.UpdatedDate
        INTO edw_temp.tbilling_account_payment_temp1
        FROM 
        edw_stage.Account acc
		inner join edw_stage.[Product] p on acc.ProductId = p.Id and p.InternalName = 'GroupPersonalExcessLiability'
        INNER JOIN edw_stage.BillingAccount bacc on bacc.Id= acc.BillingAccountId
        INNER JOIN edw_stage.AccountPayment accp on accp.AccountId = acc.Id 
        LEFT JOIN edw_core.tbillingaccount ba on ba.billingaccount_no =bacc.ReferenceCode
        where
        GREATEST(accp.CreatedDate,accp.UpdatedDate) > @last_source_extract_ts

		-- Start Merge process
		MERGE edw_core.tbilling_account_payment AS Target
		USING edw_temp.tbilling_account_payment_temp1 Source
		ON Source.payment_id = Target.payment_id
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT 
		(
			billingaccount_no, billingaccount_sk, grpel_master_policy_no, transaction_type, 
			receivable_cd, payment_amt, bill_type, payment_method, payment_dt, payment_from_type,
			system_remark, user_remark, payment_id, reversal_of_payment_id,
			source_system_sk, create_ts,update_ts, etl_audit_sk
		)
		VALUES 
		(
			[Source].billingaccount_no, [Source].billingaccount_sk, [Source].grpel_master_policy_no, [Source].transaction_type, 
			[Source].receivable_cd, [Source].payment_amt, [Source].bill_type, [Source].payment_method, [Source].payment_dt, [Source].payment_from_type,
			[Source].system_remark, [Source].user_remark, [Source].payment_id, [Source].reversal_of_payment_id,
			[Source].source_system_sk, [Source].create_ts, [Source].update_ts, [Source].etl_audit_sk
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET       		
			[Target].reversal_of_payment_id= [Source].reversal_of_payment_id,
			[Target].update_ts = [Source].update_ts;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate, UpdatedDate)) FROM edw_temp.tbilling_account_payment_temp1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tbilling_account_payment_temp1;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;


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