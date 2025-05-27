-- =================================================================================================
-- Author:		Yunus Mohammed 
-- Description: This procedure reconciles snapsheet data 
---------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 03/19/25         Yunus Mohammed				1. Created this procedure
-- 03/27/25         Sandeep Gundreddy			2. Fixed logic
-- 03/28/25         Sandeep Gundreddy			3. Fixed date filter in EDW query
-- 05/26/25		    Yunus Mohammed		  		4. AD-9616 Excluded Commercial Lines claims
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_treconciliation_snapsheet]
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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));

		declare @max_transaction_ts datetime2(6)

        select @max_transaction_ts = max(transaction_ts) from edw_core.tclaim_transaction

		IF (CAST(@last_source_extract_ts AS DATE) = CAST('1900-01-01' AS DATE))
		BEGIN
			SELECT @last_source_extract_ts='2025-02-10'
		END
		-- Create temp table
		DROP TABLE IF EXISTS edw_temp.treconciliation_snapsheet_temp1

        SELECT 
        [source].transaction_ts AS transaction_start_dt,[source].transaction_ts AS transaction_end_dt,
        NULL AS source_record_ct,[source].loss AS source_amt,NULL AS target_record_ct,[target].loss AS target_amt,
        'Claim' AS datamart_nm,CASE WHEN [source].loss = [target].loss THEN 'SUCCESS' ELSE 'FAILURE' END AS status_desc,
        'Snapsheet' AS source_system_nm
        into edw_temp.treconciliation_snapsheet_temp1
        FROM
        (
        select a.transaction_ts,sum(a.loss) as loss from 
		(
        SELECT
        cast(fta.created_at as date) as transaction_ts,
        sum(
        case  
                when ft.financial_transaction_type='indemnity' and fta.code='submitted' then pay.amount 
                when ft.financial_transaction_type='indemnity' and fta.code in ('stop','cancel','failed') then pay.amount * -1
            else 0
        end	
        ) as loss	
        FROM
        edw_stage_snapsheet.financial_payment_items pay
        INNER JOIN edw_stage_snapsheet.financial_transactions ft on pay.financial_transaction_id = ft.id
        INNER JOIN edw_stage_snapsheet.financial_transaction_actions fta on fta.financial_transaction_id = pay.financial_transaction_id
        where
        fta.code in ('submitted','cancel','stop','failed') and ft.approved_at is not null and ft.is_historical='false'
            AND cast(fta.created_at as date)  BETWEEN @last_source_extract_ts AND @max_transaction_ts
            and not exists
			(
				select 1
				from
					edw_stage_snapsheet.tags ctg
				where
					ctg.claim_id = pay.claim_id
				and ctg.[name] in 
				(
					'Commercial XS-LPL','Commercial MPL','Commercial PRF','TPA Assigned','Commercial - Primary','Commercial - First Excess'
				)
			)
        group by cast(fta.created_at as date)
		union
		 SELECT
        cast(fta.created_at as date) as transaction_ts,
        sum(
        case  
                when ft.financial_transaction_type='indemnity' and fta.code='submitted' then pay.amount 
                when ft.financial_transaction_type='indemnity' and fta.code in ('stop','cancel','failed') then pay.amount * -1
            else 0
        end	
        ) as loss	
        FROM
        edw_stage_snapsheet.financial_payment_items pay
        INNER JOIN edw_stage_snapsheet.financial_transactions ft on pay.financial_transaction_id = ft.id
        INNER JOIN edw_stage_snapsheet.financial_transaction_actions fta on fta.financial_transaction_id = pay.financial_transaction_id
        where
        fta.code in ('submitted','cancel','stop','failed') and ft.is_historical='true'
            AND cast(fta.created_at as date)  BETWEEN @last_source_extract_ts AND @max_transaction_ts
            and not exists
			(
				select 1
				from
					edw_stage_snapsheet.tags ctg
				where
					ctg.claim_id = pay.claim_id
				and ctg.[name] in 
				(
					'Commercial XS-LPL','Commercial MPL','Commercial PRF','TPA Assigned','Commercial - Primary','Commercial - First Excess'
				)
			)
        group by cast(fta.created_at as date)
		)a  
		group by a.transaction_ts
        ) as [source]
        LEFT JOIN
        (
        SELECT
        CAST(transaction_ts AS DATE) AS transaction_ts,
        SUM(
            loss_paid_amt + expense_paid_amt + defense_paid_amt /*+	
            subrogation_recovery_amt+salvage_recovery_amt+ salvage_expense_recovery_amt+ subrogation_expense_recovery_amt+deductible_recovery_amt+
            reinsurance_recovery_amt+overpayment_recovery_amt+deductible_expense_recovery_amt+
            reinsurance_expense_recovery_amt+overpayment_expense_recovery_amt+subrogation_defense_recovery_amt+
            salvage_defense_recovery_amt+deductible_defense_recovery_amt+
            reinsurance_defense_recovery_amt+overpayment_defense_recovery_amt*/
        ) AS loss
        FROM edw_core.tclaim_transaction
        WHERE CAST(transaction_ts AS DATE) >= @last_source_extract_ts AND source_system_sk=5
        GROUP BY CAST(transaction_ts AS DATE)
        ) AS target ON [source].transaction_ts=[target].transaction_ts

		-- Insert and Update treconciliation table
		MERGE [edw_core].[treconciliation] AS Target
		USING edw_temp.treconciliation_snapsheet_temp1 AS Source
		ON Target.transaction_start_dt = Source.transaction_start_dt
	    AND Target.transaction_end_dt = Source.transaction_end_dt
		AND Target.datamart_nm = Source.datamart_nm
		AND Target.source_system_nm= Source.source_system_nm
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
            transaction_start_dt,transaction_end_dt,source_record_ct,source_amt,
            target_record_ct,target_amt,datamart_nm,status_desc,source_system_nm,
            create_ts,update_ts
			)
		VALUES
			(				
				transaction_start_dt,transaction_end_dt,source_record_ct,source_amt,
                target_record_ct,target_amt,datamart_nm,status_desc,source_system_nm,
                GETDATE(),GETDATE()
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.source_amt=Source.source_amt,
		Target.target_amt=Source.target_amt,
		Target.status_desc=Source.status_desc,
		Target.[update_ts] = getdate();
		
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=CAST(DATEADD(DAY, -15, GETDATE()) AS DATE);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.treconciliation_snapsheet_temp1
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