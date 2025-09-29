-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 09/13/2023
-- Description: This procedures inserts written premium data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/16/23		Yunus Mohammed				1. Update logic for category, subcategory columns. Removed extra space in company 
-- 12/01/23		Yunus Mohammed				2. Updated  product name and company name
-- 12/05/23		Yunus Mohammed				3. Removed distinct and added contribcutoffdate date
-- 03/20/24		Yunus Mohammed				4. Added condo in aslob
-- 06/14/24		Yunus Mohammed				5. Updated aslob logic for commission query
-- 09/18/24		Yunus Mohammed				6. Added Throw in catch block and used 
--												Used tinternal_coverage for finacial category for commission part
-- 10/04/24		Yunus Mohammed				7. Added condo in subcategory for commission
-- 10/24/24		Yunus Mohammed				8. Added Marine Boat & Yacht in Commission
-- 11/26/24		Yunus Mohammed				9. Updated Marine Boat & Yacht to Marine_Boat&Yacht
-- 03/11/25		Yunus Mohammed				10.  Corrected proc running for past months
-- 04/25/25		Yunus Mohammed				11. AD8820 Updated logic to get risk address
--																					Update run date logic
-- 07/22/25		Dinesh Bobbili				12. AD10205 Added 5 PEL columns
-- 09/25/25		Dinesh Bobbili				13. AD11102 Added scheduled_limit_amt,blanket_limit_amt columns 
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_workday_written_premium_feed]
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
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

		DECLARE @year_month INT
		DECLARE @acounting_date_sk int,@last_day_month date

		DECLARE cur_main CURSOR FOR
		select yearmonth
		from edw_core.tdate
		where
		actual_dt >  @last_source_extract_ts
		and actual_dt < cast(@current_date as date)
		group by yearmonth
		order by 1; 
		
		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @year_month

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
			SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

			SELECT @acounting_date_sk=date_sk, @last_day_month=actual_dt from edw_core.tdate where yearmonth=@year_month and month_end_in='Y'
		
			DELETE FROM edw_integration.policy_workday_written_premium_feed WHERE accounting_date=@last_day_month;
			WITH policy_workday_written_premium_feed_temp AS
			(
			SELECT
				accounting_date,NULL AS policy_image_id,transaction_id,policy_number,
				CASE
					WHEN product = 'Excess Liability' THEN 'Excess_Liability'
					WHEN product = 'Auto' THEN 'Automobile'
					WHEN product = 'Condo' THEN 'Homeowners'
					WHEN product = 'Marine Boat & Yacht' THEN 'Marine_Boat&Yacht'
					ELSE product
				END AS product,
				transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,NULL AS number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,SUM(premium_amt) AS amount,NULL AS deleteddate,NULL AS contribcutoffdate,
				do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt,
				GETDATE() AS extraction_time,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk as etl_audit_sk
			FROM
			(
			SELECT
				@last_day_month AS [accounting_date],
				tp.policy_sk AS transaction_id,
				tp.policy_no AS [policy_number],
				tprd.product_nm AS [product],
				tpt.transaction_seq_no AS [transaction_sequence],
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
				END AS [risk_state],
				CASE
					WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.zip_cd
					WHEN tprd.product_nm =  'Collections' THEN cl.zip_cd
					WHEN tprd.product_nm =  'Excess Liability' THEN pl.zip_cd
					WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.zip_cd
					WHEN tprd.product_cd = 'Auto' THEN agl.garage_address_zip_code
					ELSE tp.mailing_address_zip_cd
				END AS [zip],
				NULL AS fire_protection,
				tic.internal_coverage_category_nm  AS [category],
				CASE
				WHEN tic.internal_coverage_cd in ('Cyber Protection','Service Line','Systems Protection') THEN 'Premium-Reinsured'
				WHEN internal_coverage_category_nm='Premium' THEN internal_coverage_category_nm
				WHEN internal_coverage_category_nm!='Premium' THEN internal_coverage_desc
				END AS subcategory,
				tic.internal_coverage_sk as financial_category_id,
				tic.internal_coverage_desc AS [financial_category_name],
				tic.aslob_cd AS [aslob],
				tpt.premium_amt,
				pc.do_limit_amt,
				pc.employment_practices_liability_amt,
				pc.pel_limit_amt,
				pc.uninsured_underinsured_liability_amt,
				pc.uninsured_underinsured_motorist_liability_amt,
				tc.scheduled_limit_amt,
				tc.blanket_limit_amt	
			FROM
				edw_core.tpolicy_transaction tpt
				INNER JOIN edw_core.tpolicy tp on tp.policy_sk=tpt.policy_sk
				INNER JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpt.internal_coverage_sk
				INNER JOIN edw_core.tdate tdeff on tdeff.date_sk=tpt.transaction_effective_dt_sk
				INNER JOIN edw_core.tdate tdpro on tdpro.date_sk=tpt.transaction_dt_sk
				INNER JOIN edw_core.tpolicy_transaction_type tptt on tptt.policy_transaction_type_sk=tpt.policy_transaction_type_sk
				INNER JOIN edw_core.tbroker tb on tb.broker_sk=tpt.broker_sk
				INNER JOIN edw_core.tdate tdacc on tdacc.date_sk=tpt.accouting_month_sk
				INNER JOIN edw_core.tproduct tprd on tprd.product_sk = tpt.product_sk
				LEFT JOIN edw_core.thome_location hl on hl.policy_no = tp.policy_no and hl.effective_dt = tp.effective_dt
				LEFT JOIN edw_core.tcollection_location cl on cl.policy_no = tp.policy_no and cl.effective_dt = tp.effective_dt
				LEFT JOIN edw_core.tpel_coverage pc on pc.policy_history_sk = tpt.policy_history_sk
				LEFT JOIN edw_core.tcollection_class_type tc on tc.policy_history_sk = tpt.policy_history_sk and tc.collection_class_type_sk = tpt.collection_class_type_sk
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
				tpt.accouting_month_sk=@acounting_date_sk
				AND GREATEST(tpt.transaction_dt_sk,tpt.transaction_effective_dt_sk)<=@acounting_date_sk
				AND tpt.premium_amt != 0
			) AS temp
			GROUP BY
				accounting_date,transaction_id,policy_number,product,transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt
			),
			policy_workday_written_premium_feed_commission_temp AS
			(
			SELECT
				accounting_date,NULL AS policy_image_id,transaction_id,policy_number,
				CASE
					WHEN product = 'Excess Liability' THEN 'Excess_Liability'
					WHEN product = 'Auto' THEN 'Automobile'
					WHEN product = 'Condo' THEN 'Homeowners'
					WHEN product = 'Marine Boat & Yacht' THEN 'Marine_Boat&Yacht'
					ELSE product
				END AS product,
				transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,NULL AS number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,SUM(premium_amt) AS amount,NULL AS deleteddate,NULL AS contribcutoffdate,
				do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt,
				GETDATE() AS extraction_time,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk as etl_audit_sk
			FROM
			(
				SELECT
				@last_day_month AS [accounting_date],
				tp.policy_sk AS transaction_id,
				tp.policy_no AS [policy_number],
				tprd.product_nm as [product],
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
					WHEN tprd.product_cd = 'Auto' THEN agl.garage_address_zip_code
					ELSE tp.mailing_address_zip_cd
				END AS [zip],
				NULL AS fire_protection,
				'Commission'  AS [category],
				CASE
				WHEN tp.product_cd in ('HO','CO') THEN 'Home Commission'
				WHEN tp.product_cd = 'AU' THEN 'Auto Commission'
				WHEN tp.product_cd = 'PEL' THEN 'PEL Commission'
				WHEN tp.product_cd = 'LUX' THEN 'LUX Commission'
				WHEN tp.product_cd = 'BY' THEN 'Marine_Boat&Yacht Commission'
				END
				as subcategory,
				tic.internal_coverage_sk as financial_category_id,
				tic.internal_coverage_desc AS [financial_category_name],
				tic.aslob_cd AS [aslob],
				tpt.commission_amt AS premium_amt,
				pc.do_limit_amt,
				pc.employment_practices_liability_amt,
				pc.pel_limit_amt,
				pc.uninsured_underinsured_liability_amt,
				pc.uninsured_underinsured_motorist_liability_amt,
				tc.scheduled_limit_amt,
				tc.blanket_limit_amt
				FROM
				edw_core.tpolicy_transaction tpt
				INNER JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpt.internal_coverage_sk
				inner join edw_core.tpolicy tp on tp.policy_sk=tpt.policy_sk
				INNER JOIN edw_core.tdate tdeff on tdeff.date_sk=tpt.transaction_effective_dt_sk
				INNER JOIN edw_core.tdate tdpro on tdpro.date_sk=tpt.transaction_dt_sk
				INNER JOIN edw_core.tpolicy_transaction_type tptt on tptt.policy_transaction_type_sk=tpt.policy_transaction_type_sk
				INNER JOIN edw_core.tbroker tb on tb.broker_sk=tpt.broker_sk
				INNER JOIN edw_core.tproduct tprd on tprd.product_sk = tpt.product_sk
				LEFT JOIN edw_core.thome_location hl on hl.policy_no = tp.policy_no and hl.effective_dt = tp.effective_dt
				LEFT JOIN edw_core.tcollection_location cl on cl.policy_no = tp.policy_no and cl.effective_dt = tp.effective_dt
				LEFT JOIN edw_core.tpel_coverage pc on pc.policy_history_sk = tpt.policy_history_sk
				LEFT JOIN edw_core.tcollection_class_type tc on tc.policy_history_sk = tpt.policy_history_sk and tc.collection_class_type_sk = tpt.collection_class_type_sk
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
				tpt.accouting_month_sk=@acounting_date_sk
				and tpt.commission_amt!=0
				) as temp
				GROUP BY
				accounting_date,transaction_id,policy_number,product,transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt
			)

			INSERT INTO edw_integration.policy_workday_written_premium_feed
			(
			accounting_date,policy_image_id,policy_image_identifier_id,policy_number,product,transaction_sequence,company,transaction_date,
			effective_date,expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
			[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
			aslob,amount,deleteddate,contribcutoffdate,do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,
			uninsured_underinsured_motorist_liability_amt,extraction_time,create_ts,update_ts,etl_audit_sk,scheduled_limit_amt,blanket_limit_amt
			)

			SELECT
				wp.accounting_date,wp.policy_image_id,wp.transaction_id,wp.policy_number,wp.product,wp.transaction_sequence,wp.company,wp.transaction_date,
				wp.effective_date,wp.expiration_date,wp.transaction_type,wp.producer_code,wp.agency_name,wp.number_of_installments,wp.insured_name,
				wp.[address],wp.county,wp.city,wp.risk_state,wp.zip,wp.fire_protection,category,wp.subcategory,wp.financial_category_id,wp.financial_category_name,
				wp.aslob,wp.amount,wp.deleteddate,d.subscriber_contribution_end_dt AS contribcutoffdate,wp.do_limit_amt,wp.employment_practices_liability_amt,wp.pel_limit_amt,
				wp.uninsured_underinsured_liability_amt,wp.uninsured_underinsured_motorist_liability_amt,wp.extraction_time,wp.create_ts,wp.update_ts,wp.etl_audit_sk,
				case when product = 'Collections' and financial_category_name like '%(Scheduled)' then wp.scheduled_limit_amt end as scheduled_limit_amt,
				case when product = 'Collections' and financial_category_name like '%(Blanket)' then wp.blanket_limit_amt end as blanket_limit_amt
			FROM
			(
			SELECT
				accounting_date,policy_image_id,transaction_id,policy_number,product,transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,amount,null as deleteddate,null contribcutoffdate,extraction_time,create_ts,update_ts,etl_audit_sk,
				do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt
			FROM
				policy_workday_written_premium_feed_temp
			UNION
			SELECT
				accounting_date,policy_image_id,transaction_id,policy_number,product,transaction_sequence,company,transaction_date,
				effective_date,expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,amount,null as deleteddate,null contribcutoffdate,extraction_time,create_ts,update_ts,etl_audit_sk,
				do_limit_amt,employment_practices_liability_amt,pel_limit_amt,uninsured_underinsured_liability_amt,uninsured_underinsured_motorist_liability_amt,
				scheduled_limit_amt,blanket_limit_amt
			FROM
			policy_workday_written_premium_feed_commission_temp
			) as wp
			left join
			(
			select
			policy_no,effective_dt,transaction_seq_no,max(subscriber_contribution_end_dt) as subscriber_contribution_end_dt
			from
			edw_core.tpolicy_insured where subscriber_contribution_end_dt is not null
			group by policy_no,effective_dt,transaction_seq_no
			) as d on wp.policy_number = d.policy_no and wp.effective_date = d.effective_dt
			and wp.transaction_sequence = d.transaction_seq_no;


			SET @rows_affected=@@ROWCOUNT;

			-- Update control table
			SET @new_last_source_extract_ts=dateadd(day,-1,cast(@current_date as date));
			EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

			-- Update audit table
			SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

			SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

			FETCH NEXT FROM cur_main INTO @year_month;
		END
	
		CLOSE cur_main;

		DEALLOCATE cur_main;
		
	END TRY
	BEGIN CATCH
	print @acounting_date_sk
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
