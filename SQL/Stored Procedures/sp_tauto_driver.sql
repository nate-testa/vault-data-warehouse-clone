SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==============================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-14
-- Description: This stored procedure insert and update info related to tauto_driver.
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/14/23		Alberto Almario			    1. Created this procedure
-- 01/08/24		Yunus Mohammed			    2. Added driver_deleted_in flag
-- 22/02/24		Hernnando Gonzalez		    3. Added new field lending_loss_amt
-- 04/07/24		Hernnando Gonzalez		    4. Added new fields AAFFactor, AFBFactor, NAFFactor, CPAFactor, MINFactor, MAJFactor, SPDFactor
-- 22/08/24		Hernnando Gonzalez		    5. Added auto_vehicle_sk
-- 10/22/24		Architha Gudimalla		    6. Added excluded driver - AD6949
-- ==============================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_driver]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_driver_temp1];

		SELECT 
			IssuedDate, policy_no, effective_dt, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, driver_no, policy_history_sk, VersionObjectId,
            [Prefix], [FirstName], [MiddleName], [LastName], [Suffix], [Birthdate], [Gender], [MaritalStatus], [RelationshipToInsured], [DriverStatus], [CertificationRequired], 
            [CertificationState], [DefensiveDriver], [TrainingDiscount], [LicenseStatus], [LicenseCountry], [LicenseState], [LicenseNumber], [LicenseYear], [AgeYearsLicensed], 
            [YearsLicensed], [UnverifiableDrivingRecord], [MultipleIncidentFactor], /*[**pending**-defensive_course_completed_in],*/ [PreventionCourseCompletedTwoYears], 
            [PreventionCourseCompleted], [PreventionCourseCompletionDate], [TrainingCourseCompleted], [GoodStudent], [AwayAtSchool], [MilitaryPersonnelDiscount], 
            [ArmyNationalGuardOrAirNationalGuardPersonnelDiscount], [MobileDeviceControlDiscount], [SeasonalUsePart1], [OccasionalOperatorDiscount], [AddReportedIncidents], 
            [SDIPPoints], [AAFWithVault], [AFBWithVault], [NAFWithVault], [CPAWithVault], [MINWithVault], [MAJWithVault], [SPDWithVault], [AAFPrior], [AFBPrior], [NAFPrior], 
            [CPAPrior], [MINPrior], [MAJPrior], [SPDPrior], [AAFFactor], [AFBFactor], [NAFFactor], [CPAFactor], [MINFactor], [MAJFactor], [SPDFactor], [PrimaryVehicleId],
			source_system_sk,CASE IsDeletedOnPolicyChange WHEN 0 THEN 'No' WHEN 1 THEN 'Yes' END AS IsDeletedOnPolicyChange
        INTO [edw_temp].[tauto_driver_temp1]
        FROM
			(
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acctvo.[Index] as driver_no, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no,
                    ph.policy_history_sk,
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk],
                    acctvo.IsDeletedOnPolicyChange, acctvof.VersionObjectId
                FROM
                    (SELECT
                        *
                    FROM [edw_stage].[AccountTransaction]
                    WHERE [State] = 'ISSUED'
                        AND IssuedDate > @last_source_extract_ts
                    ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                    ON ph.policy_no = acct.PolicyNumber
                    AND ph.effective_dt = acct.EffectiveDate
                    AND ph.transaction_seq_no = acct.policychangenumber
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Driver', 'License', 'Accident Prevention Course', 'Driver Discount', 'Reported Incidents')
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
                    [CPAPrior], [MINPrior], [MAJPrior], [SPDPrior], [AAFFactor], [AFBFactor], [NAFFactor], [CPAFactor], [MINFactor], [MAJFactor], [SPDFactor], [PrimaryVehicleId]
                )
			) pivottable 

		DROP TABLE IF EXISTS [edw_temp].tauto_driver_temp2;

		SELECT 
			policy_no, effective_dt, transaction_seq_no, driver_no, VersionObjectId,  
            ExcludedDriverId,ExcludedDriverAllVehicles,ExcludedDriverSelectVehicles,cast(null as varchar(max)) vehicle_list
        INTO [edw_temp].tauto_driver_temp2
        FROM
			(
                SELECT
                    acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acctvo.[Index] as driver_no,
					acct.PolicyChangeNumber as transaction_seq_no,
                    acctvof.[Field], acctvof.[Value] , acctvof.VersionObjectId
                FROM
                    (SELECT
                        *
                    FROM [edw_stage].[AccountTransaction]
                    WHERE [State] = 'ISSUED' 
                        AND IssuedDate > @last_source_extract_ts
                    ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id 
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvo.ObjectType in ('Driver','ExcludedDriver') 
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    ExcludedDriverId,ExcludedDriverAllVehicles,ExcludedDriverSelectVehicles
                )
			) pivottable ;

        DECLARE @VehList varchar(max)
		DECLARE @VehNameList varchar(max)
		DECLARE @VehUniqId varchar(255)
		DECLARE @VersionObjectId int
		DECLARE @temp varchar(max)
		
		DECLARE c1_rec CURSOR
		FOR  
		select ExcludedDriverSelectVehicles ,VersionObjectId
		from [edw_temp].tauto_driver_temp2
		where ExcludedDriverSelectVehicles is not null 
		order by 1; 

		open c1_rec; 
		FETCH NEXT FROM c1_rec INTO @VehList, @VersionObjectId; 
		WHILE @@FETCH_STATUS = 0
			BEGIN   
				print @VehList

				DECLARE c2_rec CURSOR
				FOR
				SELECT value
				FROM STRING_SPLIT(@VehList, ',')
				order by 1;

				set @VehNameList = '';

				open c2_rec; 
				FETCH NEXT FROM c2_rec INTO @VehUniqId; 
				WHILE @@FETCH_STATUS = 0
					BEGIN   
						select  @temp = v.vehicle_model_year || ' ' || v.vehicle_make || ' ' || v.vehicle_model || ', '
						from edw_core.tauto_vehicle v where vehicle_unique_id = @VehUniqId;

						set @VehNameList = @VehNameList || @temp;
							 
						--print @VehUniqId 
						--print @VehNameList 
						--print @VersionObjectId

						FETCH NEXT FROM c2_rec INTO @VehUniqId;  
					END; 
				CLOSE c2_rec;
				DEALLOCATE c2_rec;   

				update [edw_temp].tauto_driver_temp2
				set vehicle_list = stuff(@VehNameList,len(@VehNameList),1,'')
				where VersionObjectId = @VersionObjectId
								 
				FETCH NEXT FROM c1_rec INTO @VehList, @VersionObjectId;  
			END; 
		CLOSE c1_rec;
		DEALLOCATE c1_rec;  

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_driver]
        (
            policy_no,
            effective_dt,
            transaction_effective_dt,
            expiration_dt,
            transaction_dt,
            transaction_seq_no,
            driver_no,
            policy_history_sk,
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
            driver_deleted_in,
            aaf_factor,
            afb_factor,
            naf_factor,
            cpa_factor,
            min_factor,
            maj_factor,
            sdp_factor,
            primary_auto_vehicle_sk,
            source_system_sk,
            create_ts,
            update_ts,
            etl_audit_sk
            , excluded_driver_in
            , excluded_driver_for_all_vehicles_in
            , excluded_driver_for_listed_vehicles
		)
        SELECT 
            t1.policy_no,
            t1.effective_dt,
            t1.transaction_effective_dt,
            t1.expiration_dt,
            t1.transaction_dt,
            t1.transaction_seq_no,
            t1.driver_no,
            t1.policy_history_sk,
            t1.[Prefix] as prefix,
            t1.[FirstName] as first_nm,
            t1.[MiddleName] as middle_nm,
            t1.[LastName] as last_nm,
            t1.[Suffix] as suffix,
            t1.[Birthdate] as birth_dt,
            t1.[Gender] as gender,
            t1.[MaritalStatus] as marital_status,
            t1.[RelationshipToInsured] as relationship_to_insured,
            t1.[DriverStatus] as driver_status,
            t1.[CertificationRequired] as sr22_certification_required_in,
            t1.[CertificationState] as sr22_certification_state_cd,
            t1.[DefensiveDriver] as defensive_driver_in,
            t1.[TrainingDiscount] as training_discount_in,
            t1.[LicenseStatus] as license_status,
            t1.[LicenseCountry] as license_country_nm,
            t1.[LicenseState] as license_state_nm,
            t1.[LicenseNumber] as license_no,
            t1.[LicenseYear] as license_year,
            t1.[AgeYearsLicensed] as licensed_received_age,
            t1.[YearsLicensed] as no_of_years_licensed,
            t1.[UnverifiableDrivingRecord] as unverifiable_driving_record_in,
            t1.[MultipleIncidentFactor] as multiple_incident_factor,
            NULL as defensive_course_completed_in,
            t1.[PreventionCourseCompletedTwoYears] as defensive_course_completed_two_years_in,
            t1.[PreventionCourseCompleted] as defensive_course_completed_three_years_in,
            t1.[PreventionCourseCompletionDate] as defensive_course_completion_dt,
            t1.[TrainingCourseCompleted] as training_course_completed_in,
            t1.[GoodStudent] as good_student_in,
            t1.[AwayAtSchool] as away_at_school_in,
            t1.[MilitaryPersonnelDiscount] as military_personnel_discount_in,
            t1.[ArmyNationalGuardOrAirNationalGuardPersonnelDiscount] asarmy_national_guard_personnel_discount_in,
            t1.[MobileDeviceControlDiscount] as mobile_device_control_discount_in,
            t1.[SeasonalUsePart1] as seasonal_use_part_in,
            t1.[OccasionalOperatorDiscount] as occasional_operator_discount,
            t1.[AddReportedIncidents] as reported_incidents_ct,
            t1.[SDIPPoints] as sdip_points_no,
            t1.[AAFWithVault] as aaf_with_vault_ct,
            t1.[AFBWithVault] as afb_with_vault_ct,
            t1.[NAFWithVault] as naf_with_vault_ct,
            t1.[CPAWithVault] as cpa_with_vault_ct,
            t1.[MINWithVault] as min_with_vault_ct,
            t1.[MAJWithVault] as maj_with_vault_ct,
            t1.[SPDWithVault] as spd_with_vault_ct,
            t1.[AAFPrior] as aaf_prior_ct,
            t1.[AFBPrior] as afb_prior_ct,
            t1.[NAFPrior] as naf_prior_ct,
            t1.[CPAPrior] as cpa_prior_ct,
            t1.[MINPrior] as min_prior_ct,
            t1.[MAJPrior] as maj_prior_ct,
            t1.[SPDPrior] as spd_prior_ct,
            t1.IsDeletedOnPolicyChange as driver_deleted_in,
            t1.[AAFFactor] as aaf_factor,
            t1.[AFBFactor] as afb_factor,
            t1.[NAFFactor] as naf_factor,
            t1.[CPAFactor] as cpa_factor,
            t1.[MINFactor] as min_factor,
            t1.[MAJFactor] as maj_factor,
            t1.[SPDFactor] as sdp_factor,
            taut.[auto_vehicle_sk] as primary_auto_vehicle_sk,
            t1.source_system_sk,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
            , case when b.ExcludedDriverId is not null then 'Yes' else 'No' end
            , b.ExcludedDriverAllVehicles
            , b.vehicle_list
        FROM [edw_temp].[tauto_driver_temp1] AS t1
        LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acctvo	on acctvo.Id = TRY_CAST(t1.[PrimaryVehicleId] AS INT)
        LEFT JOIN [edw_core].[tauto_vehicle] taut   ON taut.vehicle_unique_id = acctvo.UniqueId
                                                    AND taut.policy_no = t1.policy_no
                                                    AND taut.effective_dt = t1.effective_dt
		left join  [edw_temp].tauto_driver_temp2 b on t1.policy_no = b.policy_no 
                                                    and t1.effective_dt = b.effective_dt 
                                                    and t1.transaction_seq_no = b.transaction_seq_no
													and t1.VersionObjectId = b.ExcludedDriverId
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_driver_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_driver_temp1];
        DROP TABLE IF EXISTS edw_temp.[tauto_driver_temp2];

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
