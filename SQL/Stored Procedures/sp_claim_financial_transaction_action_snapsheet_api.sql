-- =================================================================================================
-- Description: This procedures update claim financial payment status
---------------------------------------------------------------------------------------------------
-- Change date 				|Author										|	Change Description
---------------------------------------------------------------------------------------------------
--	01-22-2025				Yunus Mohammed				 Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_financial_transaction_action_snapsheet_api]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));	

		DROP TABLE IF EXISTS edw_temp.claim_financial_transaction_action_snapsheet_api_temp1;

		SELECT 
		settle_payee_id,
		json_query((
			SELECT
			[data.type],
			[data.attributes.code],
			[data.attributes.originated_at],
			[data.relationships.financial_transaction.data.id],
			[data.relationships.financial_transaction.data.type]
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER

		)) as [data],
		create_ts
		into edw_temp.claim_financial_transaction_action_snapsheet_api_temp1
		from
		(
		select
			fin.id as settle_payee_id,
			'financial_transaction_action' as [data.type],
			case 
			when pay.pm_status = 'In Progress' then 'submittted'
			when pay.pm_status = 'Issued' then 'issued'
			when  pay.pm_status = 'Cancelled' then 'cancel'
			when pay.pm_status in ('Stopped','Stop Pending') then 'stop'
			when pay.pm_status = 'Error' then 'failed'
			when pay.pm_status = 'Success' then 'cleared'			
			else pay.pm_status
			end as [data.attributes.code],
			pay.pm_paid_date as [data.attributes.originated_at],
			cast(fin.id as varchar(255)) as [data.relationships.financial_transaction.data.id],
			'financial_transaction' as [data.relationships.financial_transaction.data.type],
			create_ts
		from
			edw_stage.migration_create_financial_transaction_api fin
			inner join edw_stage.int_claims_payments_audit pay on fin.remote_identifier = cast( replace(pm_cr_payment_id,'PMM','' ) as decimal(15,0))
		where
			api_status = 'Success'
			and amount_type = 'Payment_Amount'
			and fin.create_ts > @last_source_extract_ts	
		) as temp

		insert into edw_integration.claim_financial_transaction_action_snapsheet_api
		(
			settle_payee_id,[data],create_ts,api_status,etl_audit_sk
		)
		select settle_payee_id,[data],getdate() as create_ts,'pending' as api_status,@etl_audit_sk
		from
		edw_temp.claim_financial_transaction_action_snapsheet_api_temp1
		
		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.create_ts) FROM edw_temp.claim_financial_transaction_action_snapsheet_api_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.claim_financial_transaction_action_snapsheet_api_temp1;
	
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
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;

	END CATCH
END