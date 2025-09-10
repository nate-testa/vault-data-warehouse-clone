-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel driver data
-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date |Author									 |	Change Description
---------------------------------------------------------------------------------------------------
-- 							Yunus Mohammed			    1. Created this procedure
-- 01/08/24		Yunus Mohammed			    2. Added deleted_on_policy_change_in
-- 02/05/24		Hernando Gonzalez			 3. Added Limits Indicator
-- 11/19/24		Architha Gudimalla		      4. AD7757 - Added driver unique id
-- 08/05/25		Dinesh Bobbili			    		5. AD10467 Added driver_status
--09/09/25		Yunus Mohammed				6. AD10908 - Added logic to use IsDeletedOnRenewal
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tpel_driver]

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
		
		drop table if exists edw_temp.tpel_driver_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,TransactionDate,transaction_seq_no,policy_history_sk,source_system_sk,[Index],
			IssuedDate,FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
			Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,
			CASE WHEN IsDeletedOnPolicyChange =1 OR IsDeletedOnRenewal =1  THEN 'No' WHEN 1 THEN 'Yes' END AS IsDeletedOnPolicyChange,
			DriverLimitsIndicator
			,driver_unique_id
			,DriverStatus		
			into edw_temp.tpel_driver_temp1
		from
		(
		select * 
		from
			(
			 
			select
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.policy_history_sk,
			act.policychangenumber AS transaction_seq_no, act.IssuedDate as TransactionDate,atvo.[Index],
			act.IssuedDate,CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value],
			atvo.IsDeletedOnPolicyChange
			,atvo.IsDeletedOnRenewal
			,atvo.[UniqueId] driver_unique_id
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tpolicy_history] tph on tph.policy_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.policychangenumber
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null
				and act.[State] ='ISSUED'
				and p.[Name]='Personal Excess Liability'
				and atvo.ObjectType='Driver'
				and pr.ProductLine = 'PersonalLines'
				and atvof.Field IN 
				(
					'FirstName','LastName','Birthdate','InsuredType','LicenseStatus','LicenseNumber',
					'Model','LicenseCountry','LicenseState','MiddleName','Suffix','Prefix','LicenseYear','DriverLimitsIndicator','DriverStatus'
				)
				and act.IssuedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (FirstName,LastName,Birthdate,InsuredType,LicenseStatus,LicenseNumber,
					Model,LicenseCountry,LicenseState,MiddleName,Suffix,Prefix,LicenseYear,DriverLimitsIndicator,DriverStatus)
		) as pivottable
			
		INSERT INTO [edw_core].[tpel_driver]
		(
			policy_no,effective_dt,transaction_effective_dt,expiration_dt,transaction_dt,transaction_seq_no,policy_history_sk,
			driver_no,prefix,first_nm,middle_nm,last_nm,suffix,birth_dt,license_status,license_country_nm,license_state_cd,license_year,
			license_no,driver_deleted_in,source_system_sk,create_ts,update_ts,etl_audit_sk, driver_limit_type
			,driver_unique_id, driver_status
		)
		SELECT
			ttlc.PolicyNumber AS policy_no,ttlc.EffectiveDate AS effective_dt,TransactionEffectiveDate AS transaction_effective_dt,
			ExpirationDate AS expiration_dt,TransactionDate AS transaction_dt,transaction_seq_no AS transaction_seq_no,policy_history_sk,
			[Index] AS driver_no,Prefix AS prefix,FirstName AS first_nm,MiddleName AS middle_nm,
			LastName AS last_nm,Suffix AS suffix,Birthdate AS birth_dt,LicenseStatus AS license_status,
			LicenseCountry AS license_country_nm,LicenseState AS license_state_cd,LicenseYear AS license_year,
			LicenseNumber AS license_no,IsDeletedOnPolicyChange AS driver_deleted_in,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk,DriverLimitsIndicator as driver_limit_type
			,driver_unique_id, DriverStatus as driver_status
		FROM
			edw_temp.tpel_driver_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.tpel_driver_temp1),@last_source_extract_ts);	
		
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tpel_driver_temp1
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

