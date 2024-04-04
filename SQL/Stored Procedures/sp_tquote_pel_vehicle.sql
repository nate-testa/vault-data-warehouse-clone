-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel quote vehicle data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 10/24/2023 			Yunus Mohammed					1. Created this procedure 
-- =========================================================================================================================== 

CREATE or alter  PROCEDURE [edw_core].[sp_tquote_pel_vehicle]

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

		drop table if exists edw_temp.tquote_pel_vehicle_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,quote_history_sk,source_system_sk,
			CreatedDate,[Index],VehicleType,Model,Vin,[Year],Make,
			[Body], Weight, Horsepower, EngineSize, EngineType, HighPerformanceVehicle, BasicModelName,
			VINChangeIndicator, DistributionDate, Restraint, AntiLockBrakes, EngineCylinders, FieldChangeIndicator, FourWheelDriveIndicator, ElectronicStabilityControl, TonnageIndicator, PayloadCapacity, DaytimeRunningLightIndicator, Wheelbase, ClassCode, AntiTheftIndicator, GrossVehicleWeight, Height, StateException, VMPerformanceIndicator, NCICCode, Chassis, [Length], Width, BaseMSRP, SpecialHandlingIndicator, RAPAInterimIndicator, SpecialInfoSelector, ModelSeriesInfo, BodyInfo, EngineInfo, RestraintInfo, TransmissionInfo, OtherInfo, ReleaseDate
			into edw_temp.tquote_pel_vehicle_temp1
		from
		(
		select * 
		from
			(
			 
			select
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk ,
			act.[Number] AS transaction_seq_no,atvo.[Index],
			act.CreatedDate,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			atvof.Field,atvof.[Value]
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tquote_history] tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.[Number]
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null and
				act.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and atvo.ObjectType='Vehicle'
				and atvof.Field IN 
				(
					'VehicleType','Model','Vin','ModelYear','Make', 'Body', 'Weight', 'Horsepower', 'EngineSize', 'EngineType', 'HighPerformanceVehicle', 'BasicModelName', 'VINChangeIndicator', 'DistributionDate', 'Restraint', 'AntiLockBrakes', 'EngineCylinders', 'FieldChangeIndicator', 'FourWheelDriveIndicator', 'ElectronicStabilityControl', 'TonnageIndicator', 'PayloadCapacity', 'DaytimeRunningLightIndicator', 'Wheelbase', 'ClassCode', 'AntiTheftIndicator', 'GrossVehicleWeight', 'Height', 'StateException', 'VMPerformanceIndicator', 'NCICCode', 'Chassis', 'Length', 'Width', 'BaseMSRP', 'SpecialHandlingIndicator', 'RAPAInterimIndicator', 'SpecialInfoSelector', 'ModelSeriesInfo', 'BodyInfo', 'EngineInfo', 'RestraintInfo', 'TransmissionInfo', 'OtherInfo', 'ReleaseDate'
				)
				and act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN (VehicleType, Model, Vin, [Year], Make, [Body], Weight, Horsepower, EngineSize, EngineType, HighPerformanceVehicle, BasicModelName, VINChangeIndicator, DistributionDate, Restraint, AntiLockBrakes, EngineCylinders, FieldChangeIndicator, FourWheelDriveIndicator, ElectronicStabilityControl, TonnageIndicator, PayloadCapacity, DaytimeRunningLightIndicator, Wheelbase, ClassCode, AntiTheftIndicator, GrossVehicleWeight, Height, StateException, VMPerformanceIndicator, NCICCode, Chassis, [Length], Width, BaseMSRP, SpecialHandlingIndicator, RAPAInterimIndicator, SpecialInfoSelector, ModelSeriesInfo, BodyInfo, EngineInfo, RestraintInfo, TransmissionInfo, OtherInfo, ReleaseDate)
		) as pivottable

		INSERT INTO [edw_core].[tquote_pel_vehicle]
		(
			quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
			[vehicle_no],[vehicle_type],[vehicle_year],[vehicle_make],[vehicle_model],[vehicle_vin],
			[vehicle_body], [vehicle_curb_weight], [vehicle_horsepower], [vehicle_engine_size], [vehicle_engine_type], [high_performance_vehicle], [vehicle_basic_model_nm],
			[vehicle_vin_change_in], [vehicle_distribution_dt], [vehicle_restraint], [vehicle_antilock_brakes], [vehicle_engine_cylinders], [vehicle_field_change_in], [vehicle_four_wheel_drive_in], [vehicle_electronic_stability_control], [vehicle_tonnage_in], [vehicle_payload_capacity], [vehicle_daytime_running_light_in], [vehicle_wheel_base], [vehicle_class_cd], [vehicle_antitheft_in], [vehicle_gross_weight], [vehicle_height], [vehicle_state_exception], [vm_performance_in], [vehicle_ncic_cd], [vehicle_chassis], [vehicle_length], [vehicle_width], [vehicle_base_msrp], [special_handling_in], [rapa_interim_in], [special_info_selector], [vehicle_model_series_info], [vehicle_body_info], [vehicle_engine_info], [vehicle_restraint_info], [vehicle_transmission_info], [vehicle_other_info], [vehicle_release_dt],
			[source_system_sk],[create_ts],[update_ts],[etl_audit_sk]
		)
		SELECT
			PolicyNumber AS policy_no,EffectiveDate AS effective_dt,
			ExpirationDate AS expiration_dt,transaction_seq_no AS transaction_seq_no,quote_history_sk,
			[Index] AS [vehicle_no], VehicleType AS [vehicle_type], [Year] AS vehicle_year,Make AS vehicle_make,
			Model AS vehicle_model,Vin AS vehicle_vin,
			[Body], Weight, Horsepower, EngineSize, EngineType, HighPerformanceVehicle, BasicModelName,
			VINChangeIndicator, DistributionDate, Restraint, AntiLockBrakes, EngineCylinders, FieldChangeIndicator, FourWheelDriveIndicator, ElectronicStabilityControl, TonnageIndicator, PayloadCapacity, DaytimeRunningLightIndicator, Wheelbase, ClassCode, AntiTheftIndicator, GrossVehicleWeight, Height, StateException, VMPerformanceIndicator, NCICCode, Chassis, Length, Width, BaseMSRP, SpecialHandlingIndicator, RAPAInterimIndicator, SpecialInfoSelector, ModelSeriesInfo, BodyInfo, EngineInfo, RestraintInfo, TransmissionInfo, OtherInfo, ReleaseDate,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_pel_vehicle_temp1 AS ttpv

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_vehicle_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_vehicle_temp1
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