-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures inserts and updates TPolicy 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/20/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 06/20/23		Architha Gudimalla				2. Modified for errors after first run 
-- 09/08/23		Architha Gudimalla				3. Modifed to reflect model changes
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy]

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

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tpolicy_temp1;
		WITH cte_AccountTransaction AS (
			SELECT  
				acct.*,
				case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end ssk
				,ROW_NUMBER() OVER (PARTITION BY acct.PolicyNumber, acct.EffectiveDate 
						ORDER BY acct.policychangenumber DESC) AS AccountTransaction_Rank
			FROM edw_stage.AccountTransaction acct
		    left join edw_stage.Product pr on acct.ProductId = pr.id
			WHERE PolicyNumber is not null and  
				acct.State ='ISSUED' --- Review BOUND transactions 
				and pr.ProductLine = 'PersonalLines' 
				AND GREATEST(acct.IssuedDate)>@last_source_extract_ts
		)
		SELECT cte_Acc.*
		INTO edw_temp.tpolicy_temp1
		FROM cte_AccountTransaction cte_Acc
		WHERE cte_Acc.AccountTransaction_Rank = 1

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tpolicy_temp2;
		SELECT	AccountTransactionId,  
				nullif(trim(NamedInsured),'') NamedInsured, 
				nullif(trim(CompanyName),'') CompanyName, 
				nullif(trim(MailingAddressLine1),'') MailingAddressLine1, 
				nullif(trim(MailingAddressLine2),'') MailingAddressLine2, 
				nullif(trim(MailingAddressLineUnit),'') UnitFloor, 
				nullif(trim(MailingAddressCity),'') MailingAddressCity, 
				nullif(trim(MailingAddressState),'') MailingAddressState, 
				nullif(trim(MailingAddressZipCode),'') MailingAddressZipCode, 
				nullif(trim(MailingAddressCounty),'') MailingAddressCounty, 
				nullif(trim(MailingAddressCountry),'') MailingAddressCountry, 
				nullif(trim(Program),'') Program
		INTO edw_temp.tpolicy_temp2
		FROM
			(
				SELECT  acctv.AccountTransactionId, 
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tpolicy_temp1 acc
					INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id --acctv.AccountTransactionId = acc.Id
					INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
					INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') != '''' --and acc.policynumber = 'HO100024581' 
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (NamedInsured, CompanyName, MailingAddressLine1, MailingAddressLine2, MailingAddressLineUnit, 
				MailingAddressCity, MailingAddressState, MailingAddressZipCode, MailingAddressCounty, MailingAddressCountry, Program)
			) pivottable

		-- Start Merge process
		MERGE edw_core.tpolicy AS Target
		USING (
			SELECT 
				tmp1.PolicyNumber,
				tmp1.EffectiveDate,
				tmp1.ExpirationDate, 
				br.producerid as BrokerId,
				ins.ReferenceCode as customer_id,
				nullif(trim(pr.ProductCode),'') product_cd,
				nullif(trim(COALESCE(acctv.RiskStateCode, 'DNA')),'') as RiskStateCode, --review
				tmp2.NamedInsured as insured_nm,
				case when acc.IsRenewal = 1 then 'Renewal' else 'New' end as policy_term,
				case when tmp2.program = 'Admitted' then 'Vault Reciprocal Exchange' 
				     when tmp2.program = 'Non-Admitted' then 'Vault E & S Insurance Company' 
				     else null
				end as uw_company_nm,
				--tmp2.CompanyName as uw_company_nm,
				tmp2.program,
				tmp1.State,
				tmp1.TransactionEffectiveDate,
				tmp2.MailingAddressLine1,
				tmp2.MailingAddressLine2,
				tmp2.UnitFloor,
				tmp2.MailingAddressCity,
				tmp2.MailingAddressState,
				tmp2.MailingAddressZipCode, 
				tmp2.MailingAddressCounty,
				tmp2.MailingAddressCountry, 
				tmp1.ssk as source_system_sk,
				tmp1.CreatedDate,
				tmp1.UpdatedDate 
				,case when charindex('-',tmp1.PolicyNumber) <> 0
					 then substring(tmp1.PolicyNumber,1,charindex('-',tmp1.PolicyNumber)-1) 
					 else tmp1.PolicyNumber  
				end as original_policy_no
				,acc_prior.PolicyNumber  prior_policy_no
				,'No' as non_renewal_in
				--select *
			FROM 
				edw_temp.tpolicy_temp1 tmp1
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = tmp1.Id
				inner join edw_stage.Account acc on tmp1.AccountId = acc.Id 
				left join edw_stage.Account acc_prior on acc.copyofAccountId = acc_prior.Id 
				left join edw_stage.Brokerage br on acctv.BrokerageId = br.id
				left join edw_stage.Insured ins on acctv.PrimaryInsuredId = ins.Id
				left join edw_stage.Product pr on tmp1.ProductId = pr.id
				left join edw_temp.tpolicy_temp2 tmp2 on tmp2.AccountTransactionId = tmp1.Id
				where pr.productline <> 'CommercialLines' --and tmp1.policynumber = 'CO100023657' 
		) AS Source
		ON Source.PolicyNumber = Target.policy_no and cast(Source.EffectiveDate as date) = cast(Target.effective_dt as date)
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
           ,insured_nm
           ,policy_term
		   ,uw_company_nm
           ,program_type
           ,policy_status -- ** This is not the state (Active or Canceled)
           ,original_policy_no
           ,original_policy_effective_dt
           ,mailing_address_line1
           ,mailing_address_line2
           ,mailing_address_unit_no
           ,mailing_address_city_nm
           ,mailing_address_state_cd
           ,mailing_address_zip_cd
           ,mailing_address_county_nm
           ,mailing_address_country_nm
           ,prior_policy_no
           ,non_renewal_in
           ,source_system_sk
           ,create_ts
           ,update_ts
           ,etl_audit_sk
			)
		VALUES (Source.PolicyNumber, 
				Source.EffectiveDate, Source.ExpirationDate, Source.BrokerId, Source.customer_id, 
				Source.product_cd,
				Source.RiskStateCode,
				Source.insured_nm,
				Source.policy_term,
				Source.uw_company_nm, 
				Source.program,
				'Active', 
				source.original_policy_no,
				Source.TransactionEffectiveDate, 
				Source.MailingAddressLine1, 
				Source.MailingAddressLine2, 
				Source.UnitFloor, 
				Source.MailingAddressCity,
				Source.MailingAddressState, 
				Source.MailingAddressZipCode, 
				Source.MailingAddressCounty, 
				Source.MailingAddressCountry, 
				source.prior_policy_no,
				source.non_renewal_in,
				Source.source_system_sk, 
				getdate(), getdate(), @etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.broker_id					= Source.BrokerId,
        Target.customer_id					= Source.customer_id,
        Target.risk_state_cd				= Source.RiskStateCode,
        Target.insured_nm					= Source.insured_nm,
        Target.policy_term					= Source.policy_term,
        Target.uw_company_nm				= Source.uw_company_nm,
        Target.program_type					= Source.program,
        Target.original_policy_no			= Source.original_policy_no,
        Target.original_policy_effective_dt	= Source.TransactionEffectiveDate,
        Target.mailing_address_line1		= Source.MailingAddressLine1,
        Target.mailing_address_line2		= Source.MailingAddressLine2,
        Target.mailing_address_unit_no		= Source.UnitFloor,
        Target.mailing_address_city_nm		= Source.MailingAddressCity,
        Target.mailing_address_state_cd		= Source.MailingAddressState,
		Target.mailing_address_zip_cd		= Source.MailingAddressZipCode,
        Target.mailing_address_county_nm	= Source.MailingAddressCounty,
		Target.mailing_address_country_nm	= Source.MailingAddressCountry, 
		Target.prior_policy_no				= source.prior_policy_no, 
        Target.update_ts 					= getdate()
		;

		SET @rows_affected=@@ROWCOUNT;
		
		update edw_core.tpolicy
		set policy_status = 'Expired'
		where expiration_dt <= cast(getdate() as date);
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t2.IssuedDate) FROM edw_temp.tpolicy_temp1 t2),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tpolicy_temp1;
		DROP TABLE IF EXISTS edw_temp.tpolicy_temp2;
		
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


