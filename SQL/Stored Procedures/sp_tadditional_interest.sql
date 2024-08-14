SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
-- ================================================================================================================================================
-- Description: This procedures insert and update info related to Additional Interest
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/15/23		Hernando Gonzalez Garcia		1. Created the proc
-- 08/12/24     Architha Gudimalla              2. Added logic for additional_interest_deleted_in
-- 08/12/24     Architha Gudimalla              3. Added additional interest vehicle
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tadditional_interest]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tadditional_interest_temp1];
		SELECT 
			PolicyNumber, EffectiveDate, IssuedDate, ExpirationDate, transaction_dt, PolicyChangeNumber
			,policy_history_sk
			,[index] as additional_interest_seq_no
			,InterestType, EntityType
			,[EntityName] as EntityName
			,DescriptionOfProperty, FirstName, LastName
			,AddressLine1, AddressLine2, AddressCity, AddressCounty, AddressState, AddressZipCode, AddressCountry
			,AnyCommercialExposures, WatercraftOrEmployCrew
			,[Name]
			,vehicle
			--,4 as [source_system_sk] --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			,product_cd
			,IsDeletedOnPolicyChange as additional_interest_deleted_in
		INTO [edw_temp].[tadditional_interest_temp1]
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.IssuedDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, acc.PolicyChangeNumber
				,his.[policy_history_sk] as [policy_history_sk]
				,acct.[Index]
				,accto.[Field]
				,CASE
                        WHEN accto.Field = 'Vehicle' THEN CAST(accto.ReferenceObjectId AS nvarchar(3800))
                        ELSE accto.[Value]
                    END AS [Value]  
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
				 ,ProductCode as product_cd
				 ,acct.IsDeletedOnPolicyChange
			FROM
				(SELECT
					*
				FROM [edw_stage].[AccountTransaction]
				WHERE
					[State] ='ISSUED' --- Review BOUND transactions
					--AND GREATEST(acct.CreatedDate)>@last_source_extract_ts --20230717 removed
					AND GREATEST(IssuedDate)>@last_source_extract_ts --20230717 added
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				LEFT JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
				LEFT JOIN [edw_stage].[AccountTransactionVersionObjectField] accto ON accto.VersionObjectId = acct.id
				LEFT JOIN [edw_core].[tpolicy_history] his ON his.policy_no = acc.PolicyNumber AND his.effective_dt=acc.EffectiveDate AND his.transaction_seq_no = acc.policychangenumber
			WHERE
				--p.[Name]='Collections'
				acct.ObjectType = 'AdditionalInterest'
				--AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (
					InterestType, EntityType, EntityName, DescriptionOfProperty, FirstName, LastName, 
					AddressLine1, AddressLine2, AddressCity, AddressCounty, AddressState, AddressZipCode, AddressCountry, 
					AnyCommercialExposures, WatercraftOrEmployCrew, [Name], vehicle
					)
			) pivottable 

			
		drop table if EXISTS [edw_temp].[tadditional_interest_temp2]

		--Get auto_vehicle_sk
		SELECT 
			acct.Id AS ReferenceObjectId,
			acct.UniqueId,
			av.auto_vehicle_sk
		INTO [edw_temp].[tadditional_interest_temp2]
		FROM
			(
				SELECT
				*
				FROM [edw_stage].[AccountTransaction]
				WHERE [State] ='ISSUED'
				AND PolicyNumber in (SELECT DISTINCT PolicyNumber FROM [edw_temp].[tadditional_interest_temp1])
			) acc
			INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acc.Id
			INNER JOIN [edw_stage].[AccountTransactionVersionObject] acct ON acct.AccountTransactionVersionId = acctv.Id
			inner join (select distinct vehicle from [edw_temp].[tadditional_interest_temp1]) a on a.vehicle = acct.id
			LEFT JOIN [edw_core].[tauto_vehicle] AS av
				ON av.policy_no = acc.PolicyNumber
				AND av.effective_dt = acc.EffectiveDate
				AND av.vehicle_unique_id = acct.[UniqueId]
			WHERE acct.ObjectType = 'Vehicle'
			
		-- Start Insert process
		INSERT INTO [edw_core].[tadditional_interest] (
			[policy_no]
      ,[effective_dt]
      ,[transaction_effective_dt]
      ,[expiration_dt]
      ,[transaction_dt]
      ,[transaction_seq_no]
      ,[policy_history_sk]
      ,[additional_interest_seq_no]
      ,[interest_type]
      ,[entity_type]
      ,[entity_nm]
      ,[property_desc]
      ,[first_nm]
      ,[last_nm]
	  ,[loss_payee_nm]
	  ,[additional_interest_nm]	  
      ,[address_line_1]
      ,[address_line_2]
      ,[city_nm]
      ,[county_nm]
      ,[state_cd]
      ,[zip_cd]
      ,[country_nm]
      ,[commercial_exposures_in]
      ,[watercraft_or_employ_crew_in]
      ,[source_system_sk]
      ,[create_ts]
      ,[update_ts]
      ,[etl_audit_sk]
	  ,[product_cd]
	  ,additional_interest_deleted_in
	  ,auto_vehicle_sk
		)
		SELECT [PolicyNumber]
      ,[EffectiveDate]
      ,[IssuedDate]
      ,[ExpirationDate]
      ,[transaction_dt]
      ,[PolicyChangeNumber]
      ,[policy_history_sk]
      ,[additional_interest_seq_no]
      ,[InterestType]
      ,[EntityType]
      ,[EntityName]
      ,[DescriptionOfProperty]
      ,[FirstName]
      ,[LastName]
	  ,CASE WHEN [InterestType] = 'Loss Payee' THEN [Name] ELSE NULL END AS [loss_payee_nm]
	  ,CASE WHEN [InterestType] = 'Additional Interest' OR [InterestType] like '%Additional Insured%' THEN [Name] ELSE NULL END AS [additional_interest_nm]
      ,[AddressLine1]
      ,[AddressLine2]
      ,[AddressCity]
      ,[AddressCounty]
      ,[AddressState]
      ,[AddressZipCode]
      ,[AddressCountry]
      ,[AnyCommercialExposures]
      ,[WatercraftOrEmployCrew]
      ,a.[source_system_sk]
      ,getdate()
      ,getdate()
	  ,@etl_audit_sk
	  ,[product_cd]
	  ,additional_interest_deleted_in
	  ,t2.auto_vehicle_sk
		FROM 
			[edw_temp].[tadditional_interest_temp1] a
		LEFT JOIN [edw_temp].[tadditional_interest_temp2] AS t2	ON a.vehicle = t2.ReferenceObjectId;

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.[tadditional_interest_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tadditional_interest_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END
GO