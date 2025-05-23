-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 09/13/2023
-- Description: This procedures inserts ceded premium data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 09/13/23		Yunus Mohammed				1. Created the procedure
-- 11/15/23		Yunus Mohammed				2. Updated logic for cancelled and expired policies  
-- 03/20/24		Yunus Mohammed				3. Included condo policies
-- 09/18/24		Yunus Mohammed				4. Added gross premium and added Throw in catch block
-- 10/24/24		Yunus Mohammed				5. Added gross premium in insert
-- 03/11/25		Yunus Mohammed				6. Corrected proc running for past months
--																				Corrected accounting begin date logic and delete stmt where clause.
--																				contribcutoffdate updated
--																				Added run_date as param for pre-run
-- 04/25/25		Yunus Mohammed				7. AD8820 Updated logic to get risk address
--																					Update run date logic
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_workday_ceded_premium_feed]
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
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		
		DECLARE @year_month INT
		DECLARE @accounting_date_end_sk int,@last_end_day_month date
		DECLARE @accounting_date_begin_sk int,@last_begin_day_month date

		DECLARE cur_main CURSOR FOR
		select yearmonth
		from edw_core.tdate
		where
		actual_dt > @last_source_extract_ts
		and actual_dt < cast(@current_date as date)
		group by yearmonth
		order by 1; 

		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @year_month
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
			SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

			SELECT @accounting_date_end_sk=date_sk, @last_end_day_month=actual_dt FROM edw_core.tdate 
			WHERE yearmonth=@year_month AND month_end_in='Y'

			SELECT @accounting_date_begin_sk=date_sk,@last_begin_day_month=actual_dt FROM edw_core.tdate 
			WHERE actual_dt =EOMONTH( dateadd(year,-1,@last_end_day_month)) and month_end_in='Y'
			
			DELETE FROM edw_integration.policy_workday_ceded_premium_feed WHERE accounting_date = @last_end_day_month;
			
			WITH policy_workday_ceded_premium_feed_temp AS
			(
				SELECT
					accounting_date,policy_image_id,NULL AS policy_image_identifier_id,policy_number,product,transaction_sequence,company,transaction_date,
					effective_date,expiration_date,transaction_type,producer_code,agency_name,NULL AS number_of_installments,insured_name,
					[address],county,city,risk_state,zip,fire_protection,financial_category_id,coveragename,SUM(premium_amt) AS amount,
					SUM(gross_premium_amt) as gross_premium_amt,
					NULL AS deleteddate,NULL AS contribcutoffdate,
					GETDATE() AS extraction_time,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk as etl_audit_sk
				FROM
				(
				SELECT
					@last_end_day_month AS [accounting_date],
					tp.policy_sk AS policy_image_id,
					tp.policy_no AS [policy_number],
					CASE
					WHEN tprd.product_nm = 'Excess Liability' THEN 'Excess_Liability'
					WHEN tprd.product_nm = 'Auto' THEN 'Automobile'
					WHEN tprd.product_nm = 'Condo' THEN 'Homeowners'
					ELSE tprd.product_nm
					END AS [product],
					tpt.transaction_seq_no as [transaction_sequence],
					CASE WHEN tp.uw_company_nm='Vault E & S Insurance Company' THEN 'Vault E&S Insurance Company' 
					ELSE tp.uw_company_nm END AS [company],
					GREATEST(tdeff.actual_dt,tdpro.actual_dt) AS [transaction_date],
					tp.effective_dt AS [effective_date],
					tp.expiration_dt AS [expiration_date],
					tptt.policy_transaction_type_cd AS [transaction_type],
					tb.broker_id AS [producer_code],
					tb.broker_nm AS [agency_name],
					tp.insured_nm AS [insured_name],
					CASE
						WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.address_line_1
						WHEN tprd.product_nm =  'Collections' THEN cl.address_line_1
						WHEN tprd.product_nm =  'Excess Liability' THEN pl.address_line_1
						WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.address_line_1
						WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_line1
					ELSE tp.mailing_address_line1
					END AS [address],
					CASE
						WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.county_nm
						WHEN tprd.product_nm =  'Collections' THEN cl.county_nm
						WHEN tprd.product_nm =  'Excess Liability' THEN pl.county_nm
						WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.county_nm
						WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_county_nm
					ELSE tp.mailing_address_county_nm
					END AS [county],
					CASE
						WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.city_nm
						WHEN tprd.product_nm =  'Collections' THEN cl.city_nm
						WHEN tprd.product_nm =  'Excess Liability' THEN pl.city_nm
						WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.city_nm
						WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_city_nm
					ELSE tp.mailing_address_city_nm
					END AS [city],
					CASE
						WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.state_cd
						WHEN tprd.product_nm =  'Collections' THEN cl.state_cd
						WHEN tprd.product_nm =  'Excess Liability' THEN pl.state_cd
						WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.state_cd
						WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_state_cd
					ELSE tp.risk_state_cd
					END AS [RISK_STATE],
					CASE
						WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.zip_cd
						WHEN tprd.product_nm =  'Collections' THEN cl.zip_cd
						WHEN tprd.product_nm =  'Excess Liability' THEN pl.zip_cd
						WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.zip_cd
						WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_zip_code
					ELSE tp.mailing_address_zip_cd
					END AS [zip],
					NULL AS fire_protection,
					tic.internal_coverage_sk AS financial_category_id,
					tic.internal_coverage_desc AS [coveragename],
					tpt.ceded_premium_amt AS premium_amt,
					tpt.premium_amt as gross_premium_amt
				FROM
					edw_core.tpolicy_transaction tpt
					INNER JOIN edw_core.tpolicy tp on tp.policy_sk=tpt.policy_sk
					INNER JOIN edw_core.tproduct tprd on tprd.product_cd = tp.product_cd
					INNER JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpt.internal_coverage_sk
					INNER JOIN edw_core.tdate tdeff on tdeff.date_sk=tpt.transaction_effective_dt_sk
					INNER JOIN edw_core.tdate tdpro on tdpro.date_sk=tpt.transaction_dt_sk
					INNER JOIN edw_core.tpolicy_transaction_type tptt on tptt.policy_transaction_type_sk=tpt.policy_transaction_type_sk
					INNER JOIN edw_core.tbroker tb on tb.broker_sk=tpt.broker_sk
					LEFT JOIN edw_core.thome_location hl on hl.policy_no = tp.policy_no and hl.effective_dt = tp.effective_dt
					LEFT JOIN edw_core.tcollection_location cl on cl.policy_no = tp.policy_no and cl.effective_dt = tp.effective_dt
					LEFT JOIN
					(
						SELECT
								ROW_NUMBER()over(partition by policy_history_sk order by primary_location_in desc,location_no) as rn,
								policy_no,effective_dt,transaction_seq_no,address_line_1,address_line_2,
								unit_no,city_nm,state_cd,zip_cd,county_nm,country_nm,primary_location_in,location_no
						FROM
							edw_core.tpel_location
					) as pl on pl.policy_no = tp.policy_no and pl.effective_dt = tp.effective_dt and pl.transaction_seq_no = tpt.transaction_seq_no and pl.rn = 1
					LEFT JOIN edw_core.tmarine_boat_yacht_location mbyl on mbyl.policy_no = tp.policy_no and mbyl.effective_dt = tp.effective_dt
						and mbyl.transaction_seq_no = tpt.transaction_seq_no
					LEFT JOIN edw_core.tauto_garage_location agl on agl.policy_history_sk = tpt.policy_history_sk 
					and agl.auto_garage_location_sk =
										(
											SELECT top 1 -- policy_no,effective_dt,transaction_seq_no,
											auto_garage_location_sk--,COUNT(auto_vehicle_sk) vehicle_count
											FROM edw_core.tauto_vehicle_coverage agl1 
											where
													agl1.policy_history_sk = agl.policy_history_sk
											GROUP BY policy_no,effective_dt,transaction_seq_no,auto_garage_location_sk
											ORDER BY policy_no,effective_dt,transaction_seq_no,COUNT(auto_vehicle_sk) DESC
										)
				WHERE
					tpt.accouting_month_sk BETWEEN @accounting_date_begin_sk AND @accounting_date_end_sk
					AND tp.product_cd IN('HO','CO')
					AND ISNULL(tpt.ceded_premium_amt,0) ! = 0
					AND tic.internal_coverage_cd in ('Cyber Protection','Service Line','System Protection','Systems Protection')
				) AS temp
				GROUP BY
					accounting_date,policy_image_id,policy_number,product,transaction_sequence,company,transaction_date,
					effective_date,expiration_date,transaction_type,producer_code,agency_name,insured_name,
					[address],county,city,risk_state,zip,fire_protection,financial_category_id,coveragename
			)
			
			INSERT INTO edw_integration.policy_workday_ceded_premium_feed
			(
			accounting_date,policy_image_id,policy_image_identifier_id,policy_number,product,transaction_sequence,company,transaction_date,
			effective_date,expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
			[address],county,city,risk_state,zip,fire_protection,financial_category_id,coverageName,
			amount,gross_premium_amt,deleteddate,contribcutoffdate,extraction_time,create_ts,update_ts,etl_audit_sk
			)
			SELECT
				accounting_date,policy_image_id,policy_image_identifier_id,policy_number,product,transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,financial_category_id,coveragename,
				amount,gross_premium_amt,null as deleteddate,d.subscriber_contribution_end_dt as contribcutoffdate,extraction_time,create_ts,update_ts,etl_audit_sk
			FROM
				policy_workday_ceded_premium_feed_temp cp
				left join
				(
				select
				policy_no,effective_dt,transaction_seq_no,max(subscriber_contribution_end_dt) as subscriber_contribution_end_dt
				from
				edw_core.tpolicy_insured where subscriber_contribution_end_dt is not null
				group by policy_no,effective_dt,transaction_seq_no
				) as d on cp.policy_number = d.policy_no and cp.effective_date = d.effective_dt
				and cp.transaction_sequence = d.transaction_seq_no


			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts= dateadd(day,-1,cast(@current_date as date))
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

			SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

			FETCH NEXT FROM cur_main INTO @year_month
		END
		
		CLOSE cur_main;

		DEALLOCATE cur_main;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
