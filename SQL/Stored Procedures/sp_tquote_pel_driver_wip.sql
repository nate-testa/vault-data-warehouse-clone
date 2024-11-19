-- =========================================================================================================================== 
-- Description: This procedures insert pel quote driver data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 05/06/2024 			Hernando Gonzalez					1. Created this procedure 
-- 05/08/2024 			Architha Gudimalla					2. Updated @new_last_source_extract_ts 
-- 05/14/2024 			Architha Gudimalla					3. Corrected errors
-- 08/22/2024			Architha Gudimalla					4. Removed eff_dt from merge
-- 11/19/24				Yunus Mohammed					    5. AD7763 - Added driver_unique_id
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_driver_wip]

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
		
		drop table if exists edw_temp.tquote_pel_driver_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,policy_history_sk,source_system_sk,[Index],
			CreatedDate,UpdatedDate,FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
			Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,DriverLimitsIndicator,driver_unique_id
			into edw_temp.tquote_pel_driver_wip_temp1
		from
		(
		select * 
		from
			(
			 
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk policy_history_sk,
			0 AS transaction_seq_no ,acco.[Index],
			acc.CreatedDate,acc.UpdatedDate, CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			accof.Field,accof.[Value],acco.[UniqueId] as driver_unique_id
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
				--and acc.[Stage] IN ('QUOTE','POLICY')				
				and p.[Name]='Personal Excess Liability'
				and acco.ObjectType='Driver'
				and pr.ProductLine = 'PersonalLines'
				and accof.Field IN 
				(
					'FirstName','LastName','Birthdate','InsuredType','LicenseStatus','LicenseNumber',
					'Model','LicenseCountry','LicenseState','MiddleName','Suffix','Prefix','LicenseYear','DriverLimitsIndicator'
				)
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
					Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,DriverLimitsIndicator)
		) as pivottable
			
		MERGE INTO [edw_core].[tquote_pel_driver] AS TARGET
		USING (
		    SELECT
		        ttlc.PolicyNumber AS quote_no,
		        ttlc.EffectiveDate AS effective_dt,
		        ttlc.ExpirationDate AS expiration_dt,
		        ttlc.transaction_seq_no AS transaction_seq_no,
		        ttlc.policy_history_sk AS quote_history_sk,
		        ttlc.[Index] AS driver_no,
		        ttlc.Prefix AS prefix,
		        ttlc.FirstName AS first_nm,
		        ttlc.MiddleName AS middle_nm,
		        ttlc.LastName AS last_nm,
		        ttlc.Suffix AS suffix,
		        ttlc.Birthdate AS birth_dt,
		        ttlc.LicenseStatus AS license_status,
		        ttlc.LicenseCountry AS license_country_nm,
		        ttlc.LicenseState AS license_state_cd,
		        ttlc.LicenseYear AS license_year,
		        ttlc.LicenseNumber AS license_no,
		        ttlc.source_system_sk AS source_system_sk,
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        ttlc.DriverLimitsIndicator AS driver_limit_type,
				driver_unique_id
		    FROM
		        edw_temp.tquote_pel_driver_wip_temp1 AS ttlc
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.driver_no = SOURCE.driver_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.prefix = SOURCE.prefix,
		        TARGET.first_nm = SOURCE.first_nm,
		        TARGET.middle_nm = SOURCE.middle_nm,
		        TARGET.last_nm = SOURCE.last_nm,
		        TARGET.suffix = SOURCE.suffix,
		        TARGET.birth_dt = SOURCE.birth_dt,
		        TARGET.license_status = SOURCE.license_status,
		        TARGET.license_country_nm = SOURCE.license_country_nm,
		        TARGET.license_state_cd = SOURCE.license_state_cd,
		        TARGET.license_year = SOURCE.license_year,
		        TARGET.license_no = SOURCE.license_no,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.driver_limit_type = SOURCE.driver_limit_type,
				TARGET.driver_unique_id = SOURCE.driver_unique_id

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        driver_no, prefix, first_nm, middle_nm, last_nm, suffix, birth_dt, license_status, license_country_nm, license_state_cd, license_year,
		        license_no, source_system_sk, create_ts, update_ts, etl_audit_sk, driver_limit_type,driver_unique_id
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.driver_no, SOURCE.prefix, SOURCE.first_nm, SOURCE.middle_nm, SOURCE.last_nm, SOURCE.suffix, SOURCE.birth_dt, SOURCE.license_status, SOURCE.license_country_nm, SOURCE.license_state_cd, SOURCE.license_year,
		        SOURCE.license_no, SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk, 
				SOURCE.driver_limit_type,SOURCE.driver_unique_id
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_pel_driver_wip_temp1),@last_source_extract_ts);	
		
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_driver_wip_temp1
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