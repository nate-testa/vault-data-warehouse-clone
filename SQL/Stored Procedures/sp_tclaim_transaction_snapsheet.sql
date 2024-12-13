SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Description: This procedures inserts and updates claim notes snapsheet
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/30/24		Hernando Gonzalez			1. Created this procedure - AD7391
-- 11/20/24		Alberto Almario				2. Changes on some columns and tables
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_transaction_snapsheet]
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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		--************Start************

		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp1;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp2;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp3;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp4;


		-- *** Create temp table 1 ***
		SELECT
			tc.claim_sk 
			,tf.claim_feature_sk AS claim_feature_sk
			,tpr.product_sk 
			,tc.policy_sk 
			,tb.broker_sk 
			,tcu.customer_sk 
			,td1.date_sk AS transaction_dt_sk 
			,fta.created_at AS transaction_ts 
			,res.financial_transaction_id AS claim_payment_sk -- get claim_pyment_sk from tclaim_payment on financial_transaction_id = tclaim_payment.payment_no
			,case 
				when res.cost_type like '%_claim%' 		and res.reserve_method is NULL 			then 'claim'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method is NULL 			then 'adjusting'
				when res.cost_type like '%_defense%' 	and res.reserve_method is NULL 			then 'defense'
				when res.cost_type like '%_claim%' 		and res.reserve_method = 'subrogation' 	then 'claim-subrogation'
				when res.cost_type like '%_claim%' 		and res.reserve_method = 'salvage' 		then 'claim-salvage'
				when res.cost_type like '%_claim%' 		and res.reserve_method = 'overpayment' 	then 'claim-overpayment'
				when res.cost_type like '%_claim%' 		and res.reserve_method = 'deductible' 	then 'claim-deductible'
				when res.cost_type like '%_claim%' 		and res.reserve_method = 'reinsurance' 	then 'claim-reinsurance'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method = 'salvage'  	then 'adjusting-salvage'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method = 'subrogation'  then 'adjusting-subrogation'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method = 'overpayment'  then 'adjusting-overpayment'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method = 'deductible'   then 'adjusting-deductible'
				when res.cost_type like '%_adjusting%' 	and res.reserve_method = 'reinsurance'  then 'adjusting-reinsurance'
				when res.cost_type like '%_defense%' 	and res.reserve_method = 'salvage' 		then 'defense-salvage'
				when res.cost_type like '%_defense%' 	and res.reserve_method = 'subrogation' 	then 'defense-subrogation'
				when res.cost_type like '%_defense%' 	and res.reserve_method = 'overpayment' 	then 'defense-overpayment'
				when res.cost_type like '%_defense%' 	and res.reserve_method = 'deductible' 	then 'defense-deductible'
				when res.cost_type like '%_defense%' 	and res.reserve_method = 'reinsurance' 	then 'defense-reinsurance'
			end as claim_transaction_type_cd
			,NULL AS feature_status_sk 
			,tcc.claim_cost_category_sk AS claim_cost_category_sk
			,res.claim_id
			,c.claim_number
			,res.system_generated
			,e.exposure_type
			,e.exposure_name
			,e.claimant_name
			,e.claimant_claim_party_id
			,e.coverage_premium_class
			,e.coverage_name
			,fta.created_at
			,fta.code
			,res.financial_transaction_id
			,res.cost_type
			,res.exposure_id
			,res.cost_category
			,res.reserve_method
			,res.amount
			,CASE 
				WHEN fta.code='cancel' THEN -1*res.amount
				ELSE res.amount -LAG(res.amount,1,0) over (partition by res.claim_id,res.exposure_id,res.cost_type,res.cost_category,res.reserve_method --,ft.id
														order by res.claim_id,res.exposure_id,res.cost_type,res.cost_category,res.reserve_method,fta.created_at) 
			END as reserve_amount
			,5 AS source_system_sk
		INTO edw_temp.tclaim_transaction_snapsheet_temp1
		FROM edw_stage_snapsheet.financial_reserve_items res
		LEFT JOIN edw_stage_snapsheet.financial_transactions ft on res.financial_transaction_id = ft.id
		LEFT JOIN edw_stage_snapsheet.financial_transaction_actions fta on fta.financial_transaction_id = res.financial_transaction_id
		INNER JOIN edw_stage_snapsheet.claims c on c.id = res.claim_id
		INNER JOIN edw_core.tclaim tc ON tc.claim_no = c.claim_number
		INNER JOIN edw_core.tclaim_feature tf ON tf.claim_no = tc.claim_no and res.exposure_id = tf.claim_coverage_cd
		INNER JOIN edw_stage_snapsheet.exposures e on e.claim_id = res.claim_id and tf.exposure_name = e.exposure_name and tf.exposure_type = e.exposure_type
		LEFT JOIN edw_core.tpolicy tp ON tp.policy_sk = tc.policy_sk
		LEFT JOIN edw_core.tbroker tb ON tb.broker_id = tp.broker_id
		LEFT JOIN edw_core.tcustomer tcu ON tcu.customer_id = tp.customer_id
		LEFT JOIN edw_core.tdate as td1 ON td1.actual_dt = CAST(res.created_at AS DATE)
		LEFT JOIN edw_core.tclaim_cost_category as tcc on tcc.claim_cost_category_nm = res.cost_category
		LEFT JOIN edw_core.tproduct tpr
			ON tpr.product_cd = (CASE 
									WHEN c.claim_type = 'auto' THEN 'AU' 
									WHEN c.claim_type = 'liability' THEN 'PEL' 
									WHEN c.claim_type = 'property' THEN 'HO' 
									ELSE c.claim_type 
								END)
		WHERE 1=1
			and fta.created_at > @last_source_extract_ts
			and fta.code in ('submitted','cancel') 
			and ft.approved_at is not null --> Added this filter to exclude pending approvals reserves and subsequent cancel records
		ORDER BY res.claim_id,res.exposure_id,res.cost_type,res.cost_category,res.reserve_method,fta.created_at
		;


		-- *** Create temp table 2 for reserve data***
		SELECT
			 a.claim_sk 
			,a.claim_feature_sk
			,a.product_sk 
			,a.policy_sk 
			,a.broker_sk 
			,a.customer_sk
			,a.transaction_dt_sk
			,a.claim_payment_sk
			,ctt.claim_transaction_type_sk
			,a.feature_status_sk
			,a.claim_cost_category_sk
			,a.claim_number
			,a.exposure_type
			,a.exposure_name
			,a.coverage_premium_class
			,a.coverage_name
			,a.transaction_ts
			,a.reserve_method 
			,a.source_system_sk
			,a.created_at
			,a.financial_transaction_id
			,a.cost_type
			,a.exposure_id
			,a.cost_category
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method is NULL 			then a.reserve_amount else 0 end as loss_reserve_amt 
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method is NULL 			then a.reserve_amount else 0 end as expense_reserve_amt 
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method is NULL 			then a.reserve_amount else 0 end as defense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method = 'subrogation' 	then a.reserve_amount else 0 end as subrogation_recovery_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method = 'salvage' 		then a.reserve_amount else 0 end as salvage_recovery_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method = 'deductible' 	then a.reserve_amount else 0 end as deductible_recovery_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method = 'reinsurance' 	then a.reserve_amount else 0 end as reinsurance_recovery_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'claim' 		and a.reserve_method = 'overpayment' 	then a.reserve_amount else 0 end as overpayment_recovery_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method = 'subrogation' 	then a.reserve_amount else 0 end as subrogation_recovery_expense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method = 'salvage' 		then a.reserve_amount else 0 end as salvage_recovery_expense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method = 'deductible' 	then a.reserve_amount else 0 end as deductible_recovery_expense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method = 'reinsurance' 	then a.reserve_amount else 0 end as reinsurance_recovery_expense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'adjusting' 	and a.reserve_method = 'overpayment' 	then a.reserve_amount else 0 end as overpayment_recovery_expense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method = 'subrogation'  	then a.reserve_amount else 0 end as subrogation_recovery_defense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method = 'salvage' 		then a.reserve_amount else 0 end as salvage_recovery_defense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method = 'deductible' 	then a.reserve_amount else 0 end as deductible_recovery_defense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method = 'reinsurance' 	then a.reserve_amount else 0 end as reinsurance_recovery_defense_reserve_amt
			,case when SUBSTRING(a.cost_type, CHARINDEX('_', a.cost_type) + 1, LEN(a.cost_type)) = 'defense' 	and a.reserve_method = 'overpayment' 	then a.reserve_amount else 0 end as overpayment_recovery_defense_reserve_amt 
		INTO edw_temp.tclaim_transaction_snapsheet_temp2
		FROM edw_temp.tclaim_transaction_snapsheet_temp1 a
		LEFT JOIN edw_core.tclaim_transaction_type ctt on a.claim_transaction_type_cd = ctt.claim_transaction_type_cd
		;


		-- *** Create temp table 3 for payment data***
		SELECT 
			tc.claim_sk 
			,tpr.product_sk 
			,tc.policy_sk 
			,tb.broker_sk 
			,c.claim_number
			,e.exposure_name
			,e.coverage_premium_class
			,e.coverage_name
			,pay.amount as source_paid_amt
			,fta.created_at as transaction_ts
			,res.reserve_method as reserve_method
			,ft.id as source_transaction_id
			,pay.financial_transaction_id
			,pay.cost_type
			,pay.exposure_id
			,pay.cost_category
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method is NULL and fta.code='submitted' then pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method is NULL and fta.code in ('stop','cancel') then -1 * pay.amount
				ELSE 0 END) as loss_paid_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method is NULL and fta.code='submitted' then pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method is NULL and fta.code in ('stop','cancel') then -1 * pay.amount
				ELSE 0 END) as expense_paid_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method is NULL and fta.code='submitted' then pay.amount
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method is NULL and fta.code in ('stop','cancel') then -1 * pay.amount
				ELSE 0 END) as defense_paid_amt 
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'subrogation' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'subrogation' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as subrogation_recovery_amt 
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'salvage' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'salvage' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as salvage_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'deductible' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'deductible' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as deductible_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'reinsurance' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'reinsurance' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as reinsurance_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'overpayment' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'claim' and res.reserve_method = 'overpayment' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as overpayment_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'subrogation' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'subrogation' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as subrogation_expense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'salvage' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'salvage' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as salvage_expense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'deductible' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'deductible' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as deductible_expense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'reinsurance' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'reinsurance' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as reinsurance_expense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'overpayment' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'adjusting' and res.reserve_method = 'overpayment' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as overpayment_expense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'subrogation' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'subrogation' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as subrogation_defense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'salvage' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'salvage' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as salvage_defense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'deductible' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'deductible' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as deductible_defense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'reinsurance' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'reinsurance' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as reinsurance_defense_recovery_amt
			,(case when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'overpayment' and fta.code='submitted' then -1 * pay.amount 
				when SUBSTRING(pay.cost_type, CHARINDEX('_', pay.cost_type) + 1, LEN(pay.cost_type)) = 'defense' and res.reserve_method = 'overpayment' and fta.code in ('stop','cancel') then  pay.amount 
				ELSE 0 END) as overpayment_defense_recovery_amt 
		INTO edw_temp.tclaim_transaction_snapsheet_temp3
		FROM edw_stage_snapsheet.financial_reserve_items res
		left JOIN edw_stage_snapsheet.financial_payment_items pay ON pay.financial_transaction_id = res.financial_transaction_id AND pay.cost_type = res.cost_type AND pay.exposure_id = res.exposure_id AND pay.cost_category = res.cost_category
		left join edw_stage_snapsheet.financial_transactions ft on res.financial_transaction_id = ft.id
		left JOIN edw_stage_snapsheet.financial_transaction_actions fta on fta.financial_transaction_id = res.financial_transaction_id
		INNER JOIN edw_stage_snapsheet.claims c on c.id = res.claim_id
		INNER JOIN edw_core.tclaim tc ON tc.claim_no = c.claim_number
		INNER JOIN edw_core.tclaim_feature tf ON tf.claim_no = tc.claim_no and res.exposure_id = tf.claim_coverage_cd
		INNER JOIN edw_stage_snapsheet.exposures e on e.claim_id = res.claim_id and tf.exposure_name = e.exposure_name and tf.exposure_type = e.exposure_type
		LEFT JOIN edw_core.tpolicy tp ON tp.policy_sk = tc.policy_sk
		LEFT JOIN edw_core.tbroker tb ON tb.broker_id = tp.broker_id
		LEFT JOIN edw_core.tcustomer tcu ON tcu.customer_id = tp.customer_id
		LEFT JOIN edw_core.tdate as td1 ON td1.actual_dt = CAST(res.created_at AS DATE)
		LEFT JOIN edw_core.tclaim_cost_category as tcc on tcc.claim_cost_category_nm = res.cost_category
		LEFT JOIN edw_core.tproduct tpr
		ON tpr.product_cd = (CASE 
								WHEN c.claim_type = 'auto' THEN 'AU' 
								WHEN c.claim_type = 'liability' THEN 'PEL' 
								WHEN c.claim_type = 'property' THEN 'HO' 
								ELSE c.claim_type 
							END)
		WHERE 1=1
			AND fta.code in ('submitted','cancel','stop')
			AND fta.created_at > @last_source_extract_ts
		;

		
		SELECT 
			a.claim_sk,
			a.claim_feature_sk,
			a.product_sk,
			a.policy_sk,
			a.broker_sk,
			a.customer_sk,
			a.transaction_dt_sk,
			a.transaction_ts,
			a.claim_payment_sk,
			a.claim_transaction_type_sk,
			a.feature_status_sk,
			a.loss_reserve_amt,
			a.expense_reserve_amt,
			a.subrogation_recovery_reserve_amt,
			a.salvage_recovery_reserve_amt,
			a.salvage_recovery_expense_reserve_amt,
			a.subrogation_recovery_expense_reserve_amt,
			b.loss_paid_amt,
			b.expense_paid_amt,
			b.subrogation_recovery_amt,
			b.salvage_recovery_amt,
			b.salvage_expense_recovery_amt,
			b.subrogation_expense_recovery_amt,
			a.source_system_sk,
			a.created_at,
			a.claim_cost_category_sk,
			a.defense_reserve_amt,
			a.deductible_recovery_reserve_amt,
			a.reinsurance_recovery_reserve_amt,
			a.overpayment_recovery_reserve_amt,
			a.deductible_recovery_expense_reserve_amt,
			a.reinsurance_recovery_expense_reserve_amt,
			a.overpayment_recovery_expense_reserve_amt,
			a.subrogation_recovery_defense_reserve_amt,
			a.salvage_recovery_defense_reserve_amt,
			a.deductible_recovery_defense_reserve_amt,
			a.reinsurance_recovery_defense_reserve_amt,
			a.overpayment_recovery_defense_reserve_amt,
			b.defense_paid_amt,
			b.deductible_recovery_amt,
			b.reinsurance_recovery_amt,
			b.overpayment_recovery_amt,
			b.deductible_expense_recovery_amt,
			b.reinsurance_expense_recovery_amt,
			b.overpayment_expense_recovery_amt,
			b.subrogation_defense_recovery_amt,
			b.salvage_defense_recovery_amt,
			b.deductible_defense_recovery_amt,
			b.reinsurance_defense_recovery_amt,
			b.overpayment_defense_recovery_amt
		INTO edw_temp.tclaim_transaction_snapsheet_temp4
		FROM edw_temp.tclaim_transaction_snapsheet_temp2 a
		LEFT JOIN edw_temp.tclaim_transaction_snapsheet_temp3 b
			ON a.claim_sk = b.claim_sk
			AND a.product_sk = b.product_sk
			AND a.exposure_name = b.exposure_name
			AND a.transaction_ts = b.transaction_ts
			AND a.financial_transaction_id = b.financial_transaction_id
			AND a.cost_type = b.cost_type
			AND a.exposure_id = b.exposure_id
			AND a.cost_category = b.cost_category
		;


	-- Start Insert process
		INSERT INTO edw_core.tclaim_transaction
		(
			claim_sk,
			claim_feature_sk,
			product_sk,
			policy_sk,
			broker_sk,
			customer_sk,
			transaction_dt_sk,
			transaction_ts,
			claim_payment_sk,
			claim_transaction_type_sk,
			feature_status_sk,
			loss_reserve_amt,
			expense_reserve_amt,
			subrogation_recovery_reserve_amt,
			salvage_recovery_reserve_amt,
			salvage_recovery_expense_reserve_amt,
			subrogation_recovery_expense_reserve_amt,
			loss_paid_amt,
			expense_paid_amt,
			subrogation_recovery_amt,
			salvage_recovery_amt,
			salvage_expense_recovery_amt,
			subrogation_expense_recovery_amt,
			source_system_sk,
			create_ts,
			update_ts,
			etl_audit_sk,
			claim_cost_category_sk,
			defense_reserve_amt,
			deductible_recovery_reserve_amt,
			reinsurance_recovery_reserve_amt,
			overpayment_recovery_reserve_amt,
			deductible_recovery_expense_reserve_amt,
			reinsurance_recovery_expense_reserve_amt,
			overpayment_recovery_expense_reserve_amt,
			subrogation_recovery_defense_reserve_amt,
			salvage_recovery_defense_reserve_amt,
			deductible_recovery_defense_reserve_amt,
			reinsurance_recovery_defense_reserve_amt,
			overpayment_recovery_defense_reserve_amt,
			defense_paid_amt,
			deductible_recovery_amt,
			reinsurance_recovery_amt,
			overpayment_recovery_amt,
			deductible_expense_recovery_amt,
			reinsurance_expense_recovery_amt,
			overpayment_expense_recovery_amt,
			subrogation_defense_recovery_amt,
			salvage_defense_recovery_amt,
			deductible_defense_recovery_amt,
			reinsurance_defense_recovery_amt,
			overpayment_defense_recovery_amt
		)
		SELECT 
			claim_sk,
			claim_feature_sk,
			product_sk,
			policy_sk,
			broker_sk,
			customer_sk,
			transaction_dt_sk,
			transaction_ts,
			claim_payment_sk,
			claim_transaction_type_sk,
			feature_status_sk,
			ISNULL(loss_reserve_amt,0) AS loss_reserve_amt,
			ISNULL(expense_reserve_amt,0) AS expense_reserve_amt,
			ISNULL(subrogation_recovery_reserve_amt,0) AS subrogation_recovery_reserve_amt,
			ISNULL(salvage_recovery_reserve_amt,0) AS salvage_recovery_reserve_amt,
			ISNULL(salvage_recovery_expense_reserve_amt,0) AS salvage_recovery_expense_reserve_amt,
			ISNULL(subrogation_recovery_expense_reserve_amt,0) AS subrogation_recovery_expense_reserve_amt,
			ISNULL(loss_paid_amt,0) AS loss_paid_amt,
			ISNULL(expense_paid_amt,0) AS expense_paid_amt,
			ISNULL(subrogation_recovery_amt,0) AS subrogation_recovery_amt,
			ISNULL(salvage_recovery_amt,0) AS salvage_recovery_amt,
			ISNULL(salvage_expense_recovery_amt,0) AS salvage_expense_recovery_amt,
			ISNULL(subrogation_expense_recovery_amt,0) AS subrogation_expense_recovery_amt,
			source_system_sk,
			GETDATE() AS create_ts,
			GETDATE() AS update_ts,
			@etl_audit_sk AS etl_audit_sk,
			claim_cost_category_sk,
			ISNULL(defense_reserve_amt,0) AS defense_reserve_amt,
			ISNULL(deductible_recovery_reserve_amt,0) AS deductible_recovery_reserve_amt,
			ISNULL(reinsurance_recovery_reserve_amt,0) AS reinsurance_recovery_reserve_amt,
			ISNULL(overpayment_recovery_reserve_amt,0) AS overpayment_recovery_reserve_amt,
			ISNULL(deductible_recovery_expense_reserve_amt,0) AS deductible_recovery_expense_reserve_amt,
			ISNULL(reinsurance_recovery_expense_reserve_amt,0) AS reinsurance_recovery_expense_reserve_amt,
			ISNULL(overpayment_recovery_expense_reserve_amt,0) AS overpayment_recovery_expense_reserve_amt,
			ISNULL(subrogation_recovery_defense_reserve_amt,0) AS subrogation_recovery_defense_reserve_amt,
			ISNULL(salvage_recovery_defense_reserve_amt,0) AS salvage_recovery_defense_reserve_amt,
			ISNULL(deductible_recovery_defense_reserve_amt,0) AS deductible_recovery_defense_reserve_amt,
			ISNULL(reinsurance_recovery_defense_reserve_amt,0) AS reinsurance_recovery_defense_reserve_amt,
			ISNULL(overpayment_recovery_defense_reserve_amt,0) AS overpayment_recovery_defense_reserve_amt,
			ISNULL(defense_paid_amt,0) AS defense_paid_amt,
			ISNULL(deductible_recovery_amt,0) AS deductible_recovery_amt,
			ISNULL(reinsurance_recovery_amt,0) AS reinsurance_recovery_amt,
			ISNULL(overpayment_recovery_amt,0) AS overpayment_recovery_amt,
			ISNULL(deductible_expense_recovery_amt,0) AS deductible_expense_recovery_amt,
			ISNULL(reinsurance_expense_recovery_amt,0) AS reinsurance_expense_recovery_amt,
			ISNULL(overpayment_expense_recovery_amt,0) AS overpayment_expense_recovery_amt,
			ISNULL(subrogation_defense_recovery_amt,0) AS subrogation_defense_recovery_amt,
			ISNULL(salvage_defense_recovery_amt,0) AS salvage_defense_recovery_amt,
			ISNULL(deductible_defense_recovery_amt,0) AS deductible_defense_recovery_amt,
			ISNULL(reinsurance_defense_recovery_amt,0) AS reinsurance_defense_recovery_amt,
			ISNULL(overpayment_defense_recovery_amt,0) AS overpayment_defense_recovery_amt
		FROM edw_temp.tclaim_transaction_snapsheet_temp4;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(created_at) FROM edw_temp.tclaim_transaction_snapsheet_temp4),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp1;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp2;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp3;
		DROP TABLE IF EXISTS edw_temp.tclaim_transaction_snapsheet_temp4;

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
