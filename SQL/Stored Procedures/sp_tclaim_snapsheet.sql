-- ======================================================================================================== 
-- Description: This procedures inserts and updates claim data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/23/2023		Architha Gudimalla		1. Created this procedure - AD7391
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_snapsheet]

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

		DROP TABLE IF exists edw_temp.tclaim_snapsheet_temp1;
		DROP TABLE IF exists edw_temp.tclaim_snapsheet_temp2;

		SELECT 
			b.claim_id,
			a.option_name,
			LEFT(a.option_name, CHARINDEX('|', a.option_name) - 1) AS catastrophe_cd,
			SUBSTRING(
				a.option_name, 
				CHARINDEX('|', a.option_name) + 1, 
				CHARINDEX('|', a.option_name, CHARINDEX('|', a.option_name) + 1) - CHARINDEX('|', a.option_name) - 1
			) AS catastrophe_nm,
			RIGHT(a.option_name, LEN(a.option_name) - CHARINDEX('|', a.option_name, CHARINDEX('|', a.option_name) + 1)) AS catastrophe_desc
		INTO edw_temp.tclaim_snapsheet_temp2
		FROM edw_stage_snapsheet.custom_field_claims_enumeration_values a
		INNER JOIN edw_stage_snapsheet.custom_field_claims b
		ON a.custom_field_claims_id = b.id
		;
		
		
		SELECT
		claim_number as claim_no, CAST(loss_dt AS DATE) AS loss_dt, CAST(report_dt AS DATE) AS report_dt, policy_no , effective_dt AS policy_effective_dt, 
		policy_sk,cause_of_loss_sk,loss_desc, source_claim_status,claim_status, catastrophe_sk, product_sk,
		loss_address ,loss_city_nm ,loss_state_cd ,loss_zip_cd,loss_country_nm,broker_id,customer_id,underwriting_company_nm,
		contact_nm,contact_type,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt,
		claim_created_ts,claim_created_by_nm,policy_history_sk,claim_reject_reason_desc,
		5 AS source_system_sk,sub_cause_of_loss_sk,update_time
		INTO edw_temp.tclaim_snapsheet_temp1
		FROM
		(
		SELECT
			1 as rn,
			tph.effective_dt, 
			tbrk.broker_id,
			cr.customer_id,
			c.claim_number, 
			c.datetime_of_loss AS loss_dt, 
			c.first_opened_at AS report_dt, 
			c.policy_number as policy_no, 
			tph.policy_sk,
			cl.cause_of_loss_sk,
			c.incident_location_description AS loss_desc,		
			UPPER(c.status) AS source_claim_status,
			UPPER(CASE 
				WHEN c.status IN('DRAFT','OPEN') 
				THEN 'Open' 
				else 'Closed' 
			END) AS claim_status,
			cat.catastrophe_sk, 
			tph.product_sk,
			CONCAT(	'',
					TRIM(c.address_address1), 
					CASE WHEN TRIM(ISNULL(c.address_address1,''))='' THEN '' ELSE '' END,
					TRIM(ISNULL(c.address_address2,''))
			) AS loss_address ,
			c.address_city AS loss_city_nm ,
		    UPPER(TRIM(c.address_region)) AS loss_state_cd ,
			c.address_postal_code AS loss_zip_cd, 
			c.address_country AS loss_country_nm,
			CASE
					WHEN c.account_code='vault_reciprocal_exchange' THEN 'VRE'
					WHEN c.account_code='vault_es_insurance_company' THEN 'VES'
			ELSE '' END AS underwriting_company_nm,
			CONCAT(	'',
					TRIM(cp.first_name), 
					CASE WHEN TRIM(ISNULL(cp.first_name,''))='' THEN '' ELSE '' END,
					TRIM(ISNULL(cp.last_name,''))
			) AS contact_nm,
			cp.relation_to_insured AS contact_type,
			cpcmp.value as contact_phone,
			CASE WHEN TRIM(cpcme.value)='' THEN NULL ELSE cpcme.value END AS contact_person_email,
			NULL as sub_cause_of_loss_sk,
			c.updated_at update_time,
			c.first_closed_at as claim_first_closed_dt,
			CAST(NULL AS DATE) as claim_first_reopen_dt, 
			c.created_at AS claim_created_ts,
			c.creator_user_name AS claim_created_by_nm,
			tph.policy_history_sk,
			NULL AS claim_reject_reason_desc 
		FROM edw_stage_snapsheet.claims c
		LEFT JOIN edw_stage_snapsheet.claim_parties cp on c.notifier_claim_party_id = cp.id
		LEFT JOIN edw_stage_snapsheet.claim_party_contact_methods cpcmp on c.notifier_claim_party_id = cpcmp.claim_party_id and  cpcmp.contact_method_type = 'phone'
		LEFT JOIN edw_stage_snapsheet.claim_party_contact_methods cpcme on c.notifier_claim_party_id = cpcme.claim_party_id and  cpcme.contact_method_type = 'email'
		LEFT JOIN edw_core.tpolicy_history tph ON TRIM(c.policy_number) = tph.policy_no
												AND tph.policy_history_sk = (
																	SELECT TOP 1 policy_history_sk
																	FROM
																		edw_core.tpolicy_history tph1
																	WHERE
																		tph1.policy_no = c.policy_number
																		AND CAST(tph1.transaction_effective_dt AS DATE) <= CAST(c.datetime_of_loss AS DATE)
																	ORDER BY transaction_seq_no DESC
																)
		LEFT JOIN edw_core.tbroker tbrk ON tbrk.broker_sk = tph.broker_sk	
		LEFT JOIN edw_core.tcustomer cr ON cr.customer_sk=tph.customer_sk
		LEFT JOIN edw_temp.tclaim_snapsheet_temp2 cc ON cc.claim_id = c.id
		LEFT JOIN edw_core.tcatastrophe cat ON cc.catastrophe_cd = cat.catastrophe_cd
		LEFT JOIN edw_core.tcause_of_loss cl ON cl.cause_of_loss_desc = c.loss_type
		WHERE greatest(c.created_at,c.updated_at) > @last_source_extract_ts
	) AS t
	WHERE
		rn=1
		
	MERGE edw_core.tclaim AS Target
	USING edw_temp.tclaim_snapsheet_temp1 AS Source
	ON Source.claim_no=Target.claim_no
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_no,loss_dt,report_dt,policy_no
			,policy_effective_dt,policy_sk,cause_of_loss_sk,sub_cause_of_loss_sk,loss_desc,claim_status
			,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,loss_address,loss_city_nm
			,loss_state_cd,loss_zip_cd,loss_country_nm,broker_id,customer_id,contact_nm,contact_type
			,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt,
			claim_created_ts,claim_created_by_nm,policy_history_sk,claim_reject_reason_desc,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		)
	VALUES
		(
		claim_no,loss_dt,report_dt,policy_no
		,policy_effective_dt,policy_sk,cause_of_loss_sk,sub_cause_of_loss_sk,loss_desc,claim_status
		,source_claim_status,catastrophe_sk,product_sk,underwriting_company_nm,loss_address,loss_city_nm
		,loss_state_cd,loss_zip_cd,loss_country_nm,broker_id,customer_id,contact_nm,contact_type
		,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt,claim_created_ts ,claim_created_by_nm,
		policy_history_sk,claim_reject_reason_desc,
		source_system_sk,@current_date,@current_date,@etl_audit_sk
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
		Target.broker_id=Source.broker_id,
		Target.customer_id=Source.customer_id,
		Target.underwriting_company_nm=Source.underwriting_company_nm,
		Target.contact_nm=Source.contact_nm,
		Target.contact_type=Source.contact_type,
		Target.contact_phone=Source.contact_phone,
		Target.contact_person_email=Source.contact_person_email,
		Target.policy_history_sk=Source.policy_history_sk,
		Target.claim_first_closed_dt=Source.claim_first_closed_dt,
		Target.claim_first_reopen_dt=Source.claim_first_reopen_dt,
		Target.claim_created_ts=Source.claim_created_ts,
		Target.claim_created_by_nm=Source.claim_created_by_nm,
		Target.update_ts=@current_date,
		Target.sub_cause_of_loss_sk=Source.sub_cause_of_loss_sk,
		Target.claim_reject_reason_desc=Source.claim_reject_reason_desc;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(update_time) FROM edw_temp.tclaim_snapsheet_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_snapsheet_temp1;
		DROP TABLE IF exists edw_temp.tclaim_snapsheet_temp2;

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