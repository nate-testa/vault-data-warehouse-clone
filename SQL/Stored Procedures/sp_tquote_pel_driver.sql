
-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel quote driver data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 10/24/2023 			Yunus Mohammed					1. Created this procedure 
-- 11/11/23		        Sandeep Gundreddy		        2. modified quote_history_sk logic and removed transaction_effective_dt
-- 02/05/24				Hernando Gonzalez				3. Added Limits Indicator
-- =========================================================================================================================== 
CREATE or alter  PROCEDURE [edw_core].[sp_tquote_pel_driver]

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
		
		drop table if exists edw_temp.tquote_pel_driver_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,policy_history_sk,source_system_sk,[Index],
			CreatedDate,FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
			Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,DriverLimitsIndicator
			into edw_temp.tquote_pel_driver_temp1
		from
		(
		select * 
		from
			(
			 
			select
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk policy_history_sk,
			act.[Number] AS transaction_seq_no ,atvo.[Index],
			act.CreatedDate,CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value]
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tquote_history] tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.[Number]
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null
				and act.[Stage] IN ('QUOTE','POLICY')				
				and p.[Name]='Personal Excess Liability'
				and atvo.ObjectType='Driver'
				and pr.ProductLine = 'PersonalLines'
				and atvof.Field IN 
				(
					'FirstName','LastName','Birthdate','InsuredType','LicenseStatus','LicenseNumber',
					'Model','LicenseCountry','LicenseState','MiddleName','Suffix','Prefix','LicenseYear','DriverLimitsIndicator'
				)
				and act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
					Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,DriverLimitsIndicator)
		) as pivottable
			
		INSERT INTO [edw_core].[tquote_pel_driver]
		(
			quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
			driver_no,prefix,first_nm,middle_nm,last_nm,suffix,birth_dt,license_status,license_country_nm,license_state_cd,license_year,
			license_no,source_system_sk,create_ts,update_ts,etl_audit_sk, driver_limit_type
		)
		SELECT
			ttlc.PolicyNumber AS policy_no,ttlc.EffectiveDate AS effective_dt,
			ExpirationDate AS expiration_dt,transaction_seq_no AS transaction_seq_no,policy_history_sk,
			[Index] AS driver_no,Prefix AS prefix,FirstName AS first_nm,MiddleName AS middle_nm,
			LastName AS last_nm,Suffix AS suffix,Birthdate AS birth_dt,LicenseStatus AS license_status,
			LicenseCountry AS license_country_nm,LicenseState AS license_state_cd,LicenseYear AS license_year,
			LicenseNumber AS license_no,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk, DriverLimitsIndicator as driver_limit_type
		FROM
			edw_temp.tquote_pel_driver_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_driver_temp1),@last_source_extract_ts);	
		
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_driver_temp1
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
