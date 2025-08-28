-- ================================================================================================= 
-- Author:		Yunus Mohammed
-- Description: This procedures inserts the PR01 data for carrier feed
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						        |	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/11/25					Yunus Mohammed			1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_current_carrier_auto_pr01_feed]
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

	drop table if exists edw_temp.policy_current_carrier_auto_pr01_feed_temp1


	select
	'PRO1' as [RecordCode],
	np.[ContribCompanyAMBestNumber],
	np.policyNumber,
	np.InsuranceType,
	np.ChangeEffectiveDate,
	LEFT(av.vehicle_vin,25) as [VIN],
	av.vehicle_model_year as VehicleModelYear,
	LEFT(av.vehicle_make,20) as VehicleMake,
	LEFT(av.vehicle_model,20) as VehicleModel,
	/*
	SUBSTRING(agl.garage_address_line1, 1, PATINDEX('%[^0-9]%', agl.garage_address_line1 + 'x') - 1) as LocationAddressHouseNumber,
	LEFT(TRIM(SUBSTRING(agl.garage_address_line1, PATINDEX('%[^0-9]%', agl.garage_address_line1), 30)), 20)  AS [LocationAddressStreetName],
	LEFT(agl.garage_address_unit_no, 5) as LocationAddressAptNumber,
	LEFT(agl.garage_address_city_nm,20) as LocationAddressCity,
	LEFT(agl.garage_address_state_cd,2) as LocationAddressState,
	LEFT(agl.garage_address_zip_code,5) as LocationAddressZIPCode,
	*/
	'' as LocationAddressHouseNumber,
	''  AS [LocationAddressStreetName],
	'' as LocationAddressAptNumber,
	'' as LocationAddressCity,
	'' as LocationAddressState,
	null as LocationAddressZIPCode,
	null as LocationAddressZIPCodePlus4,

	'' as Reserved1,
	'' as BusinessUseIndicator,
	'' as Reserved2,

	case when apc.bodily_injury_limit_amt is not null then 'BI' end CoverageType1,
	case when charindex('/',apc.bodily_injury_limit_amt) > 0 then
	trim(SUBSTRING(apc.bodily_injury_limit_amt,1,charindex('/',apc.bodily_injury_limit_amt)-1))
	end as IndividualLimit1,
	case when charindex('/',apc.bodily_injury_limit_amt) > 0 then
	trim(SUBSTRING(apc.bodily_injury_limit_amt,charindex('/',apc.bodily_injury_limit_amt)+1,100))
	end as OccurrenceLimit1,
	null as CSL1,	
	-- for collision and comp out values in ded 2 and 3 respectively.
	case when avc.collision_deductible is not null then 'CO' end as CoverageType2,
	null as IndividualLimit2,
	null as OccurrenceLimit2,
	null as CSL2,

	case when avc.otc_deductible is not null then 'CP' end as CoverageType3,
	null as IndividualLimit3,
	null as OccurrenceLimit3,
	'' as CSL3,

	case when apc.combined_single_limit_amt is not null then 'CSL' end as CoverageType4,
	null as IndividualLimit4,
	null as OccurrenceLimit4,
	apc.combined_single_limit_amt as CSL4,

	case when apc.medical_payment_limit_amt is not null then 'MP' end as CoverageType5,
	NULL AS IndividualLimit5,
	apc.medical_payment_limit_amt AS OccurrenceLimit5,
	null AS CSL5,
	case when trim(isnull(apc.uninsured_motorist_limit_amt,''))!='' then 'NB' end as CoverageType6,
	case when trim(isnull(apc.uninsured_motorist_limit_amt,''))!='' then 
	trim(
		SUBSTRING(apc.uninsured_motorist_limit_amt,1,
			iif(charindex('/',apc.uninsured_motorist_limit_amt) > 0,charindex('/',apc.uninsured_motorist_limit_amt)-1,
				100
				)
		)
	)
	end	as IndividualLimit6,
	case when CHARINDEX('/', apc.uninsured_motorist_limit_amt, CHARINDEX('/', apc.uninsured_motorist_limit_amt) + 1) >0 then 
	LTRIM(RTRIM(SUBSTRING(apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1, 
		CHARINDEX('/', apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1) - 
		charindex('/',apc.uninsured_motorist_limit_amt) - 1)))
	else
	LTRIM(RTRIM(SUBSTRING(apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1,  100)))	
	end AS OccurrenceLimit6,
	null as CSL6,
	
	case when CHARINDEX('/', apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1) > 0 then
	'NP' end as CoverageType7,
	null as IndividualLimit7,
	case when CHARINDEX('/', apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1) > 0 then
	LTRIM(RTRIM(SUBSTRING(apc.uninsured_motorist_limit_amt, CHARINDEX('/', apc.uninsured_motorist_limit_amt, 
	charindex('/',apc.uninsured_motorist_limit_amt) + 1)+1, LEN(apc.uninsured_motorist_limit_amt)))) 
	END as OccurrenceLimit7,
	null as CSL7,
	
	case when apc.property_damage_limit_amt is not null then 'PD' end CoverageType8,
	NULL AS IndividualLimit8,
	apc.property_damage_limit_amt AS OccurrenceLimit8,
	NULL AS CSL8,

	case when apc.pip_limit_amt is not null then 'PR' end AS CoverageType9,
	NULL AS IndividualLimit9,
	apc.pip_limit_amt AS OccurrenceLimit9,
	null as CSL9,
	
	case when trim(isnull(apc.underinsured_motorist_limit_amt,''))!='' then 'UB' end as CoverageType10,
	case when trim(isnull(apc.underinsured_motorist_limit_amt,''))!='' then	
	trim(
			SUBSTRING(apc.underinsured_motorist_limit_amt,1,
				iif(charindex('/',apc.underinsured_motorist_limit_amt) > 0,charindex('/',apc.underinsured_motorist_limit_amt)-1,
				100
				)
			)
		) 
	end AS IndividualLimit10,
	case when CHARINDEX('/', apc.underinsured_motorist_limit_amt, CHARINDEX('/', apc.underinsured_motorist_limit_amt) + 1) > 0 then 
	LTRIM(RTRIM(SUBSTRING(apc.underinsured_motorist_limit_amt, charindex('/',apc.underinsured_motorist_limit_amt) + 1, CHARINDEX('/', apc.underinsured_motorist_limit_amt, charindex('/',apc.underinsured_motorist_limit_amt) + 1) - charindex('/',apc.underinsured_motorist_limit_amt) - 1))) 
	ELSE
	LTRIM(RTRIM(SUBSTRING(apc.underinsured_motorist_limit_amt, charindex('/',apc.underinsured_motorist_limit_amt) + 1, 100)))
	END AS OccurrenceLimit10,
	NULL AS CSL10,
	
	case when CHARINDEX('/', apc.underinsured_motorist_limit_amt, charindex('/',apc.underinsured_motorist_limit_amt) + 1) > 0 then
	'UM' end CoverageType11,
	NULL AS IndividualLimit11,
	case when CHARINDEX('/', apc.underinsured_motorist_limit_amt, charindex('/',apc.underinsured_motorist_limit_amt) + 1) > 0 then
	LTRIM(RTRIM(SUBSTRING(apc.uninsured_motorist_limit_amt, CHARINDEX('/', apc.uninsured_motorist_limit_amt, charindex('/',apc.uninsured_motorist_limit_amt) + 1), LEN(apc.uninsured_motorist_limit_amt)))) 
	END	as OccurrenceLimit11,
	NULL AS CSL11,
	
	case when trim(isnull(apc.combined_um_bi_policy_limit_amt,''))!='' then 'UMUB' end as CoverageType12,
	case when trim(isnull(apc.combined_um_bi_policy_limit_amt,''))!='' then combined_um_bi_policy_limit_amt end as IndividualLimit12,
	case when trim(isnull(apc.combined_um_bi_policy_limit_amt,''))!='' then combined_um_bi_policy_limit_amt end as OccurrenceLimit12,
	NULL AS CSL12,
	
	case when trim(isnull(apc.combined_um_pd_policy_limit_amt,''))!='' then 'UMUP' end as CoverageType13,
	case when trim(isnull(apc.combined_um_pd_policy_limit_amt,''))!='' then combined_um_pd_policy_limit_amt end as IndividualLimit13,
	case when trim(isnull(apc.combined_um_pd_policy_limit_amt,''))!='' then combined_um_pd_policy_limit_amt end as OccurrenceLimit13,
	NULL AS CSL13,

	case when trim(isnull(apc.combined_underinsured_motorist_limit_amt,''))!='' then 'UN' end as CoverageType14,
	NULL as IndividualLimit14,
	NULL as OccurrenceLimit14,
	case when trim(isnull(apc.combined_underinsured_motorist_limit_amt,''))!='' then combined_underinsured_motorist_limit_amt end AS CSL14,

	case when trim(isnull(apc.um_pd_policy_limit_amt,''))!='' then 'UP' end as CoverageType15,
	case when trim(isnull(apc.um_pd_policy_limit_amt,''))!='' then um_pd_policy_limit_amt end as IndividualLimit15,
	NULL as OccurrenceLimit15,
	NULL AS CSL15,
	'' as Reserved3,
	'' as PropertyIdentifier,
	'' as Reserved4,
	'' as Leasedvehicle,
	'' as PropertyCancellationIndicator,
	'0' as PropertyCancellationDate,
	'' as Filler1,
	'' as PropertyType,
	'0' as Deductible1Perc,
	'0' as Deductible1Amount,
	'0' as Deductible2Perc,
	avc.collision_deductible as Deductible2Amount,
	'' as Deductible3Perc,
	avc.otc_deductible as Deductible3Amount,
	'0' as Deductible4Perc,
	'0' as Deductible4Amount,
	'0' as Deductible5Perc,
	'0' as Deductible5Amount,
	'0' as Deductible6Perc,
	'0' as Deductible6Amount,
	'0' as Deductible7Perc,
	'0' as Deductible7Amount,
	'0' as Deductible8Perc,
	'0' as Deductible8Amount,
	'0' as Deductible9Perc,
	'0' as Deductible9Amount,
	'0' as Deductible10Perc,
	'0' as Deductible10Amount,
	'0' as Deductible11Perc,
	'0' as Deductible11Amount,
	'0' as Deductible12Perc,
	'0' as Deductible12Amount,
	'0' as Deductible13Perc,
	'0' as Deductible13Amount,
	'0' as Deductible14Perc,
	'0' as Deductible14Amount,
	'0' as Deductible15Perc,
	'0' as Deductible15Amount,
	'' as FormNumber,
	'' as OtherSerialNumber,
	'' as OtherMake,
	'' as OtherModel,
	'' as OtherYear,
	'' as Filler2,

	np.policy_sk,
	np.policy_no,
	np.policy_history_sk,
	avc.auto_vehicle_coverage_sk,
	avc.auto_vehicle_sk,
	av.vehicle_no,
	apc.auto_policy_coverage_sk,
	np.transaction_seq_no,
	np.transaction_ts,
	np.create_ts as np_create_ts,
	getdate() as create_ts,
	getdate() as update_ts,
	@etl_audit_sk as etl_audit_sk
	into edw_temp.policy_current_carrier_auto_pr01_feed_temp1
	from
	edw_integration.policy_current_carrier_auto_np01_feed np
	inner join edw_core.tpolicy p on p.policy_sk = np.policy_sk
	inner join edw_core.tauto_vehicle av on p.policy_no = av.policy_no and p.effective_dt = av.effective_dt
	inner join edw_core.tauto_vehicle_coverage avc on av.auto_vehicle_sk = avc.auto_vehicle_sk and avc.policy_history_sk = np.policy_history_sk
	--inner join edw_core.tpolicy_history ph on p.policy_sk = ph.policy_sk and avc.policy_history_sk = ph.policy_history_sk
	--left join edw_core.tauto_garage_location agl on agl.policy_no = ph.policy_no and agl.effective_dt = ph.effective_dt	and agl.transaction_seq_no = ph.transaction_seq_no and ag
	left join edw_core.tauto_policy_coverage apc on apc.policy_history_sk = np.policy_history_sk -- and avc.policy_history_sk = ph.policy_history_sk
	where
	avc.vehicle_deleted_in = 'No'
	and cast(np.create_ts as date) >@last_source_extract_ts
	
	insert into edw_integration.policy_current_carrier_auto_pr01_feed
	(
	RecordCode,ContribCompanyAMBestNumber,PolicyNumber,InsuranceType,ChangeEffectiveDate,VIN,VehicleModelYear,VehicleMake,VehicleModel,
	LocationAddressHouseNumber,LocationAddressStreetName,LocationAddressAptNumber,LocationAddressCity,LocationAddressState,LocationAddressZIPCode,
	LocationAddressZIPCodePlus4,Reserved1,BusinessUseIndicator,Reserved2,CoverageType1,IndividualLimit1,OccurrenceLimit1,CSL1,CoverageType2,
	IndividualLimit2,OccurrenceLimit2,CSL2,CoverageType3,IndividualLimit3,OccurrenceLimit3,CSL3,CoverageType4,IndividualLimit4,OccurrenceLimit4,
	CSL4,CoverageType5,IndividualLimit5,OccurrenceLimit5,CSL5,CoverageType6,IndividualLimit6,OccurrenceLimit6,CSL6,CoverageType7,
	IndividualLimit7,OccurrenceLimit7,CSL7,CoverageType8,IndividualLimit8,OccurrenceLimit8,CSL8,CoverageType9,IndividualLimit9,
	OccurrenceLimit9,CSL9,CoverageType10,IndividualLimit10,OccurrenceLimit10,CSL10,CoverageType11,IndividualLimit11,OccurrenceLimit11,
	CSL11,CoverageType12,IndividualLimit12,OccurrenceLimit12,CSL12,CoverageType13,IndividualLimit13,OccurrenceLimit13,CSL13,CoverageType14,
	IndividualLimit14,OccurrenceLimit14,CSL14,CoverageType15,IndividualLimit15,OccurrenceLimit15,CSL15,Reserved3,PropertyIdentifier,Reserved4,
	Leasedvehicle,PropertyCancellationIndicator,PropertyCancellationDate,Filler1,PropertyType,Deductible1Perc,Deductible1Amount,Deductible2Perc,
	Deductible2Amount,Deductible3Perc,Deductible3Amount,Deductible4Perc,Deductible4Amount,Deductible5Perc,Deductible5Amount,Deductible6Perc,
	Deductible6Amount,Deductible7Perc,Deductible7Amount,Deductible8Perc,Deductible8Amount,Deductible9Perc,Deductible9Amount,Deductible10Perc,
	Deductible10Amount,Deductible11Perc,Deductible11Amount,Deductible12Perc,Deductible12Amount,Deductible13Perc,Deductible13Amount,Deductible14Perc,
	Deductible14Amount,Deductible15Perc,Deductible15Amount,FormNumber,OtherSerialNumber,OtherMake,OtherModel,OtherYear,Filler2,
	policy_sk,policy_no,policy_history_sk,auto_vehicle_coverage_sk,auto_vehicle_sk,vehicle_no,auto_policy_coverage_sk,
	transaction_seq_no,transaction_ts,create_ts,update_ts,etl_audit_sk
	)	
	select
	REPLACE(REPLACE(REPLACE(ISNULL(RecordCode ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RecordCode,
	REPLACE(REPLACE(REPLACE(ISNULL(ContribCompanyAMBestNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as ContribCompanyAMBestNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(PolicyNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(InsuranceType ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InsuranceType,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(ChangeEffectiveDate ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as ChangeEffectiveDate,
	REPLACE(REPLACE(REPLACE(ISNULL(VIN ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VIN,
	RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(VehicleModelYear ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as VehicleModelYear,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleMake ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleMake,
	REPLACE(REPLACE(REPLACE(ISNULL(VehicleModel ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as VehicleModel,
	REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressHouseNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LocationAddressHouseNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressStreetName ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LocationAddressStreetName,
	REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressAptNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LocationAddressAptNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressCity ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LocationAddressCity,
	REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressState ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as LocationAddressState,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressZIPCode ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as LocationAddressZIPCode,
	RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(LocationAddressZIPCodePlus4 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as LocationAddressZIPCodePlus4,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved1 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved1,
	REPLACE(REPLACE(REPLACE(ISNULL(BusinessUseIndicator ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as BusinessUseIndicator,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved2 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved2,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType1 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType1,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit1 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit1,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit1 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit1,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(CSL1 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL1,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType2 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType2,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit2 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8)as IndividualLimit2,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit2 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit2,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL2 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL2,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType3 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType3,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit3 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0') ,8)as IndividualLimit3,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit3 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit3,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL3 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL3,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType4 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType4,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit4 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit4,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit4 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit4,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL4 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL4,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType5 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType5,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit5 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit5,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit5 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0') ,8)as OccurrenceLimit5,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL5 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL5,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType6 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType6,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit6 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8)as IndividualLimit6,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit6 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit6,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL6 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL6,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType7 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType7,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit7 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit7,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit7 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit7,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(CSL7 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL7,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType8 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType8,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit8,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit8,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL8,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType9 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType9,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit9 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit9,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit9 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0') ,8) OccurrenceLimit9,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL9 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL9,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType10 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType10,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit10,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit10,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL8 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL10,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType11 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType11,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit11 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit11,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit11 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit11,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL11 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL11,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType12 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType12,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit12 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit12,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit12 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit12,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL12 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL12,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType13 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType13,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit13 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit13,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit13 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit13,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL13 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8)as CSL13,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType14 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType14,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit14 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8)as IndividualLimit14,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit14 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit14,
	RIGHT('00000000'+REPLACE(REPLACE(REPLACE(ISNULL(CSL14 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL14,
	REPLACE(REPLACE(REPLACE(ISNULL(CoverageType15 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as CoverageType15,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(IndividualLimit15 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as IndividualLimit15,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(OccurrenceLimit15 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as OccurrenceLimit15,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(CSL15 ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as CSL15,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved3 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved3,
	REPLACE(REPLACE(REPLACE(ISNULL(PropertyIdentifier ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PropertyIdentifier,
	REPLACE(REPLACE(REPLACE(ISNULL(Reserved4 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved4,
	REPLACE(REPLACE(REPLACE(ISNULL(Leasedvehicle ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Leasedvehicle,
	REPLACE(REPLACE(REPLACE(ISNULL(PropertyCancellationIndicator ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PropertyCancellationIndicator,
	RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PropertyCancellationDate ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as PropertyCancellationDate,
	REPLACE(REPLACE(REPLACE(ISNULL(Filler1 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Filler1,
	REPLACE(REPLACE(REPLACE(ISNULL(PropertyType ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PropertyType,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible1Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible1Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible1Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible1Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible2Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible2Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible2Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible2Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible3Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible3Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible3Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible3Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible4Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible4Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible4Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible4Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible5Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible5Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible5Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible5Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible6Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible6Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible6Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible6Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible7Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible7Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible7Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible7Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible8Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible8Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible8Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible8Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible9Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible9Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible9Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible9Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible10Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible10Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible10Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible10Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible11Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible11Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible11Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible11Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible12Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible12Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible12Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible12Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible13Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible13Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible13Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible13Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible14Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible15Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible14Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible15Amount,
	RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible15Perc ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as Deductible15Perc,
	RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(Deductible15Amount ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as Deductible15Amount,
	REPLACE(REPLACE(REPLACE(ISNULL(FormNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as FormNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(OtherSerialNumber ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as OtherSerialNumber,
	REPLACE(REPLACE(REPLACE(ISNULL(OtherMake ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as OtherMake,
	REPLACE(REPLACE(REPLACE(ISNULL(OtherModel ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as OtherModel,
	RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(OtherYear ,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as OtherYear,
	REPLACE(REPLACE(REPLACE(ISNULL(Filler2 ,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Filler2,
	policy_sk,
	policy_no,
	policy_history_sk,
	auto_vehicle_coverage_sk,
	auto_vehicle_sk,
	vehicle_no,
	auto_policy_coverage_sk,
	transaction_seq_no,
	transaction_ts,
	create_ts,
	update_ts,
	etl_audit_sk
	from
	edw_temp.policy_current_carrier_auto_pr01_feed_temp1
	
	SET @rows_affected=@@ROWCOUNT;

	SET @new_last_source_extract_ts=COALESCE((SELECT MAX(np_create_ts) FROM edw_temp.policy_current_carrier_auto_pr01_feed_temp1),@last_source_extract_ts);
		
	-- Update control table
	EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
	-- Update audit table
	SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) 
	EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_pr01_feed_temp1;
	
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