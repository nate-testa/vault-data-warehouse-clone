-- ==============================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-10-30
-- Description: This stored procedure insert info related to rpt_daily_inforce_policy.
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------
-- 10/30/25		Alberto Almario			    1. Created this procedure
-- ==============================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_rpt_daily_inforce_policy]
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
		
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'Full load - Monthly inforce policy snapshot'

		--************Start************

		-- Drop temp table if exists
		DROP TABLE IF EXISTS [edw_temp].[rpt_daily_inforce_policy_temp1];

		-- Create temp table with initial extraction
		-- Generate last day of each month since 2017
		-- For current month, use yesterday's date instead
		WITH MonthSequence AS (
			SELECT TOP (DATEDIFF(MONTH, '2017-01-01', GETDATE()) + 1)
				DATEADD(MONTH, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2017-01-01') AS month_date
			FROM sys.all_objects
		),
		MonthEndDates AS (
			SELECT 
				CASE 
					-- If it's the current month, use yesterday's date
					WHEN YEAR(EOMONTH(month_date)) = YEAR(GETDATE()) 
						 AND MONTH(EOMONTH(month_date)) = MONTH(GETDATE())
					THEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)
					-- Otherwise use last day of month
					ELSE EOMONTH(month_date)
				END AS actual_dt
			FROM MonthSequence
		)
		SELECT 
			b.actual_dt,
			f.policy_no,
			c.product_nm,
			d.broker_id,
			d.broker_nm,
			e.customer_id,
			e.customer_nm,
			f.risk_state_cd,
			f.uw_company_nm,
			ISNULL(a.premium_amt, 0) AS premium_amt,
			ISNULL(a.commission_amt, 0) AS commission_amt,
			ISNULL(a.net_premium_amt, 0) AS net_premium_amt,
			ISNULL(a.annual_premium_amt, 0) AS annual_premium_amt,
			getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
		INTO [edw_temp].[rpt_daily_inforce_policy_temp1]
		FROM edw_core.tdaily_inforce_policy a
		INNER JOIN edw_core.tdate b ON a.inforce_dt_sk = b.date_sk
		INNER JOIN edw_core.tproduct c ON a.product_sk = c.product_sk
		INNER JOIN edw_core.tbroker d ON a.broker_sk = d.broker_sk
		INNER JOIN edw_core.tcustomer e ON a.customer_sk = e.customer_sk
		INNER JOIN edw_core.tpolicy f ON a.policy_sk = f.policy_sk
		WHERE b.actual_dt IN (SELECT actual_dt FROM MonthEndDates);

		-- Truncate table before full load
		TRUNCATE TABLE [edw_insights_ai].[rpt_daily_inforce_policy];

		-- Start Insert process
		INSERT INTO [edw_insights_ai].[rpt_daily_inforce_policy]
        (
            actual_dt,
            policy_no,
            product_nm,
            broker_id,
            broker_nm,
            customer_id,
            customer_nm,
            risk_state_cd,
            uw_company_nm,
            premium_amt,
            commission_amt,
            net_premium_amt,
            annual_premium_amt,
			create_ts,
            update_ts,
            etl_audit_sk
		)
        SELECT 
            actual_dt,
            policy_no,
            product_nm,
            broker_id,
            broker_nm,
            customer_id,
            customer_nm,
            risk_state_cd,
            uw_company_nm,
            premium_amt,
            commission_amt,
            net_premium_amt,
            annual_premium_amt,
			create_ts,
            update_ts,
            etl_audit_sk
        FROM [edw_temp].[rpt_daily_inforce_policy_temp1];

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' Rows loaded: ' + CAST(@rows_affected AS VARCHAR(50))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS [edw_temp].[rpt_daily_inforce_policy_temp1];

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
