
-- ====================================================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert and update quote additional interest wip
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date  |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 05/09/24		Mohammed Yunus				1. Created this procedure
-- 08/14/24     Alberto Almario	            2. Added logic for additional_interest_deleted_in and additional interest vehicle
-- 08/15/24     Architha Gudimalla          3. Update additional_interest_deleted_in to use Yes/No instead of 1/0
-- ====================================================================================================================================
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tquote_additional_interest_wip]
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
		DROP TABLE IF EXISTS edw_temp.tquote_additional_interest_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_additional_interest_wip_temp2;

		SELECT 
			PolicyNumber, EffectiveDate, ExpirationDate, transaction_dt, [Number]
			,quote_history_sk
			,[index] as additional_interest_seq_no
			,InterestType, EntityType, EntityName, DescriptionOfProperty, FirstName, LastName, AddressLine1, AddressLine2, AddressCity, AddressCounty, 
            AddressState, AddressZipCode, AddressCountry, AnyCommercialExposures, WatercraftOrEmployCrew
			,Name
			,vehicle
			--,4 as source_system_sk --20230717 removed
			,source_system_sk --20230717 added
			,CreatedDate, UpdatedDate
			,product_cd
			,IsDeletedOnPolicyChange as additional_interest_deleted_in
		INTO edw_temp.tquote_additional_interest_wip_temp1
		FROM
			(
			SELECT
				acc.PolicyNumber, acc.EffectiveDate, acc.ExpirationDate, acc.TransactionEffectiveDate as transaction_dt, 0 AS Number
				,his.quote_history_sk  
				,accvo.[Index]
				,accvof.Field
				,CASE
					WHEN accvof.Field = 'Vehicle' THEN CAST(accvof.ReferenceObjectId AS nvarchar(3800))
					ELSE accvof.[Value]
				END AS [Value]
				,acc.CreatedDate, acc.UpdatedDate
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as source_system_sk
				 ,ProductCode as product_cd 
				 ,CASE WHEN accvo.IsDeletedOnPolicyChange = 1 THEN 'Yes' ELSE 'No' END as IsDeletedOnPolicyChange
			FROM
				(
                    SELECT *
				    FROM edw_stage.Account acc
				    WHERE
				        policyNumber is not null
                        and not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
				        AND GREATEST(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts
				) acc
				INNER JOIN edw_stage.Product p on p.Id = acc.ProductId
                LEFT JOIN edw_stage.AccountObject AS accvo ON accvo.AccountId = acc.Id
                LEFT JOIN edw_stage.AccountObjectField AS accvof ON accvof.ObjectId = accvo.id				
				LEFT JOIN edw_core.tquote_history his ON his.quote_no = acc.PolicyNumber AND his.effective_dt=acc.EffectiveDate AND his.transaction_seq_no = 0
			WHERE				
				accvo.ObjectType = 'AdditionalInterest'
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					InterestType, EntityType, EntityName, DescriptionOfProperty, FirstName, LastName, AddressLine1, AddressLine2, AddressCity, AddressCounty, 
                    AddressState, AddressZipCode, AddressCountry, AnyCommercialExposures, WatercraftOrEmployCrew, Name
					,vehicle
					)
			) pivottable

		--Get quote_auto_vehicle_sk
		SELECT 
			acct.Id AS ReferenceObjectId,
			acct.UniqueId,
			av.quote_auto_vehicle_sk
		INTO [edw_temp].[tquote_additional_interest_wip_temp2]
		FROM
			(
				SELECT
				*
				FROM [edw_stage].[Account]
				WHERE PolicyNumber in (SELECT DISTINCT PolicyNumber FROM [edw_temp].[tquote_additional_interest_wip_temp1])
			) acc
		INNER JOIN [edw_stage].[AccountObject] acct ON acct.AccountId = acc.Id
		INNER JOIN (select distinct vehicle from [edw_temp].[tquote_additional_interest_wip_temp1]) a on a.vehicle = acct.id
		LEFT JOIN [edw_core].[tquote_auto_vehicle] AS av
			ON av.quote_no = acc.PolicyNumber
			AND av.effective_dt = acc.EffectiveDate
			AND av.vehicle_unique_id = acct.[UniqueId]
		WHERE acct.ObjectType = 'Vehicle'

		
		--Merge data
		MERGE edw_core.tquote_additional_interest AS Target
		USING (
			SELECT 
				a.*,
				t2.quote_auto_vehicle_sk
			FROM [edw_temp].[tquote_additional_interest_wip_temp1] a
			LEFT JOIN [edw_temp].[tquote_additional_interest_wip_temp2] AS t2 ON a.vehicle = t2.ReferenceObjectId
			) AS Source
		ON Target.quote_no = Source.PolicyNumber and Target.effective_dt= Source.EffectiveDate AND
		Target.transaction_seq_no = Source.Number and 
		Source.additional_interest_seq_no = Target.additional_interest_seq_no
		WHEN NOT MATCHED BY Target THEN
				-- Start Insert process
		INSERT
        (
            quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,additional_interest_seq_no,interest_type
            ,entity_type,entity_nm,property_desc,first_nm,last_nm,loss_payee_nm,additional_interest_nm,address_line_1,address_line_2
            ,city_nm,county_nm,state_cd,zip_cd,country_nm,commercial_exposures_in,watercraft_or_employ_crew_in
            ,source_system_sk,create_ts,update_ts,etl_audit_sk,product_cd
			,additional_interest_deleted_in
	  		,quote_auto_vehicle_sk
		)
		VALUES
		(
            PolicyNumber,EffectiveDate,ExpirationDate,[Number],quote_history_sk,additional_interest_seq_no,InterestType
            ,EntityType,EntityName,DescriptionOfProperty,FirstName,LastName
            ,CASE WHEN InterestType = 'Loss Payee' THEN Name ELSE NULL END
            ,CASE WHEN InterestType = 'Additional Interest' OR InterestType like '%Additional Insured%' THEN Name ELSE NULL END
            ,AddressLine1,AddressLine2,AddressCity,AddressCounty,AddressState,AddressZipCode,AddressCountry,AnyCommercialExposures,WatercraftOrEmployCrew
            ,source_system_sk,getdate(),getdate(),@etl_audit_sk,product_cd
			,additional_interest_deleted_in
	  		,quote_auto_vehicle_sk
		)
		WHEN MATCHED THEN UPDATE
		SET
			expiration_dt = Source.ExpirationDate,
			quote_history_sk = Source.quote_history_sk,
			interest_type =Source.InterestType,
			entity_type = Source.EntityType,
			entity_nm = Source.EntityName,
			property_desc = Source.DescriptionOfProperty,
			first_nm = source.FirstName,
			last_nm = Source.LastName,
			loss_payee_nm = CASE WHEN Source.InterestType = 'Loss Payee' THEN Source.Name ELSE NULL END,
			additional_interest_nm = CASE WHEN Source.InterestType = 'Additional Interest' OR Source.InterestType like '%Additional Insured%' THEN Name ELSE NULL END,
			address_line_1 = Source.AddressLine1,
			address_line_2 = Source.AddressLine2,
			city_nm = Source.AddressCity,
			county_nm = Source.AddressCounty,
			state_cd = Source.AddressState,
			zip_cd = Source.AddressZipCode,
			country_nm = Source.AddressCountry,
			commercial_exposures_in = Source.AnyCommercialExposures,
			watercraft_or_employ_crew_in = Source.WatercraftOrEmployCrew,
			product_cd = Source.product_cd,
			Target.additional_interest_deleted_in = Source.additional_interest_deleted_in,
			Target.quote_auto_vehicle_sk = Source.quote_auto_vehicle_sk,
			update_ts = GETDATE()
			;
		

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(t1.CreatedDate,t1.UpdatedDate)) FROM edw_temp.tquote_additional_interest_wip_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_additional_interest_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_additional_interest_wip_temp2;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

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
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END