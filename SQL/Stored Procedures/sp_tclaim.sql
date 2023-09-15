/****** Object:  StoredProcedure [edw_core].[sp_tclaim]    Script Date: 15-09-2023 20:39:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 07/28/2023
-- Description: This procedures inserts and updates claim data

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim]

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

		DROP TABLE IF exists edw_temp.tclaim_temp1

		SELECT
		claim_no, CAST(loss_dt AS DATE) AS loss_dt, CAST(report_dt AS DATE) AS report_dt, policy_no , effective_dt AS policy_effective_dt, 
		policy_sk,cause_of_loss_sk,loss_desc, source_claim_status,claim_status, catastrophe_sk, product_sk,
		loss_address ,loss_city_nm ,loss_state_cd ,loss_zip_cd,loss_country_nm,broker_sk,customer_sk,underwriting_company_nm,
		contact_nm,contact_type,contact_phone,contact_person_email,
		3 AS source_system_sk,sub_cause_of_loss_sk,update_time
		INTO edw_temp.tclaim_temp1
		FROM
		(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY tcase.claim_no,tph.policy_no ORDER BY tph.transaction_seq_no DESC) AS rn,
			CASE WHEN tph.effective_dt IS NULL THEN CAST(tcp.EFF_DATE AS DATE) ELSE CAST(tph.effective_dt AS DATE) END AS effective_dt,
			tph.broker_sk,
			c.customer_sk,
			tcase.claim_no, tcase.accident_time AS loss_dt, tcase.notice_time AS report_dt, 
			CASE WHEN TRIM(tcase.policy_no) IS NULL THEN tcp.policy_no ELSE TRIM(tcase.policy_no) END AS policy_no,
			tph.policy_sk,
			cl.cause_of_loss_sk,
			tcase.accident_desc AS loss_desc,		
			UPPER(tcasestat.status_name) AS source_claim_status,
			UPPER(CASE 
				WHEN tcasestat.status_code IN('1','2','5') THEN 'Open'
				WHEN tcasestat.status_code IN('3','4','6') THEN 'Closed'
				ELSE tcasestat.status_name
			END) AS claim_status,
			cat.catastrophe_sk AS catastrophe_sk, prd.product_sk,
			CONCAT('',TRIM(tpa.address_line_1),
			CASE WHEN TRIM(ISNULL(tpa.address_line_2,''))='' THEN '' ELSE '' END,
			TRIM(ISNULL(tpa.address_line_2,'')),
			CASE WHEN ISNULL(tpa.address_line_3,'')='' THEN '' ELSE ' ' END,
			TRIM(ISNULL(tpa.address_line_3,''))
			) AS loss_address ,tpa.city AS loss_city_nm ,
		      UPPER(TRIM(tpa.state)) AS loss_state_cd ,tpa.post_code AS loss_zip_cd, 
			tpa.country AS loss_country_nm,
			CASE
					WHEN tcp.organ_id=1000000000002 THEN 'VRE'
					WHEN tcp.organ_id=1000000000001 THEN 'VES'
			ELSE '' END AS underwriting_company_nm,
			tcase.contact_name AS contact_nm,
			CASE
			WHEN tcase.contact_type='1' THEN 'Insured'
			WHEN tcase.contact_type='2' THEN 'Relative'
			WHEN tcase.contact_type='3' THEN 'Friend'
			WHEN tcase.contact_type='4' THEN 'Lawyer'
			WHEN tcase.contact_type='5' THEN 'Driver'
			WHEN tcase.contact_type='6' THEN 'Garage'
			WHEN tcase.contact_type='7' THEN 'Agent/Broker/Their staff'
			WHEN tcase.contact_type='8' THEN 'Third Party'
			WHEN tcase.contact_type='9' THEN 'Road Assistance'
			ELSE
			tcase.contact_type
			END AS contact_type,tcase.contact_phone,
			CASE WHEN TRIM(tcase.contact_person_email)='' THEN NULL ELSE tcase.contact_person_email END AS contact_person_email,
			scl.sub_cause_of_loss_sk,tcase.update_time
		FROM
			edw_stage.t_clm_case tcase
			LEFT JOIN edw_core.tpolicy_history tph ON TRIM(tcase.policy_no) = tph.policy_no
			AND CAST(tph.transaction_effective_dt AS DATE) <= CAST(tcase.accident_time AS DATE)
			LEFT JOIN edw_stage.t_clm_case_status tcasestat ON tcase.CASE_STATUS = tcasestat.STATUS_CODE
			LEFT JOIN edw_core.tcustomer c ON c.customer_sk=tph.customer_sk
			LEFT JOIN edw_core.tcatastrophe cat ON TRIM(tcase.accident_code)=TRIM(cat.catastrophe_cd)
			LEFT JOIN edw_core.tproduct prd ON prd.ebao_product_cd=tcase.product_code
			LEFT JOIN edw_core.tcause_of_loss cl ON cl.cause_of_loss_cd=tcase.loss_cause
			-- returns Accident Address
			LEFT JOIN edw_stage.t_int_address tia ON tia.source_id=tcase.case_id
			LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID=tpa.ADDRESS_ID
			LEFT JOIN edw_stage.t_clm_policy tcp ON tcase.case_id=tcp.case_id
			LEFT JOIN edw_core.tsub_cause_of_loss scl ON tcase.sub_cause_of_loss_code=scl.sub_cause_of_loss_cd 
		WHERE
			tcase.update_time>@last_source_extract_ts
	) AS t
	WHERE
		rn=1

	MERGE edw_core.tclaim  AS Target
	USING edw_temp.tclaim_temp1 AS Source
	ON Source.claim_no=Target.claim_no
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_no,loss_dt,report_dt,policy_no
			,policy_effective_dt,policy_sk,cause_of_loss_sk,sub_cause_of_loss_sk,loss_desc,claim_status
			,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,loss_address,loss_city_nm
			,loss_state_cd,loss_zip_cd,loss_country_nm,broker_id,customer_id,contact_nm,contact_type
			,contact_phone,contact_person_email,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
		claim_no,loss_dt,report_dt,policy_no
		,policy_effective_dt,policy_sk,cause_of_loss_sk,sub_cause_of_loss_sk,loss_desc,claim_status
		,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,loss_address,loss_city_nm
		,loss_state_cd,loss_zip_cd,loss_country_nm,broker_sk,customer_sk,contact_nm,contact_type
		,contact_phone,contact_person_email,source_system_sk,@current_date,@current_date,@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
		Target.loss_dt=Source.loss_dt,
		Target.report_dt=Source.report_dt,
		Target.policy_no=Source.policy_no,
		Target.policy_effective_dt=Source.policy_effective_dt,
		Target.policy_sk=Source.policy_sk,
		Target.cause_of_loss_sk=Source.cause_of_loss_sk,
		Target.loss_desc=Source.loss_desc,
		Target.claim_status=Source.claim_status,
		Target.source_claim_status=Source.source_claim_status,
		Target.catastrophe_sk=Source.catastrophe_sk,
		Target.product_sk=Source.product_sk,
		Target.loss_address=Source.loss_address,
		Target.loss_city_nm=Source.loss_city_nm,
		Target.loss_state_cd=Source.loss_state_cd,
		Target.loss_zip_cd=Source.loss_zip_cd, 
		Target.loss_country_nm=Source.loss_country_nm, 
		Target.broker_id=Source.broker_sk,
		Target.underwriting_company_nm=Source.underwriting_company_nm,
		Target.contact_nm=Source.contact_nm,
		Target.contact_type=Source.contact_type,
		Target.contact_phone=Source.contact_phone,
		Target.contact_person_email=Source.contact_person_email,
		Target.update_ts=@current_date,
		Target.sub_cause_of_loss_sk=Source.sub_cause_of_loss_sk;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_time) FROM edw_temp.tclaim_temp1),@last_source_extract_ts)
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
