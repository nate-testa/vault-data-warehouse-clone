SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================================================================
-- Description: This stored procedure insert and update info related to tauto_driver_incident.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/15/23		Alberto Almario					1. Created the proc
-- 03/01/24     Architha Gudimalla              2. Updated the logic to use parent object id to get the correct driver no with the incidents
-- 08/07/24		Hernnando Gonzalez		        3. Added new field IncreasePremiumOnRenewal
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_driver_incident] 
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_driver_incident_temp1];

		SELECT 
			IssuedDate, policy_no, effective_dt, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, policy_history_sk, auto_driver_sk, driver_no, incident_no,
            [IncidentSource], [IncidentDate], [IncidentType], [IncidentDescription], [TotalPayout], [IsDisputed], [IncludeInRate], [IncidentCode], [IncidentStatus], [BodilyInjuryPayment], 
            [CollisionPayment], [ComprehensivePayment], [GlassPayment], [MedicalExpensePayment], [MedicalPaymentPayment], [OtherPayment], [PropertyDamagePayment], [PersonalInjuryProtectionPayment], 
            [RentalReimbursementPayment], [SpousalLiabilityPayment], [TowingAndLaborPayment], [UninsuredMotoristPayment], [UnderinsuredMotoristPayment], [LendingLoss], [PIPClaimOverride], [IncreasePremiumOnRenewal],
			source_system_sk 
		
        INTO [edw_temp].[tauto_driver_incident_temp1]
		
        FROM
			(
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                    ph.policy_history_sk, ad.auto_driver_sk, ad.driver_no, acctvo.[Index] as incident_no,
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                (
                    SELECT *
                    FROM [edw_stage].[AccountTransaction]
                    WHERE [State] = 'ISSUED'
                        AND IssuedDate > @last_source_extract_ts
                ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id  
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS pid ON acctvo.parentobjectid = pid.Id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph ON ph.policy_no = acct.PolicyNumber AND ph.effective_dt = acct.EffectiveDate AND ph.transaction_seq_no = acct.policychangenumber
                LEFT JOIN [edw_core].[tauto_driver] AS ad ON ad.policy_no = acct.PolicyNumber AND ad.effective_dt = acct.EffectiveDate AND ad.transaction_seq_no = acct.policychangenumber and ad.driver_no=pid.[index]
                WHERE   p.[Name] = 'Automobile'
                AND     p.ProductLine = 'PersonalLines'
                AND     acctvof.[Group] in ('Incidents in the Past 5 Years') 
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

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_driver_incident]
        (
            policy_no, 
            effective_dt, 
            transaction_effective_dt, 
            expiration_dt, 
            transaction_dt, 
            transaction_seq_no, 
            policy_history_sk, 
            auto_driver_sk, 
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
        SELECT 
            t1.policy_no, 
            t1.effective_dt, 
            t1.transaction_effective_dt, 
            t1.expiration_dt, 
            t1.transaction_dt, 
            t1.transaction_seq_no, 
            t1.policy_history_sk, 
            t1.auto_driver_sk, 
            t1.driver_no, 
            t1.incident_no, 
            t1.[IncidentSource] as incident_source, 
            t1.[IncidentDate] as incident_dt, 
            t1.[IncidentType] as incident_type, 
            t1.[IncidentDescription] as incident_description, 
            CASE WHEN t1.[TotalPayout] = '' THEN NULL ELSE t1.[TotalPayout] END as total_payout_amt, 
            t1.[IsDisputed] as is_disputed_in, 
            t1.[IncludeInRate] as include_in_rate_in, 
            t1.[IncidentCode] as violation_point_class, 
            t1.[IncidentStatus] as incident_status, 
            t1.[BodilyInjuryPayment] as bodily_injury_payment, 
            t1.[CollisionPayment] as collision_payment, 
            t1.[ComprehensivePayment] as comprehensive_payment, 
            t1.[GlassPayment] as glass_payment, 
            t1.[MedicalExpensePayment] as medical_expense_payment, 
            t1.[MedicalPaymentPayment] as medical_payment, 
            t1.[OtherPayment] as other_payment, 
            t1.[PropertyDamagePayment] as property_damage_payment, 
            t1.[PersonalInjuryProtectionPayment] as personal_injury_protection_payment, 
            t1.[RentalReimbursementPayment] as rental_reimbursement_payment, 
            t1.[SpousalLiabilityPayment] as spousal_liability_payment, 
            t1.[TowingAndLaborPayment] as towing_and_labor_payment, 
            t1.[UninsuredMotoristPayment] as uninsured_motorist_payment, 
            t1.[UnderinsuredMotoristPayment] as underinsured_motorist_payment, 
            t1.source_system_sk, 
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk,
            t1.[LendingLoss] as lending_loss_in,
            t1.PIPClaimOverride as pip_claim_override_in,
            t1.[IncreasePremiumOnRenewal] as increase_premium_on_renewal_in
        FROM 
            [edw_temp].[tauto_driver_incident_temp1] AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_driver_incident_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_driver_incident_temp1];

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
