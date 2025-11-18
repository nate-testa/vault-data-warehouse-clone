-- =================================================================================================
-- Description: This procedures inserts and updates commercial claim payment data
-----------------------------------------------------------------------------------------------------------
-- Change date		 	|	Author								 |	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/18/25				Yunus Mohammed  			1. Created this procedure 
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommerical_claim_payment]

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

		DROP TABLE IF exists edw_temp.tcommercial_claim_payment_temp1

		SELECT	c.claim_number as claim_no,
				tc.commercial_claim_sk,
				tf.commercial_claim_feature_sk,
				fpi.id AS payment_sequence_no,
				ft.stage AS payment_status,
				fpi.financial_transaction_id AS payment_no,
				fpi.cost_type AS claim_type_cd,
				fpi.cost_category,
				case when py.original_sub_type = 'PERSON' then CONCAT_WS(' ',py.first_name,py.last_name)
				else py.organization_name
				end AS payee_nm,
				fpd.party_type AS party_role_nm, 
				ISNULL(fpi.amount,0) AS paid_amt,
				concat( cp.address_address1,', ',
						cp.address_address2,', ', 
						cp.address_city,', ', 
						cp.address_region,', ', 
						cp.address_postal_code,', ', 
						cp.address_country
				) AS payee_address,
				fpi.note_body AS remark, 
				u.name AS payment_submitter_nm,
				case when ftas.Id is null then u.name else apprvu.name end as payment_approver_nm, 
				ft.created_at AS payment_submitted_dt,
				case when ftas.Id is null then ft.approved_at else fta.created_at end AS payment_approver_dt,				
				ft.financial_transaction_type as payment_category_nm,                
				fpi.payment_type as partial_final_payment_desc,
				null as expert_subtype_role, 
                -- TBD - We don't need this?
				CASE
					WHEN ft.is_historical = 'true' THEN 3
					ELSE 5
				END AS source_system_sk,
				ft.created_at,
				ft.updated_at

		INTO edw_temp.tcommercial_claim_payment_temp1 

		FROM
		edw_stage_snapsheet.claims c
		INNER JOIN 	edw_commercial.tclaim tc ON tc.claim_no=c.claim_number
		INNER JOIN 	edw_commercial.tclaim_feature tf ON tf.claim_no = tc.claim_no
		INNER JOIN  edw_stage_snapsheet.exposures e on c.id = e.claim_id and tf.claim_coverage_cd=e.id
		INNER JOIN 	edw_stage_snapsheet.financial_payment_items fpi on fpi.claim_id = c.id and e.id = fpi.exposure_id 
		LEFT JOIN 	edw_stage_snapsheet.financial_payment_details fpd on fpd.claim_id = c.id and fpd.financial_transaction_id = fpi.financial_transaction_id
		LEFT JOIN 	edw_stage_snapsheet.claim_parties cp on fpd.party_id = cp.id
		INNER JOIN 	edw_stage_snapsheet.financial_transactions ft on ft.id = fpi.financial_transaction_id
        LEFT JOIN   edw_stage_snapsheet.financial_transaction_actions fta on ft.id = fta.financial_transaction_id and fta.code='approve'
		LEFT JOIN   edw_stage_snapsheet.financial_transaction_actions ftas on ft.id = ftas.financial_transaction_id and ftas.code='pending_approval'
		LEFT JOIN 	edw_stage_snapsheet.users u on ft.creator_user_id = u.id 
        LEFT JOIN   edw_stage_snapsheet.users apprvu on fta.actor_user_id=apprvu.id
		left join edw_stage_snapsheet.payees py on py.financial_payment_detail_id = fpd.id and py.is_primary = 'true'
		WHERE
			greatest(ft.created_at,ft.updated_at) > @last_source_extract_ts and ft.is_historical='false';   

		MERGE edw_core.tcommercial_payment  AS Target
		USING edw_temp.tcommercial_claim_payment_temp1 AS Source
		ON  Source.commercial_claim_feature_sk=Target.commercial_claim_feature_sk AND 
			Source.payment_no=Target.payment_no AND 
			Source.payment_sequence_no=Target.payment_sequence_no
			AND Source.claim_type_cd=Target.claim_type_cd
			AND Source.cost_category=Target.cost_category
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
					claim_no,commercial_claim_sk,commercial_claim_feature_sk,payment_sequence_no,payment_no,payment_status,
					claim_type_cd,cost_category,payee_nm,party_role_nm,paid_amt,payee_address,
					remark,payment_submitter_nm,payment_approver_nm,payment_submitted_dt,payment_approver_dt,
					payment_category_nm,partial_final_payment_desc,party_subtype_role_nm,source_system_sk,create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
					claim_no,commercial_claim_sk,commercial_claim_feature_sk,payment_sequence_no,payment_no,payment_status,
					claim_type_cd,cost_category,payee_nm,party_role_nm,paid_amt,payee_address,
					remark,payment_submitter_nm,payment_approver_nm,payment_submitted_dt,payment_approver_dt,
					payment_category_nm,partial_final_payment_desc,expert_subtype_role,source_system_sk,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			Target.payment_status=Source.payment_status,
			Target.payment_approver_nm=Source.payment_approver_nm,
			Target.payment_approver_dt=Source.payment_approver_dt,
			Target.update_ts=@current_date;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(created_at,updated_at)) FROM edw_temp.tcommercial_claim_payment_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_claim_payment_temp1
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