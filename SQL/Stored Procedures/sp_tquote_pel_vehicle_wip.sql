-- =========================================================================================================================== 
-- Description: This procedures insert and update info related to pel quote vehicle data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/06/2024 			Hernando Gonzalez					1. Created this procedure 
-- 05/08/2024 			Architha Gudimalla					2. Updated @new_last_source_extract_ts 
-- 05/14/2024 			Architha Gudimalla					3. Corrected errors
-- 07/31/2024 			Alberto Almario						4. Add new column vehicle_unique_id
-- 08/22/2024			Architha Gudimalla					54. Removed eff_dt from merge
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_vehicle_wip]

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

		drop table if exists edw_temp.tquote_pel_vehicle_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,quote_history_sk,source_system_sk,
			CreatedDate,UpdatedDate,[Index],VehicleType,Model,Vin,[Year],Make,
			[Body], Weight, Horsepower, EngineSize, EngineType, HighPerformanceVehicle, BasicModelName,
			VINChangeIndicator, DistributionDate, Restraint, AntiLockBrakes, EngineCylinders, FieldChangeIndicator, FourWheelDriveIndicator, ElectronicStabilityControl, TonnageIndicator, PayloadCapacity, DaytimeRunningLightIndicator, Wheelbase, ClassCode, AntiTheftIndicator, GrossVehicleWeight, Height, StateException, VMPerformanceIndicator, NCICCode, Chassis, [Length], Width, BaseMSRP, SpecialHandlingIndicator, RAPAInterimIndicator, SpecialInfoSelector, ModelSeriesInfo, BodyInfo, EngineInfo, RestraintInfo, TransmissionInfo, OtherInfo, ReleaseDate,
			CollectorCarType, MotorHomeClass,
			GaragingAddressLine1, GaragingAddressLine2, GaragingAddressLineUnit, GaragingAddressCity, GaragingAddressZipCode, GaragingAddressState, GaragingAddressCounty, GaragingAddressCountry
			,vehicle_unique_id
			into edw_temp.tquote_pel_vehicle_wip_temp1
		from
		(
		select * 
		from
			(
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk ,
			0 AS transaction_seq_no,acco.[Index],
			acc.CreatedDate,acc.UpdatedDate,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			accof.Field,accof.[Value]
			,acco.[UniqueId] as vehicle_unique_id
			from
				(
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				inner join edw_stage.Product p on p.Id=acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				left join [edw_core].[tquote_history] tph on tph.quote_no=acc.PolicyNumber
						and tph.effective_dt=acc.EffectiveDate
						and tph.transaction_seq_no = 0
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				--and acc.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and acco.ObjectType='Vehicle'
				and accof.Field IN 
				(
					'VehicleType','Model','Vin','ModelYear','Make', 'Body', 'Weight', 'Horsepower', 'EngineSize', 'EngineType', 'HighPerformanceVehicle', 'BasicModelName', 'VINChangeIndicator', 'DistributionDate', 'Restraint', 'AntiLockBrakes', 'EngineCylinders', 'FieldChangeIndicator', 'FourWheelDriveIndicator', 'ElectronicStabilityControl', 'TonnageIndicator', 'PayloadCapacity', 'DaytimeRunningLightIndicator', 'Wheelbase', 'ClassCode', 'AntiTheftIndicator', 'GrossVehicleWeight', 'Height', 'StateException', 'VMPerformanceIndicator', 'NCICCode', 'Chassis', 'Length', 'Width', 'BaseMSRP', 'SpecialHandlingIndicator', 'RAPAInterimIndicator', 'SpecialInfoSelector', 'ModelSeriesInfo', 'BodyInfo', 'EngineInfo', 'RestraintInfo', 'TransmissionInfo', 'OtherInfo', 'ReleaseDate',
					'CollectorCarType', 'MotorHomeClass',
					'GaragingAddressLine1', 'GaragingAddressLine2', 'GaragingAddressLineUnit', 'GaragingAddressCity', 'GaragingAddressZipCode', 'GaragingAddressState', 'GaragingAddressCounty', 'GaragingAddressCountry'
				)
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN (VehicleType, Model, Vin, [Year], Make, [Body], Weight, Horsepower, EngineSize, EngineType, HighPerformanceVehicle, BasicModelName, VINChangeIndicator, DistributionDate, Restraint, AntiLockBrakes, EngineCylinders, FieldChangeIndicator, FourWheelDriveIndicator, ElectronicStabilityControl, TonnageIndicator, PayloadCapacity, DaytimeRunningLightIndicator, Wheelbase, ClassCode, AntiTheftIndicator, GrossVehicleWeight, Height, StateException, VMPerformanceIndicator, NCICCode, Chassis, [Length], Width, BaseMSRP, SpecialHandlingIndicator, RAPAInterimIndicator, SpecialInfoSelector, ModelSeriesInfo, BodyInfo, EngineInfo, RestraintInfo, TransmissionInfo, OtherInfo, ReleaseDate,
										CollectorCarType, MotorHomeClass,
										GaragingAddressLine1, GaragingAddressLine2, GaragingAddressLineUnit, GaragingAddressCity, GaragingAddressZipCode, GaragingAddressState, GaragingAddressCounty, GaragingAddressCountry
										)
		) as pivottable

		MERGE INTO  [edw_core].[tquote_pel_vehicle] AS TARGET
		USING (
		    SELECT
		        PolicyNumber AS quote_no,
		        EffectiveDate AS effective_dt,
		        ExpirationDate AS expiration_dt,
		        transaction_seq_no AS transaction_seq_no,
		        quote_history_sk,
		        [Index] AS vehicle_no,
		        VehicleType AS vehicle_type,
		        [Year] AS vehicle_year,
		        Make AS vehicle_make,
		        Model AS vehicle_model,
		        Vin AS vehicle_vin,
		        [Body] AS vehicle_body,
		        Weight AS vehicle_curb_weight,
		        Horsepower AS vehicle_horsepower,
		        EngineSize AS vehicle_engine_size,
		        EngineType AS vehicle_engine_type,
		        HighPerformanceVehicle AS high_performance_vehicle,
		        BasicModelName AS vehicle_basic_model_nm,
		        VINChangeIndicator AS vehicle_vin_change_in,
		        DistributionDate AS vehicle_distribution_dt,
		        Restraint AS vehicle_restraint,
		        AntiLockBrakes AS vehicle_antilock_brakes,
		        EngineCylinders AS vehicle_engine_cylinders,
		        FieldChangeIndicator AS vehicle_field_change_in,
		        FourWheelDriveIndicator AS vehicle_four_wheel_drive_in,
		        ElectronicStabilityControl AS vehicle_electronic_stability_control,
		        TonnageIndicator AS vehicle_tonnage_in,
		        PayloadCapacity AS vehicle_payload_capacity,
		        DaytimeRunningLightIndicator AS vehicle_daytime_running_light_in,
		        Wheelbase AS vehicle_wheel_base,
		        ClassCode AS vehicle_class_cd,
		        AntiTheftIndicator AS vehicle_antitheft_in,
		        GrossVehicleWeight AS vehicle_gross_weight,
		        Height AS vehicle_height,
		        StateException AS vehicle_state_exception,
		        VMPerformanceIndicator AS vm_performance_in,
		        NCICCode AS vehicle_ncic_cd,
		        Chassis AS vehicle_chassis,
		        Length AS vehicle_length,
		        Width AS vehicle_width,
		        BaseMSRP AS vehicle_base_msrp,
		        SpecialHandlingIndicator AS special_handling_in,
		        RAPAInterimIndicator AS rapa_interim_in,
		        SpecialInfoSelector AS special_info_selector,
		        ModelSeriesInfo AS vehicle_model_series_info,
		        BodyInfo AS vehicle_body_info,
		        EngineInfo AS vehicle_engine_info,
		        RestraintInfo AS vehicle_restraint_info,
		        TransmissionInfo AS vehicle_transmission_info,
		        OtherInfo AS vehicle_other_info,
		        ReleaseDate AS vehicle_release_dt,
		        source_system_sk,
		        getdate() AS create_ts,
		        getdate() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        CollectorCarType AS collector_car_type,
		        MotorHomeClass AS motor_home_class,
		        GaragingAddressLine1 AS garage_address_line1,
		        GaragingAddressLine2 AS garage_address_line2,
		        GaragingAddressLineUnit AS garage_address_unit_no,
		        GaragingAddressCity AS garage_address_city_nm,
		        GaragingAddressZipCode AS garage_address_zip_cd,
		        GaragingAddressState AS garage_address_state_cd,
		        GaragingAddressCounty AS garage_address_county_nm,
		        GaragingAddressCountry AS garage_address_country_nm
				,vehicle_unique_id
		    FROM
		        edw_temp.tquote_pel_vehicle_wip_temp1 AS ttpv
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.vehicle_unique_id = SOURCE.vehicle_unique_id

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.vehicle_type = SOURCE.vehicle_type,
		        TARGET.vehicle_year = SOURCE.vehicle_year,
		        TARGET.vehicle_make = SOURCE.vehicle_make,
		        TARGET.vehicle_model = SOURCE.vehicle_model,
		        TARGET.vehicle_vin = SOURCE.vehicle_vin,
		        TARGET.vehicle_body = SOURCE.vehicle_body,
		        TARGET.vehicle_curb_weight = SOURCE.vehicle_curb_weight,
		        TARGET.vehicle_horsepower = SOURCE.vehicle_horsepower,
		        TARGET.vehicle_engine_size = SOURCE.vehicle_engine_size,
		        TARGET.vehicle_engine_type = SOURCE.vehicle_engine_type,
		        TARGET.high_performance_vehicle = SOURCE.high_performance_vehicle,
		        TARGET.vehicle_basic_model_nm = SOURCE.vehicle_basic_model_nm,
		        TARGET.vehicle_vin_change_in = SOURCE.vehicle_vin_change_in,
		        TARGET.vehicle_distribution_dt = SOURCE.vehicle_distribution_dt,
		        TARGET.vehicle_restraint = SOURCE.vehicle_restraint,
		        TARGET.vehicle_antilock_brakes = SOURCE.vehicle_antilock_brakes,
		        TARGET.vehicle_engine_cylinders = SOURCE.vehicle_engine_cylinders,
		        TARGET.vehicle_field_change_in = SOURCE.vehicle_field_change_in,
		        TARGET.vehicle_four_wheel_drive_in = SOURCE.vehicle_four_wheel_drive_in,
		        TARGET.vehicle_electronic_stability_control = SOURCE.vehicle_electronic_stability_control,
		        TARGET.vehicle_tonnage_in = SOURCE.vehicle_tonnage_in,
		        TARGET.vehicle_payload_capacity = SOURCE.vehicle_payload_capacity,
		        TARGET.vehicle_daytime_running_light_in = SOURCE.vehicle_daytime_running_light_in,
		        TARGET.vehicle_wheel_base = SOURCE.vehicle_wheel_base,
		        TARGET.vehicle_class_cd = SOURCE.vehicle_class_cd,
		        TARGET.vehicle_antitheft_in = SOURCE.vehicle_antitheft_in,
		        TARGET.vehicle_gross_weight = SOURCE.vehicle_gross_weight,
		        TARGET.vehicle_height = SOURCE.vehicle_height,
		        TARGET.vehicle_state_exception = SOURCE.vehicle_state_exception,
		        TARGET.vm_performance_in = SOURCE.vm_performance_in,
		        TARGET.vehicle_ncic_cd = SOURCE.vehicle_ncic_cd,
		        TARGET.vehicle_chassis = SOURCE.vehicle_chassis,
		        TARGET.vehicle_length = SOURCE.vehicle_length,
		        TARGET.vehicle_width = SOURCE.vehicle_width,
		        TARGET.vehicle_base_msrp = SOURCE.vehicle_base_msrp,
		        TARGET.special_handling_in = SOURCE.special_handling_in,
		        TARGET.rapa_interim_in = SOURCE.rapa_interim_in,
		        TARGET.special_info_selector = SOURCE.special_info_selector,
		        TARGET.vehicle_model_series_info = SOURCE.vehicle_model_series_info,
		        TARGET.vehicle_body_info = SOURCE.vehicle_body_info,
		        TARGET.vehicle_engine_info = SOURCE.vehicle_engine_info,
		        TARGET.vehicle_restraint_info = SOURCE.vehicle_restraint_info,
		        TARGET.vehicle_transmission_info = SOURCE.vehicle_transmission_info,
		        TARGET.vehicle_other_info = SOURCE.vehicle_other_info,
		        TARGET.vehicle_release_dt = SOURCE.vehicle_release_dt,
		        TARGET.collector_car_type = SOURCE.collector_car_type,
		        TARGET.motor_home_class = SOURCE.motor_home_class,
		        TARGET.garage_address_line1 = SOURCE.garage_address_line1,
		        TARGET.garage_address_line2 = SOURCE.garage_address_line2,
		        TARGET.garage_address_unit_no = SOURCE.garage_address_unit_no,
		        TARGET.garage_address_city_nm = SOURCE.garage_address_city_nm,
		        TARGET.garage_address_zip_cd = SOURCE.garage_address_zip_cd,
		        TARGET.garage_address_state_cd = SOURCE.garage_address_state_cd,
		        TARGET.garage_address_county_nm = SOURCE.garage_address_county_nm,
		        TARGET.garage_address_country_nm = SOURCE.garage_address_country_nm,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.source_system_sk = SOURCE.source_system_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        vehicle_no, vehicle_type, vehicle_year, vehicle_make, vehicle_model, vehicle_vin,
		        vehicle_body, vehicle_curb_weight, vehicle_horsepower, vehicle_engine_size, vehicle_engine_type, high_performance_vehicle, vehicle_basic_model_nm,
		        vehicle_vin_change_in, vehicle_distribution_dt, vehicle_restraint, vehicle_antilock_brakes, vehicle_engine_cylinders, vehicle_field_change_in, vehicle_four_wheel_drive_in, vehicle_electronic_stability_control, vehicle_tonnage_in, vehicle_payload_capacity, vehicle_daytime_running_light_in, vehicle_wheel_base, vehicle_class_cd, vehicle_antitheft_in, vehicle_gross_weight, vehicle_height, vehicle_state_exception, vm_performance_in, vehicle_ncic_cd, vehicle_chassis, vehicle_length, vehicle_width, vehicle_base_msrp, special_handling_in, rapa_interim_in, special_info_selector, vehicle_model_series_info, vehicle_body_info, vehicle_engine_info, vehicle_restraint_info, vehicle_transmission_info, vehicle_other_info, vehicle_release_dt,
		        source_system_sk, create_ts, update_ts, etl_audit_sk, collector_car_type, motor_home_class,
		        garage_address_line1, garage_address_line2, garage_address_unit_no, garage_address_city_nm, garage_address_zip_cd, garage_address_state_cd, garage_address_county_nm, garage_address_country_nm
				,vehicle_unique_id
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.vehicle_no, SOURCE.vehicle_type, SOURCE.vehicle_year, SOURCE.vehicle_make, SOURCE.vehicle_model, SOURCE.vehicle_vin,
		        SOURCE.vehicle_body, SOURCE.vehicle_curb_weight, SOURCE.vehicle_horsepower, SOURCE.vehicle_engine_size, SOURCE.vehicle_engine_type, SOURCE.high_performance_vehicle, SOURCE.vehicle_basic_model_nm,
		        SOURCE.vehicle_vin_change_in, SOURCE.vehicle_distribution_dt, SOURCE.vehicle_restraint, SOURCE.vehicle_antilock_brakes, SOURCE.vehicle_engine_cylinders, SOURCE.vehicle_field_change_in, SOURCE.vehicle_four_wheel_drive_in, SOURCE.vehicle_electronic_stability_control, SOURCE.vehicle_tonnage_in, SOURCE.vehicle_payload_capacity, SOURCE.vehicle_daytime_running_light_in, SOURCE.vehicle_wheel_base, SOURCE.vehicle_class_cd, SOURCE.vehicle_antitheft_in, SOURCE.vehicle_gross_weight, SOURCE.vehicle_height, SOURCE.vehicle_state_exception, SOURCE.vm_performance_in, SOURCE.vehicle_ncic_cd, SOURCE.vehicle_chassis, SOURCE.vehicle_length, SOURCE.vehicle_width, SOURCE.vehicle_base_msrp, SOURCE.special_handling_in, SOURCE.rapa_interim_in, SOURCE.special_info_selector, SOURCE.vehicle_model_series_info, SOURCE.vehicle_body_info, SOURCE.vehicle_engine_info, SOURCE.vehicle_restraint_info, SOURCE.vehicle_transmission_info, SOURCE.vehicle_other_info, SOURCE.vehicle_release_dt,
		        SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk, SOURCE.collector_car_type, SOURCE.motor_home_class,
		        SOURCE.garage_address_line1, SOURCE.garage_address_line2, SOURCE.garage_address_unit_no, SOURCE.garage_address_city_nm, SOURCE.garage_address_zip_cd, SOURCE.garage_address_state_cd, SOURCE.garage_address_county_nm, SOURCE.garage_address_country_nm
				,SOURCE.vehicle_unique_id
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_pel_vehicle_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_vehicle_wip_temp1
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