SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 
-- ================================================================================================================================================
-- Description: This stored procedure inserts and updates info related to quote auto driver - wip
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 05/06/24		Alberto Almario					1. Created the proc
-- 05/08/24		Architha Gudimalla				2. Updated @last_source_extract_ts
-- 05/14/24		Architha Gudimalla				3. Corrected errors
-- 04/07/24		Hernnando Gonzalez		        4. Added new fields AAFFactor, AFBFactor, NAFFactor, CPAFactor, MINFactor, MAJFactor, SPDFactor
-- 08/07/24		Hernnando Gonzalez		    4. Added new field IncreasePremiumOnRenewal
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_driver_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_driver_wip_temp1];

		SELECT 
			CreatedDate, UpdatedDate, quote_no, effective_dt, expiration_dt, 0 as transaction_seq_no, driver_no, quote_history_sk, 
            [Prefix], [FirstName], [MiddleName], [LastName], [Suffix], [Birthdate], [Gender], [MaritalStatus], [RelationshipToInsured], [DriverStatus], [CertificationRequired], 
            [CertificationState], [DefensiveDriver], [TrainingDiscount], [LicenseStatus], [LicenseCountry], [LicenseState], [LicenseNumber], [LicenseYear], [AgeYearsLicensed], 
            [YearsLicensed], [UnverifiableDrivingRecord], [MultipleIncidentFactor], /*[**pending**-defensive_course_completed_in],*/ [PreventionCourseCompletedTwoYears], 
            [PreventionCourseCompleted], [PreventionCourseCompletionDate], [TrainingCourseCompleted], [GoodStudent], [AwayAtSchool], [MilitaryPersonnelDiscount], 
            [ArmyNationalGuardOrAirNationalGuardPersonnelDiscount], [MobileDeviceControlDiscount], [SeasonalUsePart1], [OccasionalOperatorDiscount], [AddReportedIncidents], 
            [SDIPPoints], [AAFWithVault], [AFBWithVault], [NAFWithVault], [CPAWithVault], [MINWithVault], [MAJWithVault], [SPDWithVault], [AAFPrior], [AFBPrior], [NAFPrior], 
            [CPAPrior], [MINPrior], [MAJPrior], [SPDPrior], [AAFFactor], [AFBFactor], [NAFFactor], [CPAFactor], [MINFactor], [MAJFactor], [SPDFactor], [IncreasePremiumOnRenewal],
			source_system_sk
		
        INTO [edw_temp].[tquote_auto_driver_wip_temp1]
		
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.UpdatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, acco.[Index] as driver_no, 
                    acc.ExpirationDate as expiration_dt, --acc.Number as transaction_seq_no,
                    qh.quote_history_sk,
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
                LEFT JOIN [edw_core].[tquote_history] AS qh 
                    ON qh.quote_no = acc.PolicyNumber
                    AND qh.effective_dt = acc.EffectiveDate
                    AND qh.transaction_seq_no = 0
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Driver', 'License', 'Accident Prevention Course', 'Driver Discount', 'Reported Incidents')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [Prefix], [FirstName], [MiddleName], [LastName], [Suffix], [Birthdate], [Gender], [MaritalStatus], [RelationshipToInsured], [DriverStatus], [CertificationRequired], 
                    [CertificationState], [DefensiveDriver], [TrainingDiscount], [LicenseStatus], [LicenseCountry], [LicenseState], [LicenseNumber], [LicenseYear], [AgeYearsLicensed], 
                    [YearsLicensed], [UnverifiableDrivingRecord], [MultipleIncidentFactor], /*[**pending**-defensive_course_completed_in],*/ [PreventionCourseCompletedTwoYears], 
                    [PreventionCourseCompleted], [PreventionCourseCompletionDate], [TrainingCourseCompleted], [GoodStudent], [AwayAtSchool], [MilitaryPersonnelDiscount], 
                    [ArmyNationalGuardOrAirNationalGuardPersonnelDiscount], [MobileDeviceControlDiscount], [SeasonalUsePart1], [OccasionalOperatorDiscount], [AddReportedIncidents], 
                    [SDIPPoints], [AAFWithVault], [AFBWithVault], [NAFWithVault], [CPAWithVault], [MINWithVault], [MAJWithVault], [SPDWithVault], [AAFPrior], [AFBPrior], [NAFPrior], 
                    [CPAPrior], [MINPrior], [MAJPrior], [SPDPrior], [AAFFactor], [AFBFactor], [NAFFactor], [CPAFactor], [MINFactor], [MAJFactor], [SPDFactor], [IncreasePremiumOnRenewal]
                )
			) pivottable

		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_driver] AS target
        USING [edw_temp].[tquote_auto_driver_wip_temp1] AS source
            ON target.quote_no = source.quote_no
            AND target.effective_dt = source.effective_dt
            AND target.driver_no = source.driver_no
            AND target.transaction_seq_no = source.transaction_seq_no
        WHEN MATCHED THEN
            UPDATE SET
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.prefix = source.[Prefix],
                target.first_nm = source.[FirstName],
                target.middle_nm = source.[MiddleName],
                target.last_nm = source.[LastName],
                target.suffix = source.[Suffix],
                target.birth_dt = source.[Birthdate],
                target.gender = source.[Gender],
                target.marital_status = source.[MaritalStatus],
                target.relationship_to_insured = source.[RelationshipToInsured],
                target.driver_status = source.[DriverStatus],
                target.sr22_certification_required_in = source.[CertificationRequired],
                target.sr22_certification_state_cd = source.[CertificationState],
                target.defensive_driver_in = source.[DefensiveDriver],
                target.training_discount_in = source.[TrainingDiscount],
                target.license_status = source.[LicenseStatus],
                target.license_country_nm = source.[LicenseCountry],
                target.license_state_nm = source.[LicenseState],
                target.license_no = source.[LicenseNumber],
                target.license_year = source.[LicenseYear],
                target.licensed_received_age = source.[AgeYearsLicensed],
                target.no_of_years_licensed = source.[YearsLicensed],
                target.unverifiable_driving_record_in = source.[UnverifiableDrivingRecord],
                target.multiple_incident_factor = source.[MultipleIncidentFactor],
                target.defensive_course_completed_in = NULL,
                target.defensive_course_completed_two_years_in = source.[PreventionCourseCompletedTwoYears],
                target.defensive_course_completed_three_years_in = source.[PreventionCourseCompleted],
                target.defensive_course_completion_dt = source.[PreventionCourseCompletionDate],
                target.training_course_completed_in = source.[TrainingCourseCompleted],
                target.good_student_in = source.[GoodStudent],
                target.away_at_school_in = source.[AwayAtSchool],
                target.military_personnel_discount_in = source.[MilitaryPersonnelDiscount],
                target.army_national_guard_personnel_discount_in = source.[ArmyNationalGuardOrAirNationalGuardPersonnelDiscount],
                target.mobile_device_control_discount_in = source.[MobileDeviceControlDiscount],
                target.seasonal_use_part_in = source.[SeasonalUsePart1],
                target.occasional_operator_discount = source.[OccasionalOperatorDiscount],
                target.reported_incidents_ct = source.[AddReportedIncidents],
                target.sdip_points_no = source.[SDIPPoints],
                target.aaf_with_vault_ct = source.[AAFWithVault],
                target.afb_with_vault_ct = source.[AFBWithVault],
                target.naf_with_vault_ct = source.[NAFWithVault],
                target.cpa_with_vault_ct = source.[CPAWithVault],
                target.min_with_vault_ct = source.[MINWithVault],
                target.maj_with_vault_ct = source.[MAJWithVault],
                target.spd_with_vault_ct = source.[SPDWithVault],
                target.aaf_prior_ct = source.[AAFPrior],
                target.afb_prior_ct = source.[AFBPrior],
                target.naf_prior_ct = source.[NAFPrior],
                target.cpa_prior_ct = source.[CPAPrior],
                target.min_prior_ct = source.[MINPrior],
                target.maj_prior_ct = source.[MAJPrior],
                target.spd_prior_ct = source.[SPDPrior],
                target.aaf_factor = source.[AAFFactor],
                target.afb_factor = source.[AFBFactor],
                target.naf_factor = source.[NAFFactor],
                target.cpa_factor = source.[CPAFactor],
                target.min_factor = source.[MINFactor],
                target.maj_factor = source.[MAJFactor],
                target.sdp_factor = source.[SPDFactor],
                target.increase_premium_on_renewal_in = source.[IncreasePremiumOnRenewal],
                target.source_system_sk = source.source_system_sk,
                target.update_ts = GETDATE(),
                target.etl_audit_sk = @etl_audit_sk
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no,
                effective_dt,
                expiration_dt,
                transaction_seq_no,
                driver_no,
                quote_history_sk,
                prefix,
                first_nm,
                middle_nm,
                last_nm,
                suffix,
                birth_dt,
                gender,
                marital_status,
                relationship_to_insured,
                driver_status,
                sr22_certification_required_in,
                sr22_certification_state_cd,
                defensive_driver_in,
                training_discount_in,
                license_status,
                license_country_nm,
                license_state_nm,
                license_no,
                license_year,
                licensed_received_age,
                no_of_years_licensed,
                unverifiable_driving_record_in,
                multiple_incident_factor,
                defensive_course_completed_in,
                defensive_course_completed_two_years_in,
                defensive_course_completed_three_years_in,
                defensive_course_completion_dt,
                training_course_completed_in,
                good_student_in,
                away_at_school_in,
                military_personnel_discount_in,
                army_national_guard_personnel_discount_in,
                mobile_device_control_discount_in,
                seasonal_use_part_in,
                occasional_operator_discount,
                reported_incidents_ct,
                sdip_points_no,
                aaf_with_vault_ct,
                afb_with_vault_ct,
                naf_with_vault_ct,
                cpa_with_vault_ct,
                min_with_vault_ct,
                maj_with_vault_ct,
                spd_with_vault_ct,
                aaf_prior_ct,
                afb_prior_ct,
                naf_prior_ct,
                cpa_prior_ct,
                min_prior_ct,
                maj_prior_ct,
                spd_prior_ct,
                aaf_factor,
                afb_factor,
                naf_factor,
                cpa_factor,
                min_factor,
                maj_factor,
                sdp_factor,
                increase_premium_on_renewal_in,
                source_system_sk,
                create_ts,
                update_ts,
                etl_audit_sk
            )
            VALUES (
                source.quote_no,
                source.effective_dt,
                source.expiration_dt,
                source.transaction_seq_no,
                source.driver_no,
                source.quote_history_sk,
                source.[Prefix],
                source.[FirstName],
                source.[MiddleName],
                source.[LastName],
                source.[Suffix],
                source.[Birthdate],
                source.[Gender],
                source.[MaritalStatus],
                source.[RelationshipToInsured],
                source.[DriverStatus],
                source.[CertificationRequired],
                source.[CertificationState],
                source.[DefensiveDriver],
                source.[TrainingDiscount],
                source.[LicenseStatus],
                source.[LicenseCountry],
                source.[LicenseState],
                source.[LicenseNumber],
                source.[LicenseYear],
                source.[AgeYearsLicensed],
                source.[YearsLicensed],
                source.[UnverifiableDrivingRecord],
                source.[MultipleIncidentFactor],
                NULL,
                source.[PreventionCourseCompletedTwoYears],
                source.[PreventionCourseCompleted],
                source.[PreventionCourseCompletionDate],
                source.[TrainingCourseCompleted],
                source.[GoodStudent],
                source.[AwayAtSchool],
                source.[MilitaryPersonnelDiscount],
                source.[ArmyNationalGuardOrAirNationalGuardPersonnelDiscount],
                source.[MobileDeviceControlDiscount],
                source.[SeasonalUsePart1],
                source.[OccasionalOperatorDiscount],
                source.[AddReportedIncidents],
                source.[SDIPPoints],
                source.[AAFWithVault],
                source.[AFBWithVault],
                source.[NAFWithVault],
                source.[CPAWithVault],
                source.[MINWithVault],
                source.[MAJWithVault],
                source.[SPDWithVault],
                source.[AAFPrior],
                source.[AFBPrior],
                source.[NAFPrior],
                source.[CPAPrior],
                source.[MINPrior],
                source.[MAJPrior],
                source.[SPDPrior],
                source.[AAFFactor],
                source.[AFBFactor],
                source.[NAFFactor],
                source.[CPAFactor],
                source.[MINFactor],
                source.[MAJFactor],
                source.[SPDFactor],
                source.[IncreasePremiumOnRenewal],
                source.source_system_sk,
                GETDATE(),
                GETDATE(),
                @etl_audit_sk
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(Greatest(CreatedDate,UpdatedDate)) FROM edw_temp.[tquote_auto_driver_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_driver_wip_temp1];

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
