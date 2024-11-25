SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ========================================================================================================
-- Description: This procedures inserts tclaim_feature snapsheet data
-----------------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/21/2024		Yunus Mohammd				1. Created this procedure
-- 11/20/2024		Alberto Almario				2. Changes on some columns and tables
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_feature_snapsheet]
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

		DROP TABLE IF EXISTS edw_temp.tclaim_feature_snapsheet_temp1;

		SELECT
			tcl.claim_sk,tcl.claim_no,exps.exposure_type,exps.exposure_name,
			-- exps.coverage_premium_class as claim_coverage_cd,
			exps.id as claim_coverage_cd,
			exps.coverage_name as claim_coverage_desc,
			exps.claimant_name as claimant_nm,		
			case
				when veh.potential_total_loss = 'true' then 'Y' 
				when prd.product_cd = 'AU' then 'N'
				else NULL
			end AS total_loss_in,
			prd.product_sk,
			exps.[status] AS claim_feature_status,
			null as aslob_sk, 
			exps.[user_name] AS claim_adjuster_nm,
			CASE
				prd.product_cd
				WHEN 'HO' THEN thcov.home_location_sk
				WHEN 'LUX' THEN tccov.collection_location_sk
				WHEN 'PEL' THEN NULL
				WHEN 'AU' THEN taveh.auto_vehicle_sk
			END AS item_sk,
			CASE
				prd.product_cd
				WHEN 'HO' THEN thcov.home_coverage_sk
				WHEN 'LUX' THEN tccov.collection_coverage_sk
				WHEN 'PEL' THEN tpcov.pel_coverage_sk
				WHEN 'AU' THEN tacov.auto_policy_coverage_sk
			END AS coverage_sk ,		
			5 AS source_system_sk,		
			CASE
				prd.product_cd
				WHEN 'HO' THEN NULL
				WHEN 'LUX' THEN NULL
				WHEN 'PEL' THEN NULL
				WHEN 'AU' THEN tavc.auto_vehicle_coverage_sk
			END AS vehicle_coverage_sk,
			greatest(exps.created_at,exps.updated_at) AS greatest_created_updated
		INTO edw_temp.tclaim_feature_snapsheet_temp1
		FROM edw_stage_snapsheet.claims clm
		INNER JOIN edw_core.tclaim tcl ON clm.claim_number = tcl.claim_no
		INNER JOIN edw_stage_snapsheet.exposures exps on exps.claim_id = clm.id
		LEFT JOIN edw_stage_snapsheet.vehicles veh on veh.claim_id = exps.claim_id and veh.exposure_id = exps.id
		LEFT JOIN edw_core.tproduct prd ON prd.product_sk = tcl.product_sk
		-- Home Coverage
		LEFT JOIN edw_core.thome_coverage thcov ON
		thcov.home_coverage_sk = (
								SELECT TOP 1 home_coverage_sk
								FROM
									edw_core.thome_coverage tcov1
								WHERE
									tcov1.policy_no = tcl.policy_no
									AND tcl.loss_dt >= tcov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
							)
		-- Collection Coverage
		LEFT JOIN edw_core.tcollection_coverage tccov ON
		tccov.collection_coverage_sk= (
								SELECT TOP 1 collection_coverage_sk
								FROM
									edw_core.tcollection_coverage tccov1
								WHERE
									tccov1.policy_no = tcl.policy_no
									AND tcl.loss_dt > =tccov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
							)
		-- PEL Coverage
		LEFT JOIN edw_core.tpel_coverage tpcov ON
		tpcov.pel_coverage_sk = (
								SELECT TOP 1 pel_coverage_sk
								FROM
									edw_core.tpel_coverage tpcov1
								WHERE
									tpcov1.policy_no = tcl.policy_no
									AND tcl.loss_dt > =tpcov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
							)
		-- Auto Coverage
		LEFT JOIN edw_core.tauto_policy_coverage tacov ON
		tacov.auto_policy_coverage_sk = (
								SELECT TOP 1 auto_policy_coverage_sk
								FROM
									edw_core.tauto_policy_coverage tacov1
								WHERE
									tacov1.policy_no = tcl.policy_no
									AND tcl.loss_dt >= tacov1.transaction_effective_dt
								ORDER BY transaction_seq_no DESC
							)
		-- Auto Vehicle
		LEFT JOIN edw_core.tauto_vehicle taveh ON 
		taveh.policy_no = tcl.policy_no AND taveh.vehicle_vin = CAST(veh.vin_number AS VARCHAR(MAX))	AND
		taveh.auto_vehicle_sk = (
									SELECT TOP 1 auto_vehicle_sk
									FROM
										edw_core.tauto_vehicle aveh1
									WHERE
										aveh1.policy_no = taveh.policy_no
										AND aveh1.vehicle_vin =  CAST(veh.vin_number AS VARCHAR(MAX))
										AND tcl.loss_dt > = aveh1.effective_dt
									ORDER BY aveh1.effective_dt DESC
								)
		-- Auto Vehicle Coverage
		LEFT JOIN edw_core.tauto_vehicle_coverage tavc ON tavc.policy_no = tcl.policy_no and tavc.vehicle_no = taveh.vehicle_no
		AND
		tavc.auto_vehicle_coverage_sk= (
										SELECT TOP 1 auto_vehicle_coverage_sk
										FROM
										edw_core.tauto_vehicle_coverage tavc1
										WHERE
											tavc1.policy_no = tcl.policy_no
											AND tavc1.vehicle_no = taveh.vehicle_no
											AND tcl.loss_dt > = tavc1.transaction_effective_dt
										ORDER BY tavc1.transaction_seq_no DESC
								)
		WHERE greatest(exps.created_at,exps.updated_at) > @last_source_extract_ts;   
		

		
		MERGE edw_core.tclaim_feature AS Target
		USING edw_temp.tclaim_feature_snapsheet_temp1 AS Source
		ON cast(Source.claim_coverage_cd as varchar(255)) = Target.claim_coverage_cd
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				claim_sk,claim_no,exposure_type,exposure_name,claim_coverage_cd,claim_coverage_desc,
				claimant_nm,total_loss_in,
				product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,
				coverage_sk,item_sk,vehicle_coverage_sk,
				source_system_sk,create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
			claim_sk,claim_no,exposure_type,exposure_name,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,total_loss_in,
			product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,
			coverage_sk,item_sk,vehicle_coverage_sk,		
			source_system_sk,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET		
			Target.claim_coverage_desc = source.claim_coverage_desc,
			Target.claimant_nm=Source.claimant_nm,
			Target.total_loss_in=Source.total_loss_in,
			Target.product_sk=Source.product_sk,
			Target.claim_feature_status=Source.claim_feature_status,
			Target.aslob_sk=Source.aslob_sk,
			Target.item_sk=Source.item_sk,
			Target.coverage_sk=Source.coverage_sk,
			Target.vehicle_coverage_sk=Source.vehicle_coverage_sk,
			Target.claim_adjuster_nm=Source.claim_adjuster_nm,		
			Target.update_ts=@current_date;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest_created_updated) FROM edw_temp.tclaim_feature_snapsheet_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tclaim_feature_snapsheet_temp1

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
