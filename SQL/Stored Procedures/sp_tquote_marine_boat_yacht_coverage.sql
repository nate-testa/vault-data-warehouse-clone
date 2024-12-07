-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/22/24		    Hernando Gonzalez			1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_coverage]

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
		
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_coverage_temp1
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
			--
		INTO edw_temp.tquote_marine_boat_yacht_coverage_temp1
		FROM
		(
			SELECT * 
			FROM
			(
				SELECT			
				act.PolicyNumber
				,CAST(act.EffectiveDate as DATE) as EffectiveDate
				,CAST(act.ExpirationDate as DATE) as ExpirationDate
				,act.[Number] as transaction_seq_no
				,tqh.quote_history_sk
				,CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk
				,atvo.[index]
				,atvof.Field
				,atvof.[Value]
				,qmby.[quote_marine_boat_yacht_sk] --
				,qmbyl.[quote_marine_boat_yacht_location_sk] --
				,act.CreatedDate
				,atvpf.FactorMethod, atvpf.Factor, atvpf.Retention, atvpf.Reason
				FROM [edw_stage].[AccountTransaction] act
					INNER JOIN [edw_stage].[Product] pr on pr.Id = act.ProductId
					INNER JOIN [edw_stage].[AccountTransactionVersion] atv on act.Id = atv.AccountTransactionId
					INNER JOIN [edw_stage].[AccountTransactionVersionObject] atvo on atv.Id = atvo.AccountTransactionVersionId
					INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] atvof on atvo.Id = atvof.VersionObjectId
					LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] atvof_2 on atvof_2.ReferenceObjectId = atvo.id
					LEFT JOIN [edw_stage].[AccountTransactionVersionPremium] atvp on atvp.AccountTransactionVersionId = atv.Id
					LEFT JOIN [edw_stage].[AccountTransactionVersionPremiumfactor] atvpf on atvpf.AccountTransactionVersionPremiumId = atvp.Id
					LEFT JOIN [edw_core].[tquote_history] tqh on tqh.quote_no = act.PolicyNumber
							AND tqh.effective_dt = act.EffectiveDate
							AND tqh.transaction_seq_no = act.[Number]
					LEFT JOIN [edw_core].[tquote_marine_boat_yacht] qmby on qmby.quote_no = act.PolicyNumber
					LEFT JOIN [edw_core].[tquote_marine_boat_yacht_location] qmbyl on qmbyl.quote_no = act.PolicyNumber AND qmbyl.effective_dt = CAST(act.EffectiveDate as DATE) AND qmbyl.transaction_seq_no = act.[Number]
				WHERE
					act.PolicyNumber IS NOT NULL
					AND act.[Stage] IN ('QUOTE', 'POLICY')
					AND pr.[Name] = 'Marine Boat & Yacht'
					AND pr.ProductLine = 'PersonalLines'
					
					AND atvof.Field IN 
					(
						'Storage', 'DistanceToCoast', 'NavigableWaters', 'LayUpPeriod', 'LayUpPeriodStartDate', 'LayUpPeriodEndDate', 'LayUpFactor', 'NumberOfClaims', 'PurchaseDate', 'ActiveTrackingDevice', 'AddPersonalWatercraft', 'AddManuscript', 'HullValue', 'LiabilityLimit', 'PersonalEffectsLimit', 'OpaPollutionLiabilityLimit', 'MedicalPaymentLimit', 'UninsuredBoaterLimit', 'AopDeductible', 'WindstormDeductible', 'LightningDeductible', 'TheftDeductible', 'PersonalEffectsDeductible', 'OPAPollutionDeductible', 'UninsuredBoaterDeductible', 'MedicalPaymentsDeductible', 'IncludeTrailerCoverage', 'TrailerValue', 'TrailerDeductible', 'TrailerYear', 'TrailerManufacturer', 'TrailerVINSerialNumber'
					)
					AND act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN 
            (
                Storage, DistanceToCoast, NavigableWaters, LayUpPeriod, LayUpPeriodStartDate, LayUpPeriodEndDate, LayUpFactor, NumberOfClaims, PurchaseDate, ActiveTrackingDevice, AddPersonalWatercraft, AddManuscript, HullValue, LiabilityLimit, PersonalEffectsLimit, OpaPollutionLiabilityLimit, MedicalPaymentLimit, UninsuredBoaterLimit, AopDeductible, WindstormDeductible, LightningDeductible, TheftDeductible, PersonalEffectsDeductible, OPAPollutionDeductible, UninsuredBoaterDeductible, MedicalPaymentsDeductible, IncludeTrailerCoverage, TrailerValue, TrailerDeductible, TrailerYear, TrailerManufacturer, TrailerVINSerialNumber
            )
		) as pivottable

		INSERT INTO [edw_core].[tquote_marine_boat_yacht_coverage]
		(
            [quote_no], [effective_dt], [expiration_dt], [transaction_seq_no], [quote_history_sk], [quote_marine_boat_yacht_location_sk], [quote_marine_boat_yacht_sk], [storage_location], [distance_to_coast], [navigable_waters], [layup_period_in], [layup_period_start_dt], [layup_period_end_dt], [layup_factor], [no_of_prior_marine_claims], [purchase_dt], [active_tracking_device_in], [additional_personal_watercraft_in], [manuscript_in], [hull_value_limit_amt], [liability_limit_amt], [personal_effects_limit_amt], [opa_pollution_liability_limit_amt], [medical_payments_limit_amt], [uninsured_boater_limit_amt], [aop_deductible], [windstorm_deductible], [lightning_deductible], [theft_deductible], [personal_effects_deductible], [opa_pollution_deductible], [uninsured_boater_deductible], [medical_payments_deductible], [trailer_value_excess_of_5k_in], [trailer_value], [trailer_deductible], [trailer_year], [trailer_manufacturer_nm], [trailer_vin], [source_system_sk], [create_ts], [update_ts], [etl_audit_sk], [premium_adjustment_method], [premium_adjustment_factor], [premium_adjustment_retention], [premium_adjustment_retention_reason]	
			
		)
		SELECT
			[quote_no], [effective_dt], [expiration_dt], [transaction_seq_no], [quote_history_sk], [quote_marine_boat_yacht_location_sk], [quote_marine_boat_yacht_sk], [storage_location], [distance_to_coast], [navigable_waters], [layup_period_in], [layup_period_start_dt], [layup_period_end_dt], [layup_factor], [no_of_prior_marine_claims], [purchase_dt], [active_tracking_device_in], [additional_personal_watercraft_in], [manuscript_in], [hull_value_limit_amt], [liability_limit_amt], [personal_effects_limit_amt], [opa_pollution_liability_limit_amt], [medical_payments_limit_amt], [uninsured_boater_limit_amt], [aop_deductible], [windstorm_deductible], [lightning_deductible], [theft_deductible], [personal_effects_deductible], [opa_pollution_deductible], [uninsured_boater_deductible], [medical_payments_deductible], [trailer_value_excess_of_5k_in], [trailer_value], [trailer_deductible], [trailer_year], [trailer_manufacturer_nm], [trailer_vin], [source_system_sk], [create_ts], [update_ts], [etl_audit_sk], [premium_adjustment_method], [premium_adjustment_factor], [premium_adjustment_retention], [premium_adjustment_retention_reason]
		FROM
			edw_temp.tquote_marine_boat_yacht_coverage_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_marine_boat_yacht_coverage_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_coverage_temp1
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