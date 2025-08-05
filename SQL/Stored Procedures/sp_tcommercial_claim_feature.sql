-- =================================================================================================
-- Author:		Hernando Gonzalez
-- Create Date: 07/17/2025
-- Description: This procedures inserts and updates claim feature data
-----------------------------------------------------------------------------------------------------------
-- Change date 		  |Author						           |	Change Description
-----------------------------------------------------------------------------------------------------------
-- 07/17/2025		Hernando Gonzalez			1. Created this procedure
-- 08/05/2025		Yunus Mohammed			   2. Remove case statement from product_cd 
-- ========================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_claim_feature]

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

		DROP TABLE IF EXISTS edw_temp.sp_tcommercial_claim_feature_temp1;

		SELECT
			tcl.commercial_claim_sk,tcl.claim_no,exps.exposure_type,exps.exposure_name,
			-- exps.coverage_premium_class as claim_coverage_cd,
			exps.id as claim_coverage_cd,
						case
						when exps.coverage_name is not null then exps.coverage_name
						when  exists
							(
								SELECT distinct snapsheet_coverage_nm FROM edw_stage.migration_coverage_mapping mcm 
								where mcm.snapsheet_coverage_cd = exps.coverage_premium_class
								and mcm.product_cd = prd.product_cd
							) then		
							(
								SELECT distinct snapsheet_coverage_nm FROM edw_stage.migration_coverage_mapping mcm 
								where mcm.snapsheet_coverage_cd = exps.coverage_premium_class
								and mcm.product_cd = prd.product_cd
							) 
				end as claim_coverage_desc,
			exps.claimant_name as claimant_nm,		
			prd.product_sk,
			exps.[status] AS claim_feature_status,
			asl.aslob_sk,
			exps.[user_name] AS claim_adjuster_nm,
	
			CASE
				WHEN exps.external_reference_number is not null THEN 3
				ELSE 5
			END AS source_system_sk,		
			greatest(clm.created_at,clm.updated_at) AS greatest_created_updated
		INTO edw_temp.sp_tcommercial_claim_feature_temp1
		FROM edw_stage_snapsheet.claims clm
		INNER JOIN edw_commercial.tcommercial_claim tcl ON clm.claim_number = tcl.claim_no
		INNER JOIN edw_stage_snapsheet.exposures exps on exps.claim_id = clm.id
		LEFT JOIN edw_stage_snapsheet.vehicles veh on veh.claim_id = exps.claim_id and veh.exposure_id = exps.id
		LEFT JOIN edw_core.tproduct prd ON prd.product_sk = tcl.product_sk
		LEFT JOIN 
		(
				select ROW_NUMBER()over(partition by product_cd,coverage_cd order by aslob_cd) as row_no, *
				from edw_core.taslob
		) as asl on asl.row_no = 1 and asl.coverage_cd = 
						case
						when exps.coverage_name is not null then exps.coverage_name
						when  exists
							(
								SELECT distinct snapsheet_coverage_nm FROM edw_stage.migration_coverage_mapping mcm 
								where mcm.snapsheet_coverage_cd = exps.coverage_premium_class
								and mcm.product_cd = prd.product_cd
							) then		
							(
								SELECT distinct snapsheet_coverage_nm FROM edw_stage.migration_coverage_mapping mcm 
								where mcm.snapsheet_coverage_cd = exps.coverage_premium_class
								and mcm.product_cd = prd.product_cd
							) 
				end
		and
			asl.product_cd = prd.product_cd

		WHERE greatest(clm.created_at,clm.updated_at) > @last_source_extract_ts
		and exists
			(
				select 1
				from
					edw_stage_snapsheet.tags ctg
				where
					ctg.claim_id = clm.id
					and ctg.[name] like 'Commercial%'
			)
		;

		MERGE edw_commercial.tcommercial_claim_feature AS Target
		USING edw_temp.sp_tcommercial_claim_feature_temp1 AS Source
		ON cast(Source.claim_coverage_cd as varchar(255)) = Target.claim_coverage_cd
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				commercial_claim_sk,claim_no,exposure_type,exposure_name,claim_coverage_cd,claim_coverage_desc,
				claimant_nm,
				product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,
				source_system_sk,create_ts,update_ts,etl_audit_sk
			)
		VALUES
			(
			commercial_claim_sk,claim_no,exposure_type,exposure_name,claim_coverage_cd,claim_coverage_desc,
			claimant_nm,
			product_sk,claim_feature_status,aslob_sk,claim_adjuster_nm,
			source_system_sk,@current_date,@current_date,@etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET		
			Target.claim_coverage_desc = source.claim_coverage_desc,
			Target.claimant_nm=Source.claimant_nm,
			Target.product_sk=Source.product_sk,
			Target.claim_feature_status=Source.claim_feature_status,
			Target.aslob_sk=Source.aslob_sk,
			Target.claim_adjuster_nm=Source.claim_adjuster_nm,		
			Target.update_ts=@current_date;

		--************End************

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest_created_updated) FROM edw_temp.sp_tcommercial_claim_feature_temp1),@last_source_extract_ts);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.sp_tcommercial_claim_feature_temp1

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
