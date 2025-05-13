-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 09/13/2023
-- Description: This procedures inserts unearned premium data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/15/23		Yunus Mohammed				1. Updated logic for cancelled and expired policies
-- 12/01/23		Yunus Mohammed				2. Updated  product name and company name
-- 12/05/23		Yunus Mohammed				3. Added contribcutoffdate date
-- 02/14/24		Yunus Mohammed				4. Removed distinct and added check from tpolicy_history table
-- 09/18/24		Yunus Mohammed				5. Added Throw in catch block
-- 11/26/24		Yunus Mohammed				6. Updated Marine Boat & Yacht to Marine_Boat&Yacht
-- 03/11/25		Yunus Mohammed				7. Corrected proc running for past months
--																				Added run_date as param for pre-run
-- 04/25/25		Yunus Mohammed				8. AD8820 Updated logic to get risk address
--																					Update run date logic
-- 05/07/25		Yunus Mohammed				9. AD9047 Used tdaily_inforce table to check inforce policies.
--																					Removed cancellation logic
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_workday_unearned_premium_feed]
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
		DECLARE @acounting_date_sk int,@last_day_month date	,@end_dt_sk int

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

			SELECT @acounting_date_sk=date_sk, @last_day_month=actual_dt ,@end_dt_sk = date_sk
			FROM edw_core.tdate WHERE yearmonth=@year_month and month_end_in='Y';
		
			DELETE FROM edw_integration.policy_workday_unearned_premium_feed WHERE accounting_date=@last_day_month;

			IF @year_month = concat(datepart(yyyy,@current_date),iif(datepart(mm,@current_date) < 10,'0','') ,datepart(mm,@current_date) )
			BEGIN  
					SELECT 
						@end_dt_sk = max(date_sk)
					FROM edw_core.tdate
					WHERE yearmonth = @year_month AND actual_dt < cast(@current_date AS DATE)
			END;

			WITH policy_workday_unearned_premium_feed_temp AS
			(
				SELECT
				accounting_date,policy_image_id,policy_number,product,
				company,transaction_date,transaction_sequence,effective_date,
				expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,sum(amount) as amount,sum(unearned) as unearned,contribcutoffdate,
				getdate() as extraction_time,
				getdate() as create_ts,
				getdate() as update_ts,
				@etl_audit_sk AS etl_audit_sk
			FROM
			(
			 SELECT				
				@last_day_month AS [accounting_date],
				tp.policy_sk AS policy_image_id,
				tp.policy_no AS [policy_number],
				CASE
					WHEN tprd.product_nm = 'Excess Liability' THEN 'Excess_Liability'
					WHEN tprd.product_nm = 'Auto' THEN 'Automobile'
					WHEN tprd.product_nm = 'Condo' THEN 'Homeowners'
					WHEN tprd.product_cd = 'Marine Boat & Yacht' THEN 'Marine_Boat&Yacht'
					ELSE tprd.product_nm
				END AS [product],
				CASE WHEN tp.uw_company_nm='Vault E & S Insurance Company' THEN 'Vault E&S Insurance Company' 
				ELSE tp.uw_company_nm END AS [company],
				GREATEST(tdeff.actual_dt,tdpro.actual_dt) AS [transaction_date],
				tpts.transaction_seq_no AS transaction_sequence,
				tp.effective_dt AS [effective_date],
				tp.expiration_dt AS [expiration_date],
				tptt.policy_transaction_type_cd AS [transaction_type],
				CAST(tb.broker_id AS VARCHAR(100)) AS producer_code,
				tb.broker_nm AS agency_name,
				NULL AS number_of_installments,
				tp.insured_nm AS insured_name,
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
				END AS county,
				CASE
					WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.city_nm
					WHEN tprd.product_nm =  'Collections' THEN cl.city_nm
					WHEN tprd.product_nm =  'Excess Liability' THEN pl.city_nm
					WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.city_nm
					WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_city_nm
					ELSE tp.mailing_address_city_nm
				END AS city,
				CASE
					WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.state_cd
					WHEN tprd.product_nm =  'Collections' THEN cl.state_cd
					WHEN tprd.product_nm =  'Excess Liability' THEN pl.state_cd
					WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.state_cd
					WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_state_cd
					ELSE tp.risk_state_cd
				END AS risk_state,
				CASE
					WHEN tprd.product_nm in ( 'Homeowners' ,'Condo') THEN hl.zip_cd
					WHEN tprd.product_nm =  'Collections' THEN cl.zip_cd
					WHEN tprd.product_nm =  'Excess Liability' THEN pl.zip_cd
					WHEN tprd.product_nm =  'Marine Boat & Yacht' THEN mbyl.zip_cd
					WHEN tprd.product_nm = 'Auto' THEN agl.garage_address_zip_code
					ELSE tp.mailing_address_zip_cd
				END AS zip,
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
				tpts.premium_amt AS [amount],
				tpts.unearned_premium_amt AS [unearned],
				null as contribcutoffdate
			FROM
			edw_core.tpolicy_transaction_summary tpts
			INNER JOIN edw_core.tpolicy tp on tp.policy_sk=tpts.policy_sk
			INNER JOIN edw_core.tproduct tprd on tprd.product_cd = tp.product_cd
			INNER JOIN edw_core.tdate tdeff on tdeff.date_sk=tpts.transaction_effective_dt_sk
			INNER JOIN edw_core.tdate tdpro on tdpro.date_sk=tpts.transaction_dt_sk
			INNER JOIN edw_core.tpolicy_transaction_type tptt on tptt.policy_transaction_type_sk=tpts.policy_transaction_type_sk
			INNER JOIN edw_core.tbroker tb on tb.broker_sk=tpts.broker_sk
			INNER JOIN edw_core.tdaily_inforce_policy  dip on dip.policy_sk = tp.policy_sk	and dip.inforce_dt_sk = @end_dt_sk
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
    		) as pl on pl.policy_no = tp.policy_no and pl.effective_dt = tp.effective_dt and pl.transaction_seq_no = tpts.transaction_seq_no and pl.rn = 1
			LEFT JOIN edw_core.tmarine_boat_yacht_location mbyl on mbyl.policy_no = tp.policy_no and mbyl.effective_dt = tp.effective_dt
			and mbyl.transaction_seq_no = tpts.transaction_seq_no
			LEFT JOIN edw_core.tauto_garage_location agl on agl.policy_history_sk = tpts.policy_history_sk 
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

			LEFT JOIN edw_core.tinternal_coverage tic ON tic.internal_coverage_sk=tpts.internal_coverage_sk
			WHERE
				tpts.month_sk=@acounting_date_sk
				AND (tic.internal_coverage_category_nm = 'Premium' OR tic.internal_coverage_desc like 'Subscriber Contribution%')
				AND tpts.transaction_effective_dt_sk < = @acounting_date_sk
				AND tpts.expiration_dt_sk > @acounting_date_sk
			) AS t
			GROUP BY
				accounting_date,policy_image_id,policy_number,product,company,transaction_date,transaction_sequence,effective_date,
				expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,contribcutoffdate
			)	
		
			INSERT INTO edw_integration.policy_workday_unearned_premium_feed
			(
				accounting_date,policy_image_id,policy_number,product,company,transaction_date,transaction_sequence,effective_date,
				expiration_date,transaction_type,producer_code,agency_name,number_of_installments,insured_name,
				[address],county,city,risk_state,zip,fire_protection,category,subcategory,financial_category_id,financial_category_name,
				aslob,amount,unearned,contribcutoffdate,extraction_time,create_ts,update_ts,etl_audit_sk
			)
			SELECT
				uep.accounting_date,uep.policy_image_id,uep.policy_number,uep.product,uep.company,uep.transaction_date,uep.transaction_sequence,uep.effective_date,
				uep.expiration_date,uep.transaction_type,uep.producer_code,uep.agency_name,uep.number_of_installments,uep.insured_name,
				uep.[address],uep.county,uep.city,uep.risk_state,uep.zip,uep.fire_protection,uep.category,
				CASE WHEN  uep.subcategory IN ('Subscriber Contribution (Automobile)','Subscriber Contribution (Homeowners)')
				THEN 'Subscriber Contribution'
				ELSE uep.subcategory END AS subcategory,
				uep.financial_category_id,uep.financial_category_name,
				uep.aslob,uep.amount,uep.unearned,d.subscriber_contribution_end_dt AS contribcutoffdate,uep.extraction_time,uep.create_ts,uep.update_ts,uep.etl_audit_sk
			FROM
				policy_workday_unearned_premium_feed_temp uep
				left join
				(
				select
				policy_no,effective_dt,transaction_seq_no,max(subscriber_contribution_end_dt) as subscriber_contribution_end_dt
				from
				edw_core.tpolicy_insured where subscriber_contribution_end_dt is not null
				group by policy_no,effective_dt,transaction_seq_no
				) as d on uep.policy_number = d.policy_no and uep.effective_date = d.effective_dt
				and uep.transaction_sequence = d.transaction_seq_no

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
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
