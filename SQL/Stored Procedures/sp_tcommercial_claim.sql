-- =================================================================================================
-- Author:		Hernando Gonzalez
-- Create Date: 07/17/2025
-- Description: This procedures inserts and updates claim data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 07/17/2025	Hernando Gonzalez			1. Created this procedure
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_claim]

AS	
BEGIN
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

		DROP TABLE IF exists edw_temp.tcommercial_claim_temp1;
		DROP TABLE IF exists edw_temp.tcommercial_claim_temp2;

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
		INTO edw_temp.tcommercial_claim_temp2
		FROM edw_stage_snapsheet.custom_field_claims_enumeration_values a
		INNER JOIN edw_stage_snapsheet.custom_field_claims b
		ON a.custom_field_claims_id = b.id
		;		
		
		SELECT
		claim_number as claim_no, CAST(loss_dt AS DATE) AS loss_dt, CAST(report_dt AS DATE) AS report_dt, policy_no , effective_dt AS policy_effective_dt, 
		policy_sk,cause_of_loss_sk,loss_desc, source_claim_status,claim_status, product_sk,
		broker_id,customer_id,underwriting_company_nm,
		contact_nm,contact_type,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt,
		claim_created_ts,claim_created_by_nm,policy_history_sk,claim_reject_reason_desc,
		source_system_sk,update_time
		,fault_decision,
		coverage_confirmed_ts,coverage_confirmed_by_nm,coverage_confirmed_in,
		litigation_in,litigation_complete_in
		INTO edw_temp.tcommercial_claim_temp1
		FROM
		(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY c.claim_number ORDER BY c.claim_number) as rn,
			CASE WHEN c.policy_number LIKE 'NFP%'  then nfp.effective_dt else tp.effective_dt end as effective_dt,
			tp.broker_id,
			tp.customer_id,
			c.claim_number, 
			c.datetime_of_loss AS loss_dt, 
			c.datetime_of_notification AS report_dt, 
			c.policy_number as policy_no, 
			tp.policy_sk,
			cl.cause_of_loss_sk,
			case
				when c.claim_source = 'api' then c.incident_location_description
				else cid.facts_of_loss
			end AS loss_desc,		
			UPPER(c.status) AS source_claim_status,
			UPPER(CASE 
				WHEN c.status IN('DRAFT','OPEN') 
				THEN 'Open' 
				else 'Closed' 
			END) AS claim_status,
			CASE WHEN c.policy_number LIKE 'NFP%' THEN 4 ELSE pr.product_sk END as product_sk,
			CASE
					WHEN c.account_code='vault_reciprocal_exchange' THEN 'VRE'
					WHEN c.account_code='vault_es_insurance_company' THEN 'VES'
					WHEN tp.uw_company_nm like '%litigation%' then tp.uw_company_nm
			ELSE '' END AS underwriting_company_nm,
			CONCAT(	'',
					TRIM(cp.first_name), 
					CASE WHEN TRIM(ISNULL(cp.first_name,''))='' THEN '' ELSE '' END,
					TRIM(ISNULL(cp.last_name,''))
			) AS contact_nm,
			cp.relation_to_insured AS contact_type,
			cpcmp.value as contact_phone,
			CASE WHEN TRIM(cpcme.value)='' THEN NULL ELSE cpcme.value END AS contact_person_email,
			c.updated_at AS update_time,
			c.first_closed_at as claim_first_closed_dt,
			CASE WHEN c.first_opened_at!=c.opened_at THEN c.opened_at END AS claim_first_reopen_dt,			
			c.created_at AS claim_created_ts,
			c.creator_user_name AS claim_created_by_nm,
			tph.policy_history_sk,
			NULL AS claim_reject_reason_desc,
			la.fault_decision
			,covc.updated_at as coverage_confirmed_ts
			,u.name as coverage_confirmed_by_nm
			,case
				when covc.status = 'true' then 'Yes' 
				when covc.[status] = 'false' then 'No'
			end as  coverage_confirmed_in
			,case
				when c.claim_source = 'api' then 3
				else 5
			end as source_system_sk
			, case
					when c.in_litigation = 'true' then 'Yes'
					when c.in_litigation = 'false' then 'No'
			end as [litigation_in]
			, case
					when c.litigation_complete = 'true' then 'Yes'
					when c.litigation_complete = 'false' then 'No'
			end as [litigation_complete_in]
		FROM edw_stage_snapsheet.claims c
		LEFT JOIN edw_stage_snapsheet.claim_parties cp on c.notifier_claim_party_id = cp.id
		LEFT JOIN edw_stage_snapsheet.claim_party_contact_methods cpcmp on c.notifier_claim_party_id = cpcmp.claim_party_id and  cpcmp.contact_method_type = 'phone'
		LEFT JOIN edw_stage_snapsheet.claim_party_contact_methods cpcme on c.notifier_claim_party_id = cpcme.claim_party_id and  cpcme.contact_method_type = 'email'
		LEFT JOIN edw_stage_snapsheet.vehicles v on v.claim_id = c.id 
		LEFT JOIN edw_stage_snapsheet.claim_parties cpd on v.driver_claim_party_id = cpd.id
		LEFT JOIN edw_stage_snapsheet.property_incident_detail_fire_damages pidfd on c.id = pidfd.claim_id
		LEFT JOIN edw_stage_snapsheet.property_incident_detail_water_damages pidwd on c.id = pidwd.claim_id
		LEFT JOIN edw_stage_snapsheet.liability_assignments la on la.claim_id = c.id
		LEFT JOIN edw_stage_snapsheet.liability_determinations ld on ld.claim_id = c.id
		LEFT JOIN edw_core.tpolicy tp on TRIM(c.policy_number) = tp.policy_no												
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
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = tp.product_cd
		LEFT JOIN edw_temp.tcommercial_claim_temp2 cc ON cc.claim_id = c.id
		LEFT JOIN edw_core.tcatastrophe cat ON cc.catastrophe_cd = cat.catastrophe_cd
		LEFT JOIN edw_core.tcause_of_loss cl ON cl.cause_of_loss_desc = c.loss_type
		LEFT JOIN edw_stage_snapsheet.common_incident_details cid on cid.claim_id = c.id
		LEFT JOIN edw_stage_snapsheet.coverage_checks covc on c.id = covc.claim_id
		LEFT JOIN  edw_stage_snapsheet.users u on covc.determined_by_user_id = u.id
		LEFT JOIN
		(
			select ROW_NUMBER()OVER(partition by policy_no, insured_cert_no order by transaction_date desc, reporting_month desc) as transaction_seq_no,
			insured_cert_no as policy_no,effective_date as effective_dt
			from edw_stage.nfp_policy	
		) nfp on nfp.policy_no = c.policy_number and nfp.transaction_seq_no = 1
		WHERE greatest(c.created_at,c.updated_at) > @last_source_extract_ts
		and exists
			(
				select 1
				from
					edw_stage_snapsheet.tags ctg
				where
					ctg.claim_id = c.id
					and ctg.[name] like 'Commercial%'
			)
	) AS t
	WHERE
		rn=1
		
	MERGE edw_core.tclaim AS Target
	USING edw_temp.tcommercial_claim_temp1 AS Source
	ON Source.claim_no=Target.claim_no
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT (
			claim_no,loss_dt,report_dt,policy_no
			,policy_effective_dt,policy_sk,cause_of_loss_sk,loss_desc,claim_status
			,source_claim_status,product_sk,underwriting_company_nm,broker_id,customer_id,contact_nm,contact_type
			,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt
			,claim_created_ts,claim_created_by_nm,policy_history_sk,claim_reject_reason_desc
			,source_system_sk,create_ts,update_ts,etl_audit_sk
			,fault_decision,
			coverage_confirmed_ts,coverage_confirmed_by_nm,coverage_confirmed_in,
			litigation_in,litigation_complete_in
		)
	VALUES
		(
		claim_no,loss_dt,report_dt,policy_no
		,policy_effective_dt,policy_sk,cause_of_loss_sk,loss_desc,claim_status
		,source_claim_status,product_sk,underwriting_company_nm,broker_id,customer_id,contact_nm,contact_type
		,contact_phone,contact_person_email,claim_first_closed_dt,claim_first_reopen_dt,claim_created_ts ,claim_created_by_nm
		,policy_history_sk,claim_reject_reason_desc
		,source_system_sk,@current_date,@current_date,@etl_audit_sk
		,fault_decision,
		coverage_confirmed_ts,coverage_confirmed_by_nm,coverage_confirmed_in,
		litigation_in,litigation_complete_in
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
		Target.product_sk=Source.product_sk,
		Target.broker_id=Source.broker_id,
		Target.customer_id=Source.customer_id,
		Target.underwriting_company_nm=Source.underwriting_company_nm,
		Target.contact_nm=Source.contact_nm,
		Target.contact_type=Source.contact_type,
		Target.contact_phone=Source.contact_phone,
		Target.contact_person_email=Source.contact_person_email,
		Target.policy_history_sk=Source.policy_history_sk,
		Target.claim_first_closed_dt=Source.claim_first_closed_dt,
		Target.claim_first_reopen_dt= case when Target.claim_first_reopen_dt is null then  Source.claim_first_reopen_dt else Target.claim_first_reopen_dt end,
		Target.claim_created_ts=Source.claim_created_ts,
		Target.claim_created_by_nm=Source.claim_created_by_nm,
		Target.update_ts=@current_date,
		Target.claim_reject_reason_desc=Source.claim_reject_reason_desc,
		Target.fault_decision=Source.fault_decision
		,Target.coverage_confirmed_ts=Source.coverage_confirmed_ts
		,Target.coverage_confirmed_by_nm=Source.coverage_confirmed_by_nm
		,Target.coverage_confirmed_in= Source.coverage_confirmed_in
		,Target.litigation_in = Source.litigation_in
		,Target.litigation_complete_in= Source.litigation_complete_in
		;
		
		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(claim_created_ts,update_time)) FROM edw_temp.tcommercial_claim_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_claim_temp1;
		DROP TABLE IF exists edw_temp.tcommercial_claim_temp2;
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