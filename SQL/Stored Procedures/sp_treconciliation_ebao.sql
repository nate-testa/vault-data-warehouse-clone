-- =================================================================================================
-- Author:		Yunus Mohammed 
-- Description: This procedure reconciles ebao data 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/08/23		Yunus Mohammed				1. Created this procedure 
-- 11/27/23		Yunus Mohammed				2. Updated Merge Statement
-- 07/23/24		Yunus Mohammed				3. Updated 30 days to 90 days
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_treconciliation_ebao]
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

		IF (CAST(@last_source_extract_ts AS DATE) = CAST('1900-01-01' AS DATE))
		BEGIN
			SELECT @last_source_extract_ts=CAST(MIN(post_date) AS DATE) FROM edw_stage.t_clm_reserve_his
		END
		-- Create temp table
		DROP TABLE IF EXISTS edw_temp.treconciliation_ebao_temp1

		SELECT
		source.*
        INTO edw_temp.treconciliation_ebao_temp1
        FROM
        (
            SELECT 
            source.post_date AS transaction_start_dt,source.post_date AS transaction_end_dt,
            NULL AS source_record_ct,source.loss AS source_amt,NULL AS target_record_ct,target.loss AS target_amt,
            'Claim' AS datamart_nm,CASE WHEN source.loss=target.loss THEN 'SUCCESS' ELSE 'FAILURE' END AS status_desc,
            'eBao' AS source_system_nm
            FROM
            (
            SELECT CAST(post_date AS DATE) AS post_date,SUM(outstanding_changed+settle_changed) AS loss 
            FROM 
                edw_stage.t_clm_reserve_his
            WHERE CAST(post_date AS DATE) BETWEEN CAST(@last_source_extract_ts AS DATE) AND CAST(GETDATE() AS DATE)
            GROUP BY CAST(post_date AS DATE)
            ) AS source
            LEFT JOIN
            (
            SELECT
                CAST(transaction_ts AS DATE) AS transaction_ts,
                SUM(loss_reserve_amt+expense_reserve_amt+adjusting_other_reserve_amt+subro_reserve_amt+
                    salvage_reserve_amt+salvage_expense_reserve_amt+subro_expense_reserve_amt+loss_paid_amt+
                    expense_paid_amt+adjusting_other_paid_amt+subro_recovery_amt+salvage_recovery_amt+
                    salvage_expense_paid_amt+subro_expense_paid_amt+refund_indemnity_paid_amt+refund_expense_paid_amt
                    ) AS loss
            FROM edw_core.tclaim_transaction
            WHERE (CAST(transaction_ts AS DATE) BETWEEN CAST(@last_source_extract_ts AS DATE) AND CAST(GETDATE() AS DATE)) AND source_system_sk=3
            GROUP BY CAST(transaction_ts AS DATE)
            ) AS target ON source.post_date=target.transaction_ts
        ) AS source        

		-- Insert and Update treconciliation table
		MERGE [edw_core].[treconciliation] AS Target
		USING edw_temp.treconciliation_ebao_temp1 AS Source
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
		SET @new_last_source_extract_ts=CAST(DATEADD(DAY, -90, GETDATE()) AS DATE);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.treconciliation_ebao_temp1
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
