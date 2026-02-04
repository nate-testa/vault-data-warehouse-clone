-- =========================================================================================================================== 
-- Description: This procedures insert pel quote location data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/06/2024 			Hernando Gonzalez					1. Created this procedure 
-- 05/08/2024 			Architha Gudimalla					2. Updated @new_last_source_extract_ts 
-- 07/03/2024			Alberto Almario						3. Added primary_location_in
-- 08/22/2024			Architha Gudimalla					4. Removed eff_dt from merge
-- 10/01/2024			Architha Gudimalla					5. Corrected AddressCountry
-- 02/03/26				Dinesh Bobbii		 				6. AD12434 - Added new columns
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_location_wip]

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

		drop table if exists edw_temp.tquote_pel_location_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,source_system_sk,quote_history_sk,
			rownum as [index],
			CreatedDate,UpdatedDate,AddressLine1,AddressLine2,AddressCity,AddressState,AddressZipCode,AddressCounty,AddressCountry,
			NumberOfSwimmingPools,MultiFamilyDwelling,VacantOrUnoccupied,ForSale,
			SquareFootage,NumberofAthleticStructures,ShortTermRental,LongTermRental,LocationsLimitsIndicator
			,primary_location_in,
			OwnedByTrustLLCOrOtherEntity ,TrustOrLegalEntityLegalName ,MailingAddressTrustOrLegalEntity ,TrustOrLegalEntityPurpose ,
			TrustOrLegalEntityAssetUseOrPossession ,TrustOrLegalEntityGrantorAndBeneficiaries ,TrustOrLegalEntityMembershipDetails ,
			TrustOrLegalEntityOwnedHoldingsorAssets ,TrustOrLegalEntityBusinessActivities ,TrustorLegalEntityInsuranceCoverage ,
			TrustOrLegalEntityEmployeesAndResponsibilities ,TrustOrLegalEntityIncomeDetails ,HasAdditionalOwners ,HasBusinessOperations ,
			IsRentedOutsideOwnersFamily ,HomeType ,OccupancyType ,UnderConstructionOrRenovation ,IsVacant ,IsAnyVaultHomeForSale
			into edw_temp.tquote_pel_location_wip_temp1
		from
		(
		select * 
		from
			(
			-- We are generating rownum becase atvo.[index] is 1 for every row of a policy and we are using it as location_no but we should 
			-- have different location_no for different location of a policy number.
			-- This rownum is used as location no
			select
			DENSE_RANK()OVER(PARTITION BY acc.PolicyNumber, CAST(acc.EffectiveDate AS DATE) ORDER BY acco.Id) as rownum,
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			0 AS transaction_seq_no, acco.[index],
			acc.CreatedDate,acc.UpdatedDate,accof.Field,accof.[Value] -- ,atvo.Id
			,CASE WHEN accof_2.Field = 'PrimaryLocationId' THEN 'Yes' ELSE 'No' END AS primary_location_in
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
				left join [edw_stage].[AccountObjectField] accof_2 on accof_2.ReferenceObjectId = acco.id and accof_2.Field = 'PrimaryLocationId'
				left join [edw_core].[tquote_history] tph on tph.quote_no=acc.PolicyNumber
						and tph.effective_dt=acc.EffectiveDate
						and tph.transaction_seq_no = 0
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				--and acc.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and acco.ObjectType='Location'
				and accof.Field IN 
				(
					'AddressLine1','AddressLine2','AddressCity','AddressState','AddressZipCode','AddressCounty',
					'AddressCountry','NumberOfSwimmingPools','MultiFamilyDwelling','VacantOrUnoccupied','ForSale',
					'SquareFootage','NumberofAthleticStructures','ShortTermRental','LongTermRental','LocationsLimitsIndicator',
					'OwnedByTrustLLCOrOtherEntity' ,'TrustOrLegalEntityLegalName' ,'MailingAddressTrustOrLegalEntity' ,'TrustOrLegalEntityPurpose' ,
					'TrustOrLegalEntityAssetUseOrPossession' ,'TrustOrLegalEntityGrantorAndBeneficiaries' ,'TrustOrLegalEntityMembershipDetails' ,
					'TrustOrLegalEntityOwnedHoldingsorAssets' ,'TrustOrLegalEntityBusinessActivities' ,'TrustorLegalEntityInsuranceCoverage' ,
					'TrustOrLegalEntityEmployeesAndResponsibilities' ,'TrustOrLegalEntityIncomeDetails' ,'HasAdditionalOwners' ,'HasBusinessOperations' ,
					'IsRentedOutsideOwnersFamily' ,'HomeType' ,'OccupancyType' ,'UnderConstructionOrRenovation' ,'IsVacant' ,'IsAnyVaultHomeForSale'
				)
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
					IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,
					AddressState,AddressZipCode,AddressCounty,AddressCountry,NumberOfSwimmingPools,MultiFamilyDwelling,
					VacantOrUnoccupied,ForSale,SquareFootage,NumberofAthleticStructures,ShortTermRental,LongTermRental,LocationsLimitsIndicator,
					OwnedByTrustLLCOrOtherEntity ,TrustOrLegalEntityLegalName ,MailingAddressTrustOrLegalEntity ,TrustOrLegalEntityPurpose ,
					TrustOrLegalEntityAssetUseOrPossession ,TrustOrLegalEntityGrantorAndBeneficiaries ,TrustOrLegalEntityMembershipDetails ,
					TrustOrLegalEntityOwnedHoldingsorAssets ,TrustOrLegalEntityBusinessActivities ,TrustorLegalEntityInsuranceCoverage ,
					TrustOrLegalEntityEmployeesAndResponsibilities ,TrustOrLegalEntityIncomeDetails ,HasAdditionalOwners ,HasBusinessOperations ,
					IsRentedOutsideOwnersFamily ,HomeType ,OccupancyType ,UnderConstructionOrRenovation ,IsVacant ,IsAnyVaultHomeForSale)
		) as pivottable
		
		MERGE INTO [edw_core].[tquote_pel_location] AS TARGET
		USING (
		    SELECT
		        ttlc.PolicyNumber AS quote_no,
		        ttlc.EffectiveDate AS effective_dt,
		        ttlc.ExpirationDate AS expiration_dt,
		        ttlc.transaction_seq_no AS transaction_seq_no,
		        ttlc.quote_history_sk AS quote_history_sk,
		        ttlc.[index] AS location_no,
		        ttlc.AddressLine1 AS address_line_1,
		        ttlc.AddressLine2 AS address_line_2,
		        NULL AS unit_no,
		        ttlc.AddressCity AS city_nm,
		        ttlc.AddressState AS state_cd,
		        ttlc.AddressZipCode AS zip_cd,
		        ttlc.AddressCounty AS county_nm,
		        ttlc.AddressCountry AS country_nm,
		        NULL AS longitude,
		        NULL AS latitude,
		        ttlc.NumberOfSwimmingPools AS swimming_pool_ct,
		        ttlc.MultiFamilyDwelling AS multi_family_dwelling_in,
				COALESCE(NULLIF(ttlc.IsVacant, ''), ttlc.VacantOrUnoccupied) AS vacant_unoccupied_in,
				COALESCE(NULLIF(ttlc.IsAnyVaultHomeForSale, ''), ttlc.ForSale) AS for_sale_in,
		        ttlc.source_system_sk AS source_system_sk,
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        ttlc.SquareFootage AS square_feet,
		        ttlc.NumberofAthleticStructures AS no_of_athletic_structures,
		        ttlc.ShortTermRental AS short_term_rental_in,
		        ttlc.LongTermRental AS long_term_rental_in,
		        ttlc.LocationsLimitsIndicator AS location_limit_type,
				ttlc.primary_location_in
				,ttlc.OwnedByTrustLLCOrOtherEntity	as	owned_by_trust_llc_or_other_entity_in
				,ttlc.TrustOrLegalEntityLegalName	as	trust_or_legal_entity_legal_nm
				,ttlc.MailingAddressTrustOrLegalEntity	as	trust_or_legal_entity_mailing_address
				,ttlc.TrustOrLegalEntityPurpose	as	trust_or_legal_entity_purpose
				,ttlc.TrustOrLegalEntityAssetUseOrPossession	as	trust_or_legal_entity_asset_use_or_possession
				,ttlc.TrustOrLegalEntityGrantorAndBeneficiaries	as	trust_or_legal_grantor_and_beneficiaries
				,ttlc.TrustOrLegalEntityMembershipDetails	as	trust_or_legal_entity_membership_details
				,ttlc.TrustOrLegalEntityOwnedHoldingsorAssets	as	trust_or_legal_entity_owned_holding_or_assets
				,ttlc.TrustOrLegalEntityBusinessActivities	as	trust_or_legal_entity_business_activities
				,ttlc.TrustorLegalEntityInsuranceCoverage	as	trust_or_legal_entity_insurance_coverage
				,ttlc.TrustOrLegalEntityEmployeesAndResponsibilities	as	trust_or_legal_entity_employees_and_reponsibilities
				,ttlc.TrustOrLegalEntityIncomeDetails	as	trust_or_legal_entity_income_details
				,ttlc.HasAdditionalOwners	as	additional_owners_in
				,ttlc.HasBusinessOperations	as	business_operations_in
				,ttlc.IsRentedOutsideOwnersFamily	as	rented_outside_owners_family_in
				,ttlc.HomeType	as	home_type
				,ttlc.OccupancyType	as	occupancy_type
				,ttlc.UnderConstructionOrRenovation	as	under_construction_or_renovation_in
		    FROM
		        edw_temp.tquote_pel_location_wip_temp1 AS ttlc
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.location_no = SOURCE.location_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.address_line_1 = SOURCE.address_line_1,
		        TARGET.address_line_2 = SOURCE.address_line_2,
		        TARGET.unit_no = SOURCE.unit_no,
		        TARGET.city_nm = SOURCE.city_nm,
		        TARGET.state_cd = SOURCE.state_cd,
		        TARGET.zip_cd = SOURCE.zip_cd,
		        TARGET.county_nm = SOURCE.county_nm,
		        TARGET.country_nm = SOURCE.country_nm,
		        TARGET.longitude = SOURCE.longitude,
		        TARGET.latitude = SOURCE.latitude,
		        TARGET.swimming_pool_ct = SOURCE.swimming_pool_ct,
		        TARGET.multi_family_dwelling_in = SOURCE.multi_family_dwelling_in,
		        TARGET.vacant_unoccupied_in = SOURCE.vacant_unoccupied_in,
		        TARGET.for_sale_in = SOURCE.for_sale_in,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.square_feet = SOURCE.square_feet,
		        TARGET.no_of_athletic_structures = SOURCE.no_of_athletic_structures,
		        TARGET.short_term_rental_in = SOURCE.short_term_rental_in,
		        TARGET.long_term_rental_in = SOURCE.long_term_rental_in,
		        TARGET.location_limit_type = SOURCE.location_limit_type,
				TARGET.primary_location_in = SOURCE.primary_location_in
				,TARGET.owned_by_trust_llc_or_other_entity_in = SOURCE.owned_by_trust_llc_or_other_entity_in
				,TARGET.trust_or_legal_entity_legal_nm = SOURCE.trust_or_legal_entity_legal_nm
				,TARGET.trust_or_legal_entity_mailing_address = SOURCE.trust_or_legal_entity_mailing_address
				,TARGET.trust_or_legal_entity_purpose = SOURCE.trust_or_legal_entity_purpose
				,TARGET.trust_or_legal_entity_asset_use_or_possession = SOURCE.trust_or_legal_entity_asset_use_or_possession
				,TARGET.trust_or_legal_grantor_and_beneficiaries = SOURCE.trust_or_legal_grantor_and_beneficiaries
				,TARGET.trust_or_legal_entity_membership_details = SOURCE.trust_or_legal_entity_membership_details
				,TARGET.trust_or_legal_entity_owned_holding_or_assets = SOURCE.trust_or_legal_entity_owned_holding_or_assets
				,TARGET.trust_or_legal_entity_business_activities = SOURCE.trust_or_legal_entity_business_activities
				,TARGET.trust_or_legal_entity_insurance_coverage = SOURCE.trust_or_legal_entity_insurance_coverage
				,TARGET.trust_or_legal_entity_employees_and_reponsibilities = SOURCE.trust_or_legal_entity_employees_and_reponsibilities
				,TARGET.trust_or_legal_entity_income_details = SOURCE.trust_or_legal_entity_income_details
				,TARGET.additional_owners_in = SOURCE.additional_owners_in
				,TARGET.business_operations_in = SOURCE.business_operations_in
				,TARGET.rented_outside_owners_family_in = SOURCE.rented_outside_owners_family_in
				,TARGET.home_type = SOURCE.home_type
				,TARGET.occupancy_type = SOURCE.occupancy_type
				,TARGET.under_construction_or_renovation_in = SOURCE.under_construction_or_renovation_in


		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        location_no, address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd, county_nm, country_nm, longitude, latitude,
		        swimming_pool_ct, multi_family_dwelling_in, vacant_unoccupied_in, for_sale_in, source_system_sk, create_ts, update_ts, etl_audit_sk,
		        square_feet, no_of_athletic_structures, short_term_rental_in, long_term_rental_in, location_limit_type,
				primary_location_in,owned_by_trust_llc_or_other_entity_in ,trust_or_legal_entity_legal_nm ,trust_or_legal_entity_mailing_address ,
				trust_or_legal_entity_purpose ,trust_or_legal_entity_asset_use_or_possession ,trust_or_legal_grantor_and_beneficiaries ,
				trust_or_legal_entity_membership_details ,trust_or_legal_entity_owned_holding_or_assets ,trust_or_legal_entity_business_activities ,
				trust_or_legal_entity_insurance_coverage ,trust_or_legal_entity_employees_and_reponsibilities ,trust_or_legal_entity_income_details ,
				additional_owners_in ,business_operations_in ,rented_outside_owners_family_in ,home_type ,occupancy_type ,
				under_construction_or_renovation_in
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.location_no, SOURCE.address_line_1, SOURCE.address_line_2, SOURCE.unit_no, SOURCE.city_nm, SOURCE.state_cd, SOURCE.zip_cd, SOURCE.county_nm, SOURCE.country_nm, SOURCE.longitude, SOURCE.latitude,
		        SOURCE.swimming_pool_ct, SOURCE.multi_family_dwelling_in, SOURCE.vacant_unoccupied_in, SOURCE.for_sale_in, SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk,
		        SOURCE.square_feet, SOURCE.no_of_athletic_structures, SOURCE.short_term_rental_in, SOURCE.long_term_rental_in, SOURCE.location_limit_type,
				SOURCE.primary_location_in,SOURCE.owned_by_trust_llc_or_other_entity_in, SOURCE.trust_or_legal_entity_legal_nm, SOURCE.trust_or_legal_entity_mailing_address, SOURCE.trust_or_legal_entity_purpose, 
				SOURCE.trust_or_legal_entity_asset_use_or_possession, SOURCE.trust_or_legal_grantor_and_beneficiaries, SOURCE.trust_or_legal_entity_membership_details, 
				SOURCE.trust_or_legal_entity_owned_holding_or_assets, SOURCE.trust_or_legal_entity_business_activities, SOURCE.trust_or_legal_entity_insurance_coverage, 
				SOURCE.trust_or_legal_entity_employees_and_reponsibilities, SOURCE.trust_or_legal_entity_income_details, SOURCE.additional_owners_in, 
				SOURCE.business_operations_in, SOURCE.rented_outside_owners_family_in, SOURCE.home_type, SOURCE.occupancy_type, 
				SOURCE.under_construction_or_renovation_in
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_pel_location_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_location_wip_temp1
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
