SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-26
-- Description: This stored procedure insert and update info related to tcommercial_policy.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 26/03/2025            Alberto Almario			1. Created this procedure 
-- 22/04/2025            Alberto Almario			2. Use BindDate instead of IssuedDate
-- 30/04/2025            Alberto Almario			3. Add fix value Active for policy_status
-- ===================================================================================================================== 
CREATE OR ALTER     PROCEDURE [edw_core].[sp_tcommercial_policy]

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
		DECLARE @CU DATETIME=GETDATE()
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp3;

		-- Step1 limit amount of rows.
		WITH cte_AccountTransaction AS (
			SELECT  
				acct.*
				,CASE 
					WHEN acct.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
					ELSE 4 --(Metal)
				 END source_system_sk
				,ROW_NUMBER() OVER (PARTITION BY acct.PolicyNumber, cast(acct.EffectiveDate as date) ORDER BY acct.policychangenumber DESC) AS AccountTransaction_Rank
			FROM edw_stage.AccountTransaction acct 
		    LEFT JOIN edw_stage.Product pr on acct.ProductId = pr.id
			WHERE acct.State IN ('ISSUED','BOUND')
			AND pr.ProductLine = 'CommercialLines'  
			AND acct.BindDate > @last_source_extract_ts
		)
		SELECT cte_Acc.*
		INTO edw_temp.tcommercial_policy_temp1
		FROM cte_AccountTransaction cte_Acc
		WHERE cte_Acc.AccountTransaction_Rank = 1

		-- Pivot Table
		SELECT	
			AccountTransactionId 
			,nullif(trim(InsuredType),'') as InsuredType
			,nullif(trim(NamedInsured),'') as NamedInsured
			,nullif(trim(FirstName),'') as FirstName
			,nullif(trim(MiddleName),'') as MiddleName
			,nullif(trim(LastName),'') as LastName
			,nullif(trim(Prefix),'') as Prefix
			,nullif(trim(Suffix),'') as Suffix
			,nullif(trim(MailingAddressLine1),'') as mailing_address_line1
			,nullif(trim(MailingAddressLine2),'') as mailing_address_line2
			,nullif(trim(MailingAddressLineUnit),'') as mailing_address_unit_no
			,nullif(trim(MailingAddressCity),'') as mailing_address_city_nm
			,nullif(trim(MailingAddressState),'') as mailing_address_state_cd
			,nullif(trim(MailingAddressZipCode),'') as mailing_address_zip_cd
		INTO edw_temp.tcommercial_policy_temp2
		FROM
			(
				SELECT  
					 acctv.AccountTransactionId 
					,acctvof.Field
					,acctvof.Value
				FROM edw_temp.tcommercial_policy_temp1 acc
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id
				INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE LTRIM(RTRIM(acctvof.Field)) IN ('InsuredType','NamedInsured','FirstName','MiddleName','LastName','Prefix','Suffix','MailingAddressLine1','MailingAddressLine2','MailingAddressLineUnit','MailingAddressCity','MailingAddressState','MailingAddressZipCode')
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					InsuredType, NamedInsured, FirstName, MiddleName, LastName, Prefix, Suffix,
					MailingAddressLine1, MailingAddressLine2, MailingAddressLineUnit, MailingAddressCity, MailingAddressState, MailingAddressZipCode
				)
			) pivottable

		-- Create final temp table
		SELECT 
			 tmp1.PolicyNumber as policy_no
			,tmp1.EffectiveDate as effective_dt
			,tmp1.ExpirationDate as expiration_dt
			,br.producerid as broker_id
			,ins.ReferenceCode as customer_id
			,nullif(trim(pr.ProductCode),'') as product_cd
			,nullif(trim(COALESCE(acctv.RiskStateCode, 'DNA')),'') as risk_state_cd
			,case when acc.RenewalIndex = 0 then 'New' else 'Renewal' end as policy_term
			,'Active' as policy_status
			,CASE
				WHEN nullif(trim(isnull(tmp2.Prefix + ' ','') + isnull(tmp2.FirstName + ' ','') + isnull(tmp2.MiddleName + ' ','') + isnull(tmp2.LastName + ' ','') + isnull(tmp2.Suffix,'')),'') IS NOT NULL
					THEN nullif(trim(isnull(tmp2.Prefix + ' ','') + isnull(tmp2.FirstName + ' ','') + isnull(tmp2.MiddleName + ' ','') + isnull(tmp2.LastName + ' ','') + isnull(tmp2.Suffix,'')),'')
				WHEN tmp2.NamedInsured IS NOT NULL
					THEN tmp2.NamedInsured
				ELSE ins.NamedInsured
			END as insured_nm
			,tmp2.mailing_address_line1
			,tmp2.mailing_address_line2
			,tmp2.mailing_address_unit_no
			,tmp2.mailing_address_city_nm
			,tmp2.mailing_address_state_cd
			,tmp2.mailing_address_zip_cd
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,tmp1.source_system_sk
		INTO edw_temp.tcommercial_policy_temp3
		FROM edw_temp.tcommercial_policy_temp1 tmp1
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = tmp1.Id
		INNER JOIN edw_stage.Account acc on tmp1.AccountId = acc.Id 
		LEFT JOIN edw_stage.Brokerage br on acctv.BrokerageId = br.id
		LEFT JOIN edw_stage.Insured ins on acctv.PrimaryInsuredId = ins.Id
		LEFT JOIN edw_stage.Product pr on tmp1.ProductId = pr.id
		LEFT JOIN edw_temp.tcommercial_policy_temp2 tmp2 on tmp2.AccountTransactionId = tmp1.Id
		WHERE pr.productline = 'CommercialLines'
		AND pr.ProductCode IS NOT NULL
			

		-- Start Merge process
		MERGE edw_commercial.tcommercial_policy AS Target
		USING edw_temp.tcommercial_policy_temp3 AS Source
		ON Source.policy_no = Target.policy_no and cast(Source.effective_dt as date) = cast(Target.effective_dt as date)
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			 policy_no
			,effective_dt
			,expiration_dt
			,broker_id
			,customer_id
			,product_cd
			,risk_state_cd
			,policy_term
			,policy_status
			,insured_nm
			,mailing_address_line1
			,mailing_address_line2
			,mailing_address_unit_no
			,mailing_address_city_nm
			,mailing_address_state_cd
			,mailing_address_zip_cd
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
			)
		VALUES (
			 Source.policy_no
			,Source.effective_dt
			,Source.expiration_dt
			,Source.broker_id
			,Source.customer_id
			,Source.product_cd
			,Source.risk_state_cd
			,Source.policy_term
			,Source.policy_status
			,Source.insured_nm
			,Source.mailing_address_line1
			,Source.mailing_address_line2
			,Source.mailing_address_unit_no
			,Source.mailing_address_city_nm
			,Source.mailing_address_state_cd
			,Source.mailing_address_zip_cd
			,Source.create_ts
			,Source.update_ts
			,Source.etl_audit_sk
			,Source.source_system_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        	 Target.expiration_dt = Source.expiration_dt
			,Target.broker_id = Source.broker_id
			,Target.customer_id = Source.customer_id
			,Target.product_cd = Source.product_cd
			,Target.risk_state_cd = Source.risk_state_cd
			,Target.policy_term = Source.policy_term
			,Target.policy_status = Source.policy_status
			,Target.insured_nm = Source.insured_nm
			,Target.mailing_address_line1 = Source.mailing_address_line1
			,Target.mailing_address_line2 = Source.mailing_address_line2
			,Target.mailing_address_unit_no = Source.mailing_address_unit_no
			,Target.mailing_address_city_nm = Source.mailing_address_city_nm
			,Target.mailing_address_state_cd = Source.mailing_address_state_cd
			,Target.mailing_address_zip_cd = Source.mailing_address_zip_cd
			,Target.update_ts = getdate()
		;

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(tmp.BindDate) FROM edw_temp.tcommercial_policy_temp1 tmp),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_temp3;
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; 

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END

