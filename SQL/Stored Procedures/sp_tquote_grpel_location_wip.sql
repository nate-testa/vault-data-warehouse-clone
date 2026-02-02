-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert Participant Personal Excess Liability location data for wip quotes
-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date          |Author									 |	Change Description
---------------------------------------------------------------------------------------------------
-- 	01/30/26            Yunus Mohammed			    1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_location_wip]

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
		
		drop table if exists edw_temp.tquote_grpel_location_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,transaction_seq_no,
            policy_history_sk,source_system_sk,CreatedDate,UpdatedDate,
           AddressLine1,AddressLine2,AddressCity,AddressState,AddressZipCode,AddressCounty,AddressCountry,
            NumberOfSwimmingPools,rented_in,rental_term,location_unique_id
	    into edw_temp.tquote_grpel_location_wip_temp1
		from
		(
		select * 
		from
			(
			select
			acc.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			tqh.quote_history_sk,
			0 AS transaction_seq_no, acco.[Index],
			acc.CreatedDate,acc.UpdatedDate,CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
            acco.Field,acco.[Value],acc.UpdatedDate.[UniqueId] location_unique_id
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
				left join [edw_core].[tquote_history] tph on tph.quote_no=acc.PolicyNumber
						and tph.effective_dt=acc.EffectiveDate
						and tph.transaction_seq_no = 0
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				and act.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Participant Personal Excess Liability'
				and acco.ObjectType='Location'
				and pr.ProductLine = 'PersonalLines'
				and accof.Field IN 
				(
					'AddressLine1','AddressLine2','AddressCity','AddressState','AddressZipCode','AddressCounty',
					'AddressCountry','NumberOfSwimmingPools','IsRented','RentalTerm'
				)
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (
            		FirstName,MiddleName,LastName,Birthdate,RelationshipToInsured,HasDUIDWI,LicenseStatus,
                    LicenseCountry,LicenseState,LicenseYear,LicenseNumber
                )
		) as pivottable
			
		MERGE INTO [edw_core].[tquote_grpel_location] AS TARGtargetET
		USING (
		    SELECT
                ttlc.PolicyNumber AS quote_no,ttlc.EffectiveDate AS effective_dt,
                ExpirationDate AS expiration_dt,TransactionDate AS transaction_dt,transaction_seq_no AS transaction_seq_no,quote_history_sk,
                [index] AS location_no,AddressLine1 AS address_line_1,AddressLine2 AS address_line_2,AddressCity AS city_nm,
                AddressState AS state_cd,AddressZipCode AS zip_cd,AddressCounty AS county_nm,AddressCountry AS country_nm,            
                NumberOfSwimmingPools AS swimming_pool_ct,IsRented as rented_in,RentalTerm as rental_term,location_unique_id,
                primary_location_in,location_deleted_in,
                source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		    FROM
		        edw_temp.tquote_grpel_location_wip_temp1 AS ttlc
		) AS source
		ON
		    target.quote_no = source.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    target.transaction_seq_no = source.transaction_seq_no AND
		    target.location_unique_id = source.location_unique_id

		WHEN MATCHED THEN
		    UPDATE 
            SET
                target. effective_dt = source.effective_dt,
                target.expiration_dt= source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.location_no = source.location_no,
                target. address_line_1= source.address_line_1,
                target.address_line_2= source.address_line_2,
                target.city_nm= source.city_nm,
                target.state_cd = source.state_cd,
                target.zip_cd = source.zip_cd,
                target.county_nm = source.county_nm,
                target.country_nm = source.country_nm,
                target.swimming_pool_ct = source.swimming_pool_ct,
                target.rented_in =source. rented_in,
                target.rental_term = source.rental_term,
                target.primary_location_in = source.primary_location_in	,
                target.source_system_sk = source.source_system_sk,
                target.update_ts = source.update_ts,
                target.etl_audit_sk = source.etl_audit_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		    		quote_no,effective_dt,transaction_effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
                    driver_no,first_nm ,middle_nm,last_nm ,birth_dt ,relationship_to_insured,has_dui_dwi_in ,license_status,license_country_nm,
                    license_state_cd,license_year,license_no,driver_unique_id,source_system_sk ,create_ts ,update_ts,etl_audit_sk  
		    )
		    VALUES (
                source.quote_no,source.effective_dt,source.transaction_effective_dt,source.expiration_dt,source.transaction_seq_no,source.quote_history_sk,
                source.driver_no,first_nm ,source.middle_nm,source.last_nm ,source.birth_dt ,source.relationship_to_insured,source.has_dui_dwi_in,
                source.license_status,source.license_country_nm,
                source.license_state_cd,source.license_year,source.license_no,source.driver_unique_id,
                source.source_system_sk ,source.create_ts  ,source.update_ts,source.etl_audit_sk  
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
        SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_grpel_location_wip_temp1),@last_source_extract_ts);	

		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_location_wip_temp1
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