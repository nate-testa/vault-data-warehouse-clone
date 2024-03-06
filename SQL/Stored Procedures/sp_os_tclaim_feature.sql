-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures insert OneShied claim into tclaim table
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/08/23		Yunus Mohammed				1. Created the procedure
-- 12/12/23		Yunus Mohammed				2. Added update stmts for aslob and sub_claim_type_nm
-- 01/30/24		Yunus Mohammed				3. Changed name of temp table for aslob and added drop table stmt
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tclaim_feature]

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

		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_temp1

		SELECT
		tc.claim_sk,tc.claim_no,ttcf.subclaim_type_nm,
		RIGHT('000' + cast(ROW_NUMBER()OVER(PARTITION BY ttcf.claim_no ORDER BY ttcf.claim_sk,ttcf.claim_coverage_cd)as varchar(100)),3) AS subclaim_seq_no,
		claim_coverage_cd,ttcf.claim_coverage_desc,claimant_nm,damage_severity,damage_type,possible_subrogation_in,
		possible_salvage_in,total_loss_in,litigation_in,ttcf.product_sk,ttcf.CASE_STATUS AS claim_feature_status,NULL aslob_sk,
		claim_adjuster_nm,NULL AS risk_item,
		ROUND(ttcf.loss_reserve_amt,2) AS loss_reserve_amt,ROUND(ttcf.expense_reserve_amt,2) AS expense_reserve_amt,
		ROUND(ttcf.adjusting_other_reserve_amt,2) AS adjusting_other_reserve_amt,ROUND(ttcf.subro_reserve_amt,2) AS subro_reserve_amt,
		ROUND(ttcf.salvage_reserve_amt,2) AS salvage_reserve_amt,ROUND(ttcf.salvage_expense_reserve_amt,2) AS salvage_expense_reserve_amt,
		ROUND(ttcf.subro_expense_reserve_amt,2) AS subro_expense_reserve_amt,ROUND(ttcf.loss_paid_amt,2) AS loss_paid_amt,
		ROUND(ttcf.expense_paid_amt,2) AS expense_paid_amt,ROUND(ttcf.adjusting_other_paid_amt,2) AS adjusting_other_paid_amt,
		ROUND(ttcf.subro_recovery_amt,2) AS subro_recovery_amt,ROUND(ttcf.salvage_recovery_amt,2) AS salvage_recovery_amt,
		ROUND(ttcf.salvage_expense_paid_amt,2) AS salvage_expense_paid_amt,ROUND(ttcf.subro_expense_paid_amt,2) AS subro_expense_paid_amt,
		ROUND(ttcf.refund_indemnity_paid_amt,2) AS refund_indemnity_paid_amt,
		ROUND(ttcf.refund_expense_paid_amt,2) AS refund_expense_paid_amt,
		ttcf.source_system_sk
		INTO edw_temp.os_tclaim_feature_temp1
		FROM
		edw_stage.dragon_feature_os ttcf
		INNER JOIN edw_core.tclaim tc ON ttcf.claim_no=tc.claim_no		
		WHERE
		tc.source_system_sk=1


		INSERT INTO edw_core.tclaim_feature
		(
			claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
			subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,
			subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,adjusting_other_paid_amt,
			subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
			refund_indemnity_paid_amt,refund_expense_paid_amt,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT claim_sk,claim_no,subclaim_type_nm,subclaim_seq_no,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,damage_severity,damage_type,possible_subrogation_in,possible_salvage_in,total_loss_in,
			litigation_in,product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,risk_item,
			loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
			subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,
			subro_expense_reserve_amt,loss_paid_amt,expense_paid_amt,adjusting_other_paid_amt,
			subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,subro_expense_paid_amt,
			refund_indemnity_paid_amt,refund_expense_paid_amt,
			source_system_sk,GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tclaim_feature_temp1

		SET @rows_affected=@@ROWCOUNT;

		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Collision',claim_coverage_desc='Collision' WHERE claim_no='CL-1167936751';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-478753011';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-767009506';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Property Damage',claim_coverage_desc='Property Damage' WHERE claim_no='CL-814259127';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-816803818';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-850899681';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Comprehensive',claim_coverage_desc='Comprehensive' WHERE claim_no='CL-896845956';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-898598354';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Comprehensive',claim_coverage_desc='Comprehensive' WHERE claim_no='CL-906169842';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Towing',claim_coverage_desc='Towing' WHERE claim_no in 
		('CL-1047193616','CL-1088687951','CL-1130485401','CL-1161301179','CL-912758938','CL-956048039')		;
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Glass',claim_coverage_desc='Glass' WHERE claim_no='CL-917207093';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Property Damage',claim_coverage_desc='Property Damage' WHERE claim_no='CL-935537010';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-940637022';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-948754869';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Personal Liability',claim_coverage_desc='VT Personal Liability' WHERE claim_no='CL-948759188';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Bodily Injury',claim_coverage_desc='Bodily Injury' WHERE claim_no='CL-950231904';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-951755571';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Towing',claim_coverage_desc='Towing' WHERE claim_no='CL-956048039';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Loss Of Use Limit',claim_coverage_desc='VT Loss Of Use Limit' WHERE claim_no='CL-974402364';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Glass',claim_coverage_desc='Glass' WHERE claim_no='CL-977644349';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Collision',claim_coverage_desc='Collision' WHERE claim_no='CL-983303223';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='Collision',claim_coverage_desc='Collision' WHERE claim_no='CL-987005375';
		UPDATE edw_core.tclaim_feature SET subclaim_type_nm='VT Dwelling Limit',claim_coverage_desc='VT Dwelling Limit' WHERE claim_no='CL-987008324';

		UPDATE edw_core.taslob SET product_cd = 'Auto' WHERE aslob_sk = 93	

		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_aslob_temp2

		SELECT
			tf.claim_feature_sk, ta.aslob_sk
		INTO edw_temp.os_tclaim_feature_aslob_temp2
		FROM
			edw_core.tclaim_feature tf
			LEFT JOIN edw_core.tproduct tp ON tf.product_sk=tp.product_sk
			LEFT JOIN edw_core.taslob ta ON      
			(  
				CASE
				WHEN tf.subclaim_type_nm='VT Dwelling Limit' THEN 'Dwelling'
				WHEN tf.subclaim_type_nm='VT Loss Of Use Limit' THEN 'Loss Of Use'
				WHEN tf.subclaim_type_nm='VT Personal Liability' THEN 'Personal Liability'
				WHEN tf.subclaim_type_nm='VT Contents Limit' THEN 'Contents'
				WHEN tf.subclaim_type_nm='VT Ded Waiver Large Losses' THEN 'Ded Waiver Large Losses'
				WHEN tf.subclaim_type_nm='VT Ensuing Fungi Increase' THEN 'Ensuing Fungi Increase'
				WHEN tf.subclaim_type_nm='VT Final Premium Policy Optional Coverages' THEN 'Dwelling'
				WHEN tf.subclaim_type_nm='VT Home Systems Protection' THEN 'Home Systems Protection'
				WHEN TRIM(tf.subclaim_type_nm)='VT Loss Assessment Increase' THEN 'Market Appreciation'
				WHEN tf.subclaim_type_nm='VT Lux Class Total Blanket' THEN 'Class Total Blanket'
				WHEN tf.subclaim_type_nm='VT Lux Scheduled Property Item' THEN 'Scheduled Property Item'
				WHEN tf.subclaim_type_nm='VT Medical payments' THEN 'Medical Payments'
				WHEN tf.subclaim_type_nm='VT Other Structures Limit' THEN 'Other Structures'
				WHEN tf.subclaim_type_nm='VT Service Line Protection' THEN 'Service Line Protection'
				WHEN tf.subclaim_type_nm='VT Sinkhole Collapse Extension' THEN 'Sinkhole Collapse Extension'
				WHEN tf.subclaim_type_nm='VTL Lux Class Total Blanket' THEN 'Class Total Blanket'
				WHEN tf.subclaim_type_nm='VTL Lux Scheduled Property Item' THEN 'Scheduled Property Item'
				WHEN tf.subclaim_type_nm='Excess Liability Coverage' THEN 'Liability'
				ELSE tf.subclaim_type_nm
				END
			) = ta.coverage_cd  AND tp.product_cd =
				CASE ta.product_cd
					WHEN 'Auto' THEN 'AU'
					WHEN 'Homeowners' THEN 'HO'
					WHEN 'Collections' THEN 'LUX'
					WHEN 'Excess Liability' THEN 'PEL'
				END
		WHERE tf.source_system_sk = 1

		UPDATE tcf
		SET
			tcf.aslob_sk = src.aslob_sk
		FROM
			edw_core.tclaim_feature tcf
			INNER JOIN edw_temp.os_tclaim_feature_aslob_temp2 src ON tcf.claim_feature_sk = src.claim_feature_sk		

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_temp1
		DROP TABLE IF EXISTS edw_temp.os_tclaim_feature_aslob_temp2
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