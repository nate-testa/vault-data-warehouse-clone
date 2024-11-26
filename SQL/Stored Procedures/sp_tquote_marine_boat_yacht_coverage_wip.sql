-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/22/24		    Hernando Gonzalez			1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_coverage_wip]

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets FROM
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
		
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_coverage_wip_temp1
		SELECT 
			PolicyNumber as quote_no
			,EffectiveDate as effective_dt
			,ExpirationDate as expiration_dt
			,transaction_seq_no
			,quote_history_sk
			--
			,[quote_marine_boat_yacht_sk]
			,[quote_marine_boat_yacht_location_sk]
			--
			--
			,Storage as [storage_location] 
			,DistanceToCoast as [distance_to_coast]
			,NavigableWaters as [navigable_waters]
			,LayUpPeriod as [layup_period_in]
			,LayUpPeriodStartDate as [layup_period_start_dt]
			,LayUpPeriodEndDate as [layup_period_end_dt]
			,LayUpFactor as [layup_factor]
			,NumberOfClaims as [no_of_prior_marine_claims]
			,PurchaseDate as [purchase_dt]
			,ActiveTrackingDevice as [active_tracking_device_in]
			,AddPersonalWatercraft as [additional_personal_watercraft_in]
			,AddManuscript as [manuscript_in]
			,HullValue as [hull_value_limit_amt]
			,LiabilityLimit as [liability_limit_amt]
			,PersonalEffectsLimit as [personal_effects_limit_amt]
			,OpaPollutionLiabilityLimit as [opa_pollution_liability_limit_amt]
			,MedicalPaymentLimit as [medical_payments_limit_amt]
			,UninsuredBoaterLimit as [uninsured_boater_limit_amt]
			,AopDeductible as [aop_deductible]
			,WindstormDeductible as [windstorm_deductible]
			,LightningDeductible as [lightning_deductible]
			,TheftDeductible as [theft_deductible]
			,PersonalEffectsDeductible as [personal_effects_deductible]
			,OPAPollutionDeductible as [opa_pollution_deductible]
			,UninsuredBoaterDeductible as [uninsured_boater_deductible]
			,MedicalPaymentsDeductible as [medical_payments_deductible]
			,IncludeTrailerCoverage as [trailer_value_excess_of_5k_in]
			,TrailerValue as [trailer_value]
			,TrailerDeductible as [trailer_deductible]
			,TrailerYear as [trailer_year]
			,TrailerManufacturer as [trailer_manufacturer_nm]
			,TrailerVINSerialNumber as [trailer_vin]
			--
			,FactorMethod as [premium_adjustment_method]
			,Factor as [premium_adjustment_factor]
			,[Retention] as [premium_adjustment_retention]
			,Reason as [premium_adjustment_retention_reason]
			--
			,source_system_sk
			,getdate() as create_ts
			,getdate() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,CreatedDate
			,UpdatedDate
			--
		INTO edw_temp.tquote_marine_boat_yacht_coverage_wip_temp1
		FROM
		(
			SELECT * 
			FROM
			(
				SELECT			
				act.PolicyNumber
				,CAST(act.EffectiveDate as DATE) as EffectiveDate
				,CAST(act.ExpirationDate as DATE) as ExpirationDate
				,0 as transaction_seq_no
				,tqh.quote_history_sk
				,CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk
				,accof.Field
				,accof.[Value]
				,qmby.[quote_marine_boat_yacht_sk] --
				,qmbyl.[quote_marine_boat_yacht_location_sk] --
				,act.CreatedDate
				,act.UpdatedDate
				,apf.FactorMethod, apf.Factor, apf.Retention, apf.Reason
				FROM 
					(
						SELECT *
						FROM [edw_stage].[Account] AS a
						WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
						AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
						AND a.PolicyNumber IS NOT NULL
					) act
					INNER JOIN [edw_stage].[Product] pr on pr.Id = act.ProductId
					INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = act.Id
					INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
					LEFT JOIN [edw_stage].[AccountPremium] ap on ap.AccountId = act.Id
					LEFT JOIN [edw_stage].[AccountPremiumFactor] apf on apf.AccountPremiumId = ap.Id
					LEFT JOIN [edw_core].[tquote_history] tqh on tqh.quote_no = act.PolicyNumber
							AND tqh.effective_dt = act.EffectiveDate
							AND tqh.transaction_seq_no = 0
					LEFT JOIN [edw_core].[tquote_marine_boat_yacht] qmby on qmby.quote_no = act.PolicyNumber AND qmby.effective_dt = CAST(act.EffectiveDate as DATE) AND qmby.expiration_dt = CAST(act.ExpirationDate as DATE)
					LEFT JOIN [edw_core].[tquote_marine_boat_yacht_location] qmbyl on qmbyl.quote_no = act.PolicyNumber AND qmbyl.effective_dt = CAST(act.EffectiveDate as DATE) AND qmbyl.transaction_seq_no = 0
				WHERE
					act.PolicyNumber IS NOT NULL
					AND act.[Stage] IN ('QUOTE', 'POLICY')
					AND pr.[Name] = 'Marine Boat & Yacht'
					AND pr.ProductLine = 'PersonalLines'
					AND accof.Field IN 
					(
						'Storage', 'DistanceToCoast', 'NavigableWaters', 'LayUpPeriod', 'LayUpPeriodStartDate', 'LayUpPeriodEndDate', 'LayUpFactor', 'NumberOfClaims', 'PurchaseDate', 'ActiveTrackingDevice', 'AddPersonalWatercraft', 'AddManuscript', 'HullValue', 'LiabilityLimit', 'PersonalEffectsLimit', 'OpaPollutionLiabilityLimit', 'MedicalPaymentLimit', 'UninsuredBoaterLimit', 'AopDeductible', 'WindstormDeductible', 'LightningDeductible', 'TheftDeductible', 'PersonalEffectsDeductible', 'OPAPollutionDeductible', 'UninsuredBoaterDeductible', 'MedicalPaymentsDeductible', 'IncludeTrailerCoverage', 'TrailerValue', 'TrailerDeductible', 'TrailerYear', 'TrailerManufacturer', 'TrailerVINSerialNumber'
					)
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN 
            (
                Storage, DistanceToCoast, NavigableWaters, LayUpPeriod, LayUpPeriodStartDate, LayUpPeriodEndDate, LayUpFactor, NumberOfClaims, PurchaseDate, ActiveTrackingDevice, AddPersonalWatercraft, AddManuscript, HullValue, LiabilityLimit, PersonalEffectsLimit, OpaPollutionLiabilityLimit, MedicalPaymentLimit, UninsuredBoaterLimit, AopDeductible, WindstormDeductible, LightningDeductible, TheftDeductible, PersonalEffectsDeductible, OPAPollutionDeductible, UninsuredBoaterDeductible, MedicalPaymentsDeductible, IncludeTrailerCoverage, TrailerValue, TrailerDeductible, TrailerYear, TrailerManufacturer, TrailerVINSerialNumber
            )
		) as pivottable

		MERGE INTO [edw_core].[tquote_marine_boat_yacht_coverage] AS [Target]
		USING [edw_temp].[tquote_marine_boat_yacht_coverage_wip_temp1] as [Source]
		ON
		    [Target].quote_no = [Source].quote_no AND
		    [Target].effective_dt = [Source].effective_dt AND
		    [Target].transaction_seq_no = [Source].transaction_seq_no
		WHEN MATCHED THEN
		    UPDATE SET
		        [Target].effective_dt = [Source].effective_dt,
		        [Target].expiration_dt = [Source].expiration_dt,
		        [Target].quote_history_sk = [Source].quote_history_sk,
				[Target].quote_marine_boat_yacht_sk = [Source].[quote_marine_boat_yacht_sk],
				[Target].quote_marine_boat_yacht_location_sk = [Source].[quote_marine_boat_yacht_location_sk],
		        --
				[Target].[storage_location] = [Source].[storage_location],
				[Target].[distance_to_coast] = [Source].[distance_to_coast],
				[Target].[navigable_waters] = [Source].[navigable_waters],
				[Target].[layup_period_in] = [Source].[layup_period_in],
				[Target].[layup_period_start_dt] = [Source].[layup_period_start_dt],
				[Target].[layup_period_end_dt] = [Source].[layup_period_end_dt],
				[Target].[layup_factor] = [Source].[layup_factor],
				[Target].[no_of_prior_marine_claims] = [Source].[no_of_prior_marine_claims],
				[Target].[purchase_dt] = [Source].[purchase_dt],
				[Target].[active_tracking_device_in] = [Source].[active_tracking_device_in],
				[Target].[additional_personal_watercraft_in] = [Source].[additional_personal_watercraft_in],
				[Target].[manuscript_in] = [Source].[manuscript_in],
				[Target].[hull_value_limit_amt] = [Source].[hull_value_limit_amt],
				[Target].[liability_limit_amt] = [Source].[liability_limit_amt],
				[Target].[personal_effects_limit_amt] = [Source].[personal_effects_limit_amt],
				[Target].[opa_pollution_liability_limit_amt] = [Source].[opa_pollution_liability_limit_amt],
				[Target].[medical_payments_limit_amt] = [Source].[medical_payments_limit_amt],
				[Target].[uninsured_boater_limit_amt] = [Source].[uninsured_boater_limit_amt],
				[Target].[aop_deductible] = [Source].[aop_deductible],
				[Target].[windstorm_deductible] = [Source].[windstorm_deductible],
				[Target].[lightning_deductible] = [Source].[lightning_deductible],
				[Target].[theft_deductible] = [Source].[theft_deductible],
				[Target].[personal_effects_deductible] = [Source].[personal_effects_deductible],
				[Target].[opa_pollution_deductible] = [Source].[opa_pollution_deductible],
				[Target].[uninsured_boater_deductible] = [Source].[uninsured_boater_deductible],
				[Target].[medical_payments_deductible] = [Source].[medical_payments_deductible],
				[Target].[trailer_value_excess_of_5k_in] = [Source].[trailer_value_excess_of_5k_in],
				[Target].[trailer_value] = [Source].[trailer_value],
				[Target].[trailer_deductible] = [Source].[trailer_deductible],
				[Target].[trailer_year] = [Source].[trailer_year],
				[Target].[trailer_manufacturer_nm] = [Source].[trailer_manufacturer_nm],
				[Target].[trailer_vin] = [Source].[trailer_vin],
				--
				[Target].[premium_adjustment_method] = [Source].[premium_adjustment_method],
				[Target].[premium_adjustment_factor] = [Source].[premium_adjustment_factor],
				[Target].[premium_adjustment_retention] = [Source].[premium_adjustment_retention],
				[Target].[premium_adjustment_retention_reason] = [Source].[premium_adjustment_retention_reason],
				--
		        [Target].source_system_sk = [Source].source_system_sk,
		        [Target].update_ts = [Source].update_ts,
		        [Target].etl_audit_sk = [Source].etl_audit_sk
		WHEN NOT MATCHED BY Target THEN
		INSERT
		(
            [quote_no], [effective_dt], [expiration_dt], [transaction_seq_no], [quote_history_sk], [quote_marine_boat_yacht_location_sk], [quote_marine_boat_yacht_sk], [storage_location], [distance_to_coast], [navigable_waters], [layup_period_in], [layup_period_start_dt], [layup_period_end_dt], [layup_factor], [no_of_prior_marine_claims], [purchase_dt], [active_tracking_device_in], [additional_personal_watercraft_in], [manuscript_in], [hull_value_limit_amt], [liability_limit_amt], [personal_effects_limit_amt], [opa_pollution_liability_limit_amt], [medical_payments_limit_amt], [uninsured_boater_limit_amt], [aop_deductible], [windstorm_deductible], [lightning_deductible], [theft_deductible], [personal_effects_deductible], [opa_pollution_deductible], [uninsured_boater_deductible], [medical_payments_deductible], [trailer_value_excess_of_5k_in], [trailer_value], [trailer_deductible], [trailer_year], [trailer_manufacturer_nm], [trailer_vin], [source_system_sk], [create_ts], [update_ts], [etl_audit_sk], [premium_adjustment_method], [premium_adjustment_factor], [premium_adjustment_retention], [premium_adjustment_retention_reason]		
			
		)
		VALUES
		(
			[Source].[quote_no], [Source].[effective_dt], [Source].[expiration_dt], [Source].[transaction_seq_no], [Source].[quote_history_sk], [Source].[quote_marine_boat_yacht_location_sk], [Source].[quote_marine_boat_yacht_sk], [Source].[storage_location], [Source].[distance_to_coast], [Source].[navigable_waters], [Source].[layup_period_in], [Source].[layup_period_start_dt], [Source].[layup_period_end_dt], [Source].[layup_factor], [Source].[no_of_prior_marine_claims], [Source].[purchase_dt], [Source].[active_tracking_device_in], [Source].[additional_personal_watercraft_in], [Source].[manuscript_in], [Source].[hull_value_limit_amt], [Source].[liability_limit_amt], [Source].[personal_effects_limit_amt], [Source].[opa_pollution_liability_limit_amt], [Source].[medical_payments_limit_amt], [Source].[uninsured_boater_limit_amt], [Source].[aop_deductible], [Source].[windstorm_deductible], [Source].[lightning_deductible], [Source].[theft_deductible], [Source].[personal_effects_deductible], [Source].[opa_pollution_deductible], [Source].[uninsured_boater_deductible], [Source].[medical_payments_deductible], [Source].[trailer_value_excess_of_5k_in], [Source].[trailer_value], [Source].[trailer_deductible], [Source].[trailer_year], [Source].[trailer_manufacturer_nm], [Source].[trailer_vin], [Source].[source_system_sk], [Source].[create_ts], [Source].[update_ts], [Source].[etl_audit_sk], [premium_adjustment_method], [premium_adjustment_factor], [premium_adjustment_retention], [premium_adjustment_retention_reason]	
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_marine_boat_yacht_coverage_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_coverage_wip_temp1
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