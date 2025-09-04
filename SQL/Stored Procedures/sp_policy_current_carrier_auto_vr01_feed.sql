-- ================================================================================================= 
-- Author:		Yunus Mohammed
-- Description: This procedures inserts the VR01 data for carrier feed
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						        |	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/15/25					Yunus Mohammed			1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_current_carrier_auto_vr01_feed]
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
	DECLARE @parameter_desc VARCHAR(255)
	-- Get last source extract date
	SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
	EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

	DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_vr01_feed_temp1;
	
	select
	'VR01' as [RecordCode],
	pr.[ContribCompanyAMBestNumber],
	pr.PolicyNumber,
	pr.InsuranceType,
	pr.ChangeEffectiveDate,	
	av.vehicle_vin as [VIN],
	avc.registration_state_cd as [VehicleRegisteredState],
	-- -- Dune Buggy
	--Collector Car
	case
		when av.vehicle_type = 'Private Passenger Auto' then '02'
		when av.vehicle_type IN('Motor Home','Recreational Trailer') then '22'
		WHEN av.vehicle_type = 'Snowmobile / ATV' then '24'
		when av.vehicle_type = 'Motorcycles / Mopeds / Scooter / Go Karts' then '23'
		when av.vehicle_type = 'Golf Cart' then '21'		
		else ''
	end as [VehicleType],
	'A' as VehicleStatus,
	'0' as VehicleStatusDate,
	'' as vehicleCancellationReason,
	'' as NonCoverageReasonCode,
	'' as LicensePlateNumber,
	'' as StateTrackingNumber,
	'' as Reserved1,
	(
		select
			FORMAT(min(avc1.transaction_effective_dt),'yyyyMMdd')
		from
			edw_core.tauto_vehicle_coverage avc1
		where
			avc1.auto_vehicle_sk = avc.auto_vehicle_sk

	) as VehicleAddDate,
	'' InsuredRegistrantSequenceNumber,
	'' as VehicleMileage,
	'' as ALIRtSActivityCode,
	'' as TelematicsIndicator,
	'' as TownshipCode,
	'' as RegistrationPlateType,
	'' as RegistrationPlateColor,
	'' as RideShareIndicator,
	'' as Reserved2,
	'' as CellphoneNumberCountryCode,
	'' as CellphoneAreaCode,
	'' as CellphoneNumber,
	'' as Filler1,
	pr.policy_sk,
	pr.policy_no,
	pr.policy_history_sk,
	avc.auto_vehicle_coverage_sk,
	avc.auto_vehicle_sk,
	av.vehicle_no,
	pr.transaction_seq_no,
	pr.transaction_ts,
	pr.create_ts as pr_create_ts,
	getdate() as create_ts,
	getdate() as update_ts,
	@etl_audit_sk as etl_audit_sk
	into edw_temp.policy_current_carrier_auto_vr01_feed_temp1
	from
	edw_integration.policy_current_carrier_auto_pr01_feed pr
	--inner join edw_core.tpolicy p on p.policy_sk = pr.policy_sk
	inner join edw_core.tauto_vehicle av on av.auto_vehicle_sk = pr.auto_vehicle_sk -- p.policy_no = av.policy_no and p.effective_dt = av.effective_dt
	inner join edw_core.tauto_vehicle_coverage avc on  av.auto_vehicle_sk = avc.auto_vehicle_sk and avc.policy_history_sk = pr.policy_history_sk
	--inner join edw_core.tpolicy_history ph on pr.policy_history_sk = ph.policy_history_sk and avc.policy_history_sk = ph.policy_history_sk
	
	where
	cast(pr.create_ts as date) >@last_source_extract_ts
	and avc.vehicle_deleted_in = 'No'

	
	insert into [edw_integration].policy_current_carrier_auto_vr01_feed
	(
	RecordCode,ContribCompanyAMBestNumber,PolicyNumber,InsuranceType,ChangeEffectiveDate,VIN,
	VehicleRegisteredState,VehicleType,VehicleStatus,VehicleStatusDate,vehicleCancellationReason,
	NonCoverageReasonCode,LicensePlateNumber,StateTrackingNumber,Reserved1,VehicleAddDate,InsuredRegistrantSequenceNumber,
	VehicleMileage,ALIRtSActivityCode,TelematicsIndicator,TownshipCode,RegistrationPlateType,RegistrationPlateColor,
	RideShareIndicator,Reserved2,CellphoneNumberCountryCode,CellphoneAreaCode,CellphoneNumber,Filler1,
	policy_sk,policy_no,policy_history_sk,auto_vehicle_coverage_sk,auto_vehicle_sk,vehicle_no,
	transaction_seq_no,transaction_ts,create_ts,update_ts,etl_audit_sk
	)
	
	select
	RecordCode,ContribCompanyAMBestNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(PolicyNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(InsuranceType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InsuranceType,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(ChangeEffectiveDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as ChangeEffectiveDate,
	REPLACE(REPLACE(REPLACE(ISNULL(VIN,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VIN,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleRegisteredState,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleRegisteredState,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleType,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleStatus,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleStatus,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(VehicleStatusDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as VehicleStatusDate,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleCancellationReason,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleCancellationReason,
	REPLACE(REPLACE(REPLACE(ISNULL(NonCoverageReasonCode,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as NonCoverageReasonCode,
	REPLACE(REPLACE(REPLACE(ISNULL(LicensePlateNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LicensePlateNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(StateTrackingNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as StateTrackingNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved1,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved1,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(VehicleAddDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as VehicleAddDate,
	REPLACE(REPLACE(REPLACE(ISNULL(InsuredRegistrantSequenceNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InsuredRegistrantSequenceNumber,
	RIGHT('000000'+ REPLACE(REPLACE(REPLACE(ISNULL(VehicleMileage,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),6) as VehicleMileage,
	REPLACE(REPLACE(REPLACE(ISNULL(ALIRtSActivityCode,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as ALIRtSActivityCode,
	REPLACE(REPLACE(REPLACE(ISNULL(TelematicsIndicator,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as TelematicsIndicator,
	REPLACE(REPLACE(REPLACE(ISNULL(TownshipCode,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as TownshipCode,
	REPLACE(REPLACE(REPLACE(ISNULL(RegistrationPlateType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RegistrationPlateType, 
	REPLACE(REPLACE(REPLACE(ISNULL(RegistrationPlateColor,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RegistrationPlateColor,
	REPLACE(REPLACE(REPLACE(ISNULL(RideShareIndicator,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RideShareIndicator,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved2,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved2,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(CellphoneNumberCountryCode,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as CellphoneNumberCountryCode,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(CellphoneAreaCode,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as CellphoneAreaCode,
	RIGHT('0000000'+ REPLACE(REPLACE(REPLACE(ISNULL(CellphoneNumber,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),7) as CellphoneNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(Filler1,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Filler1,
	policy_sk,policy_no,policy_history_sk,auto_vehicle_coverage_sk,auto_vehicle_sk,vehicle_no,
	transaction_seq_no,transaction_ts,create_ts,update_ts,etl_audit_sk
	from
	edw_temp.policy_current_carrier_auto_vr01_feed_temp1

	SET @rows_affected=@@ROWCOUNT;

	SET @new_last_source_extract_ts=COALESCE((SELECT MAX(pr_create_ts) FROM edw_temp.policy_current_carrier_auto_vr01_feed_temp1),@last_source_extract_ts);
	-- Update control table
	EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
	-- Update audit table
	SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) 
	EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_vr01_feed_temp1;
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