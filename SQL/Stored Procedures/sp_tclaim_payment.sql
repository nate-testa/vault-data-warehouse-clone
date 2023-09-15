/****** Object:  StoredProcedure [edw_core].[sp_tclaim_payment]    Script Date: 15-09-2023 20:41:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts and updates claim payment data

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_payment]

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
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF exists edw_temp.tclaim_payment_temp1

		SELECT
		tcase.claim_no,tc.claim_sk,tf.claim_feature_sk,settle_item.settle_item_id AS payment_sequence_no,
		settle_payee.payment_status AS payment_status,settle.settlement_no AS payment_no,
		settle.claim_type AS claim_type_cd,settle_payee.settle_payee_id,settle_payee.payee_id,
		settle_payee.payee_name AS payee_nm,party_role.role_name AS party_role_nm,
		ISNULL(settle_item.settle_amount,0) AS paid_amt,settle_payee.address AS payee_address,
		settle_payee.remark AS remark,
		-- we don't have these fields so inserting null here.
		ISNULL(tpu3.REAL_NAME,tpu.REAL_NAME) AS payment_submitter_nm,ISNULL(tpu1.REAL_NAME,tpu2.REAL_NAME) AS payment_approver_nm,
		ISNULL(CAST(settle.submit_date AS DATE),CAST(settle_payee.INSERT_TIME AS DATE)) AS payment_submitted_dt,
		ISNULL(CAST(settle.approve_date AS DATE),CAST(settle_payee.UPDATE_TIME AS DATE)) AS payment_approver_dt,
		-- DATE(settle_payee.INSERT_TIME) AS payment_submitted_dt, DATE(settle_payee.UPDATE_TIME) AS payment_approver_dt,
		(CASE WHEN settle.claim_type = 'LOS' THEN 'Payment' ELSE 'Recovery' END) AS payment_category_nm,
		(CASE WHEN settle_item.pay_final = 4 THEN 'Final' ELSE 'Partial' END) AS partial_final_payment_desc,
		3 AS source_system_sk
		INTO edw_temp.tclaim_payment_temp1
		FROM
			edw_stage.t_clm_settle_item AS settle_item
			LEFT JOIN edw_stage.t_clm_settle_payee AS settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id
			LEFT JOIN edw_stage.t_clm_settle AS settle ON settle.settle_id = settle_payee.settle_id
			LEFT JOIN edw_stage.t_clm_party AS party ON settle.case_id = party.case_id AND party.party_id = settle_payee.payee_id
			LEFT JOIN edw_stage.t_clm_party_role AS party_role ON party.party_role = party_role.role_code
			LEFT JOIN edw_stage.t_clm_item AS item ON settle_item.item_id = item.item_id
			LEFT JOIN edw_stage.t_clm_object AS obj ON obj.object_id = item.object_id
			INNER JOIN edw_stage.t_clm_case tcase ON tcase.case_id=obj.case_id
			INNER JOIN edw_core.tclaim tc ON tc.claim_no=tcase.claim_no
			INNER JOIN edw_core.tclaim_feature tf ON tf.claim_no=tc.claim_no AND tf.subclaim_seq_no = obj.seq_no 
				AND tf.claim_coverage_cd = item.coverage_code
			LEFT JOIN edw_stage.t_pub_user tpu ON settle.INSERT_BY = tpu.[USER_ID]
			LEFT JOIN edw_stage.t_pub_user tpu3 ON settle.SUBMITTER = tpu3.[USER_ID]
			LEFT JOIN edw_stage.t_pub_user tpu1 ON settle.approver = tpu1.[USER_ID]
			LEFT JOIN edw_stage.t_pub_user tpu2 ON settle.UPDATE_BY = tpu2.[USER_ID]
		WHERE
				settle.settlement_no IS NOT NULL AND
				settle_item.update_time > @last_source_extract_ts;

		MERGE edw_core.tclaim_payment  AS Target
		USING edw_temp.tclaim_payment_temp1 AS Source
		ON 
		Source.claim_feature_sk=Target.claim_feature_sk AND 
		Source.payment_no=Target.payment_no AND 
		Source.payment_sequence_no=Target.payment_sequence_no
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
					claim_no,claim_sk,claim_feature_sk,payment_sequence_no,payment_no,payment_status,
					claim_type_cd,settle_payee_id,payee_id,payee_nm,party_role_nm,paid_amt,payee_address,
					remark,payment_submitter_nm,payment_approver_nm,payment_submitted_dt,payment_approver_dt,
					payment_category_nm,partial_final_payment_desc,source_system_sk,create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
					claim_no,claim_sk,claim_feature_sk,payment_sequence_no,payment_no,payment_status,
					claim_type_cd,settle_payee_id,payee_id,payee_nm,party_role_nm,paid_amt,payee_address,
					remark,payment_submitter_nm,payment_approver_nm,payment_submitted_dt,payment_approver_dt,
					payment_category_nm,partial_final_payment_desc,3,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.payment_status=Source.payment_status,
		Target.claim_type_cd=Source.claim_type_cd,
		Target.settle_payee_id=Source.settle_payee_id,
		Target.payee_id=Source.payee_id,
		Target.payee_nm=Source.payee_nm,
		Target.party_role_nm=Source.party_role_nm,
		Target.paid_amt=Source.paid_amt,
		Target.payee_address=Source.payee_address,
		Target.remark=Source.remark,
		Target.payment_submitter_nm=Source.payment_submitter_nm,
		Target.payment_approver_nm=Source.payment_approver_nm,
		Target.payment_submitted_dt=Source.payment_submitted_dt,
		Target.payment_approver_dt=Source.payment_approver_dt,
		Target.payment_category_nm=Source.payment_category_nm,
		Target.partial_final_payment_desc=Source.partial_final_payment_desc,
		Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(payment_approver_dt) FROM edw_temp.tclaim_payment_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message
	END CATCH
END
