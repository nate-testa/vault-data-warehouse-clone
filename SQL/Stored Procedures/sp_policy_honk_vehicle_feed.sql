-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the daily policy and associated vehicles data feed to Honk
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/07/25					Dinesh Bobbili			    1. Created this procedure
-- 08/27/25					Dinesh Bobbili			    2. logic to add leading zeros to vin if length is less than 15
-- 08/29/25					Dinesh Bobbili			    3. updated leading zeros for vin
-- 09/09/25					Yunus Mohammed		 		4. Update vin no logic for null values
-- 10/09/25					Dinesh Bobbili			    5. Added logic to replace single and double quotes
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_honk_vehicle_feed]
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
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.policy_honk_vehicle_feed_temp1;
		with temp_inforce_policy as
		(
		select dip.*,
		CASE 
			WHEN TRY_CAST(collision_deductible AS float) IS NOT NULL THEN TRY_CAST(collision_deductible AS float) -- to handle varchar values
			ELSE 0
		END as collision_deductible_1,
		CASE 
			WHEN TRY_CAST(otc_deductible AS float) IS NOT NULL THEN TRY_CAST(otc_deductible AS float)  -- to handle varchar values
			ELSE 0
		END as otc_deductible_1,
		pol.policy_no as policy_number,
		REPLACE(REPLACE(case 
			when len(isnull(av.vehicle_vin,'')) < 15 then concat_ws('',REPLICATE('0', 15-len(isnull(av.vehicle_vin,''))), av.vehicle_vin)
			else av.vehicle_vin
		end, '''', ''), '"', '') as vin,
		REPLACE(REPLACE(av.vehicle_make, '''', ''), '"', '') as vehicle_make,
		REPLACE(REPLACE(av.vehicle_model, '''', ''), '"', '') as vehicle_model,
		av.vehicle_model_year as vehicle_year,
		pol.risk_state_cd,
		vehicle_type,
		avc.extended_towing_and_labor_in,
		avc.vehicle_deleted_in,
		collision_deductible,
		otc_deductible
		from edw_core.tdaily_inforce_policy dip 
		inner join edw_core.tpolicy_history ph
		on ph.policy_history_sk = dip.policy_history_sk
		inner join edw_core.tpolicy pol
		on ph.policy_sk = pol.policy_sk
		inner join edw_core.tauto_vehicle_coverage avc
		on avc.policy_history_sk = ph.policy_history_sk
		inner join edw_core.tauto_vehicle av 
			on avc.auto_vehicle_sk = av.auto_vehicle_sk
		where dip.inforce_dt_sk = (select max(date_sk) from edw_core.tdate where actual_dt < cast(getdate() as date))
		and avc.vehicle_deleted_in = 'No'
		and av.vehicle_type in ('Private Passenger Auto', 'Collector Car', 'Motorcycles / Mopeds / Scooter / Go Karts')
		--and pol.policy_no in (--'AU100003131-05','AU100013273-04')
		)
		select distinct policy_number,
		vin,
		vehicle_make,
		vehicle_model,
		vehicle_year,
		CASE 
			WHEN vehicle_type = 'Private Passenger Auto' THEN 
			CASE 
				WHEN risk_state_cd = 'NC' THEN 
				CASE WHEN extended_towing_and_labor_in = 'Yes' THEN 10000 ELSE 0 END
				WHEN risk_state_cd = 'SC' THEN 
				CASE 
					WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 350 ELSE 0 
				END
				ELSE 
				CASE 
					WHEN risk_state_cd IN ('PA','MD','TN') AND extended_towing_and_labor_in IS NULL AND collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 350
					WHEN extended_towing_and_labor_in = 'Yes' THEN 350 
					ELSE 0 END
			END
			WHEN vehicle_type IN ('Motorcycles / Mopeds / Scooter / Go Karts', 'Collector Car') THEN 
			CASE 
				WHEN risk_state_cd = 'NC' THEN 
				CASE 
					WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 10000 ELSE 0 
				END
				ELSE 
				CASE 
					WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 350 ELSE 0 
				END
			END
			ELSE 0
		END AS coverage_amount_tow,

		CASE 
			WHEN vehicle_type = 'Private Passenger Auto' AND collision_deductible_1 = 0 AND otc_deductible_1 <> 0 THEN 10000
			WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 10000
			ELSE 0
		END AS coverage_amount_accident,

		CASE 
			WHEN vehicle_type = 'Private Passenger Auto' THEN 
			CASE 
				WHEN risk_state_cd = 'SC' THEN 
				CASE 
					WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 'Yes' 
					ELSE 'No' 
				END
				ELSE 
				CASE 
					WHEN risk_state_cd IN ('PA','MD','TN') AND extended_towing_and_labor_in IS NULL AND collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 'Yes'
					WHEN extended_towing_and_labor_in = 'Yes' THEN 'Yes' 
					ELSE 'No' 
				END
			END
			WHEN vehicle_type IN ('Collector Car', 'Motorcycles / Mopeds / Scooter / Go Karts') THEN 
			CASE 
				WHEN collision_deductible_1 <> 0 AND otc_deductible_1 <> 0 THEN 'Yes' 
				ELSE 'No' 
			END
			ELSE 'No'
		END AS coverage_soft_services  
		into edw_temp.policy_honk_vehicle_feed_temp1
		from temp_inforce_policy ip

		TRUNCATE TABLE edw_integration.policy_honk_vehicle_feed;
		-- Start Insert process
		INSERT INTO edw_integration.policy_honk_vehicle_feed (
			policy_number
			,vin
			,vehicle_make
			,vehicle_model
			,vehicle_year
			,coverage_amount_tow
			,coverage_amount_accident
			,coverage_soft_services
			,create_ts
			,update_ts
			,etl_audit_sk

		)
		SELECT 
			policy_number
			,vin
			,vehicle_make
			,vehicle_model
			,vehicle_year
			,coverage_amount_tow
			,coverage_amount_accident
			,coverage_soft_services
			,getdate()
			,getdate()
			,@etl_audit_sk
		FROM 
			edw_temp.policy_honk_vehicle_feed_temp1

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE(dateadd("dd",-1, cast(getdate() as date)),@last_source_extract_ts);
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

		DROP TABLE IF EXISTS edw_temp.policy_honk_vehicle_feed_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END