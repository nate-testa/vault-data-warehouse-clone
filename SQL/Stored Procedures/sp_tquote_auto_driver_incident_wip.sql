SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
-- ================================================================================================================================================
-- Description: This stored procedure inserts and updates info related to quote auto driver incident - wip
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 05/06/24		Alberto Almario					1. Created the proc
-- 05/08/24		Architha Gudimalla				2. Updated @last_source_extract_ts
-- 05/14/24		Architha Gudimalla				3. Corrected errors
-- 06/09/2024   Yunus Mohammed                  4. Corrcted insert statement
-- 08/07/24		Hernnando Gonzalez		        5. Added new field IncreasePremiumOnRenewal
-- 08/21/24		Alberto Almario					6. Remove effective_dt from merge join and add into update section
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_driver_incident_wip]
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

        -- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_driver_incident_wip_temp1];

		SELECT 
			CreatedDate, UpdatedDate, quote_no, effective_dt, expiration_dt, 0 as transaction_seq_no, quote_history_sk, quote_auto_driver_sk, driver_no, incident_no,
            [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], [TotalPayout], [IsDisputed], [IncludeInRate], [IncidentCode], [IncidentStatus], [BodilyInjuryPayment], 
            [CollisionPayment], [ComprehensivePayment], [GlassPayment], [MedicalExpensePayment], [MedicalPaymentPayment], [OtherPayment], [PropertyDamagePayment], [PersonalInjuryProtectionPayment], 
            [RentalReimbursementPayment], [SpousalLiabilityPayment], [TowingAndLaborPayment], [UninsuredMotoristPayment], [UnderinsuredMotoristPayment], [LendingLoss], [PIPClaimOverride], [IncreasePremiumOnRenewal],
			source_system_sk  
		
        INTO [edw_temp].[tquote_auto_driver_incident_wip_temp1]
		
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, 
                    acc.ExpirationDate as expiration_dt, --acc.Number as transaction_seq_no,
                    qh.quote_history_sk, qad.quote_auto_driver_sk, qad.driver_no, acco.[Index] as incident_no,
                    accof.[Field], accof.[Value],
                    CASE 
                        WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (
                        SELECT *
                        FROM [edw_stage].[Account] AS a
                        WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                    ) acc
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                INNER JOIN [edw_stage].[AccountObject] AS pid ON acco.parentobjectid = pid.Id
                LEFT JOIN [edw_core].[tquote_history] AS qh  ON qh.quote_no = acc.PolicyNumber AND qh.effective_dt = acc.EffectiveDate AND qh.transaction_seq_no = 0
                LEFT JOIN [edw_core].[tquote_auto_driver] AS qad ON qad.quote_no = acc.PolicyNumber AND qad.effective_dt = acc.EffectiveDate AND qad.transaction_seq_no = 0 and qad.driver_no=pid.[index]
                WHERE p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Incidents in the Past 5 Years')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], [TotalPayout], [IsDisputed], [IncludeInRate], [IncidentCode], [IncidentStatus], [BodilyInjuryPayment], 
                    [CollisionPayment], [ComprehensivePayment], [GlassPayment], [MedicalExpensePayment], [MedicalPaymentPayment], [OtherPayment], [PropertyDamagePayment], [PersonalInjuryProtectionPayment], 
                    [RentalReimbursementPayment], [SpousalLiabilityPayment], [TowingAndLaborPayment], [UninsuredMotoristPayment], [UnderinsuredMotoristPayment], [LendingLoss], [PIPClaimOverride], [IncreasePremiumOnRenewal]
                )
			) pivottable

		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_driver_incident] AS target
        USING [edw_temp].[tquote_auto_driver_incident_wip_temp1] AS source
            ON target.quote_no = source.quote_no
            AND target.driver_no = source.driver_no
            AND target.incident_no = source.incident_no
            AND target.transaction_seq_no = source.transaction_seq_no
        WHEN MATCHED THEN
            UPDATE SET
                target.effective_dt = source.effective_dt,
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.quote_auto_driver_sk = source.quote_auto_driver_sk,
                target.incident_source = source.[IncidentSource],
                target.incident_dt = source.[IncidentDate],
                target.incident_type = source.[IncidentType],
                target.incident_description = source.[IncidentDescription],
                target.total_payout_amt = NULLIF(source.[TotalPayout], ''),
                target.is_disputed_in = source.[IsDisputed],
                target.include_in_rate_in = source.[IncludeInRate],
                target.violation_point_class = source.[IncidentCode],
                target.incident_status = source.[IncidentStatus],
                target.bodily_injury_payment = source.[BodilyInjuryPayment],
                target.collision_payment = source.[CollisionPayment],
                target.comprehensive_payment = source.[ComprehensivePayment],
                target.glass_payment = source.[GlassPayment],
                target.medical_expense_payment = source.[MedicalExpensePayment],
                target.medical_payment = source.[MedicalPaymentPayment],
                target.other_payment = source.[OtherPayment],
                target.property_damage_payment = source.[PropertyDamagePayment],
                target.personal_injury_protection_payment = source.[PersonalInjuryProtectionPayment],
                target.rental_reimbursement_payment = source.[RentalReimbursementPayment],
                target.spousal_liability_payment = source.[SpousalLiabilityPayment],
                target.towing_and_labor_payment = source.[TowingAndLaborPayment],
                target.uninsured_motorist_payment = source.[UninsuredMotoristPayment],
                target.underinsured_motorist_payment = source.[UnderinsuredMotoristPayment],
                target.source_system_sk = source.source_system_sk,
                target.update_ts = GETDATE(),
                target.etl_audit_sk = @etl_audit_sk,
                target.lending_loss_in = source.[LendingLoss],
                target.pip_claim_override_in = source.[PIPClaimOverride],
                target.increase_premium_on_renewal_in = source.[IncreasePremiumOnRenewal]
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no,
                effective_dt,
                expiration_dt,
                transaction_seq_no,
                quote_history_sk,
                quote_auto_driver_sk,
                driver_no,
                incident_no,
                incident_source,
                incident_dt,
                incident_type,
                incident_description,
                total_payout_amt,
                is_disputed_in,
                include_in_rate_in,
                violation_point_class,
                incident_status,
                bodily_injury_payment,
                collision_payment,
                comprehensive_payment,
                glass_payment,
                medical_expense_payment,
                medical_payment,
                other_payment,
                property_damage_payment,
                personal_injury_protection_payment,
                rental_reimbursement_payment,
                spousal_liability_payment,
                towing_and_labor_payment,
                uninsured_motorist_payment,
                underinsured_motorist_payment,
                source_system_sk,
                create_ts,
                update_ts,
                etl_audit_sk,
                lending_loss_in,
                pip_claim_override_in,
                increase_premium_on_renewal_in
            )
            VALUES (
                source.quote_no,
                source.effective_dt,
                source.expiration_dt,
                source.transaction_seq_no,
                source.quote_history_sk,
                source.quote_auto_driver_sk,
                source.driver_no,
                source.incident_no,
                source.[IncidentSource],
                source.[IncidentDate],
                source.[IncidentType],
                source.[IncidentDescription],
                NULLIF(source.[TotalPayout], ''),
                source.[IsDisputed],
                source.[IncludeInRate],
                source.[IncidentCode],
                source.[IncidentStatus],
                source.[BodilyInjuryPayment],
                source.[CollisionPayment],
                source.[ComprehensivePayment],
                source.[GlassPayment],
                source.[MedicalExpensePayment],
                source.[MedicalPaymentPayment],
                source.[OtherPayment],
                source.[PropertyDamagePayment],
                source.[PersonalInjuryProtectionPayment],
                source.[RentalReimbursementPayment],
                source.[SpousalLiabilityPayment],
                source.[TowingAndLaborPayment],
                source.[UninsuredMotoristPayment],
                source.[UnderinsuredMotoristPayment],                
                source.source_system_sk,
                GETDATE(),
                GETDATE(),
                @etl_audit_sk,
                source.[LendingLoss],
                source.[PIPClaimOverride],
                source.[IncreasePremiumOnRenewal]
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(CreatedDate,UpdatedDate)) FROM edw_temp.[tquote_auto_driver_incident_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_driver_incident_wip_temp1];

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
GO
