/****** Object:  StoredProcedure [edw_core].[sp_tquote]    Script Date: 11/16/2023 11:49:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================================================================================
-- Description: This procedures inserts and updates tquote 
-----------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 10/23/23		Architha Gudimalla				1. Created this procedure 
-- 11/16/23		Architha Gudimalla				2. Updated the prior policy logic
-- ===================================================================================================================== 

create or ALTER      PROCEDURE [edw_core].[sp_tquote]

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
		DROP TABLE IF EXISTS edw_temp.tquote_temp1;
		SELECT acc.* 
		into edw_temp.tquote_temp1
		FROM edw_stage.Account acc 
		left join edw_stage.Product pr on acc.ProductId = pr.id
		WHERE acc.PolicyNumber is not null 
		and  pr.ProductLine = 'PersonalLines' 
		AND greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts

		
		/*
		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tquote_temp1;
		WITH cte_AccountTransaction AS (
			SELECT  
				acct.*,
				case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end ssk
				,ROW_NUMBER() OVER (PARTITION BY acct.PolicyNumber--, acct.EffectiveDate 
						ORDER BY acct.number DESC) AS AccountTransaction_Rank
			FROM edw_stage.Account acc 
		    left join edw_stage.Product pr on acct.ProductId = pr.id
			left join edw_stage.AccountTransaction acct on acct.AccountId = acc.Id and acct.Stage in ('QUOTE','POLICY')
			WHERE acc.PolicyNumber is not null   
			and pr.ProductLine = 'PersonalLines' 
			AND acc.CreatedDate > @last_source_extract_ts
		)
		SELECT cte_Acc.*
		INTO edw_temp.tquote_temp1
		FROM cte_AccountTransaction cte_Acc
		WHERE cte_Acc.AccountTransaction_Rank = 1*/
		

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tquote_temp2;
		SELECT	id,  
				nullif(trim(NamedInsured),'') NamedInsured, 
				nullif(trim(FirstName),'') FirstName, 
				nullif(trim(MiddleName),'') MiddleName, 
				nullif(trim(LastName),'') LastName, 
				nullif(trim(Prefix),'') Prefix, 
				nullif(trim(Suffix),'') Suffix, 
				nullif(trim(InsuredType),'') InsuredType, 
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
		INTO edw_temp.tquote_temp2
		FROM
			(
				SELECT  acc.id, accof.Field, accof.Value 
						/*case when pin.id is not null and accof.Field in  ('FirstName','LastName','MiddleName')  then accof.Field 
							 when pin.id is  null and accof.Field in  ('FirstName','LastName','MiddleName')  then null 
							 else accof.Field
						end as Field, 
						case when pin.id is not null and accof.Field in  ('FirstName','LastName','MiddleName')  then accof.Value 
							 when pin.id is  null and accof.Field in  ('FirstName','LastName','MiddleName')  then null 
							 else accof.Value
						end as Value */
				FROM edw_temp.tquote_temp1 acc
					left JOIN edw_stage.AccountObject acco ON acco.AccountId = acc.Id
					left JOIN edw_stage.AccountObjectField accof ON accof.ObjectId = acco.id
					--left join edw_stage.AccountObjectField pin on pin.objectid = acco.id and pin.field = 'IsPrimaryInsured' and pin.Value = 'True'
				WHERE COALESCE(LTRIM(RTRIM(accof.Field)), '''') != '''' 
                --and acc.policynumber = 'HO200025786' 
				/*SELECT  acctv.AccountTransactionId, --acctvof.Field, acctvof.Value 
						case when pin.id is not null and acctvof.Field in  ('FirstName','LastName','MiddleName')  then acctvof.Field 
							 when pin.id is  null and acctvof.Field in  ('FirstName','LastName','MiddleName')  then null 
							 else acctvof.Field
						end as Field, 
						case when pin.id is not null and acctvof.Field in  ('FirstName','LastName','MiddleName')  then acctvof.Value 
							 when pin.id is  null and acctvof.Field in  ('FirstName','LastName','MiddleName')  then null 
							 else acctvof.Value
						end as Value
				FROM edw_temp.tquote_temp1 acc
					left JOIN edw_stage.AccountTransaction acct ON acct.AccountId = acc.Id --acctv.AccountTransactionId = acc.Id
					left JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id --acctv.AccountTransactionId = acc.Id
					left JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
					left JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
					left join edw_stage.AccountTransactionVersionObjectField pin on pin.versionobjectid = acctvo.id and pin.field = 'IsPrimaryInsured' and pin.Value = 'True'
				WHERE COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') != '''' --and acc.policynumber = 'HO100024581' */
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (InsuredType, NamedInsured, FirstName, LastName, MiddleName, Prefix, Suffix, 
										 CompanyName, MailingAddressLine1, MailingAddressLine2, MailingAddressLineUnit, 
				MailingAddressCity, MailingAddressState, MailingAddressZipCode, MailingAddressCounty, MailingAddressCountry, Program)
			) pivottable

			

		-- Start Merge process
		MERGE edw_core.tquote AS Target
		USING (
			SELECT 
				tmp1.PolicyNumber,
				tmp1.EffectiveDate,
				tmp1.ExpirationDate, 
				case when br.producerid is null then '0' else br.producerid end as BrokerId,
				ins.ReferenceCode as customer_id,
				nullif(trim(pr.ProductCode),'') product_cd,
				nullif(trim(COALESCE(tmp1.RiskStateCode, 'DNA')),'') as RiskStateCode, --review
				--nullif(trim(isnull(tmp2.Prefix + ' ','') + isnull(tmp2.FirstName + ' ','') 
				--+ isnull(tmp2.LastName + ' ','') + isnull(tmp2.MiddleName + ' ','') + isnull(tmp2.Suffix,'')),'') 
				ins.NamedInsured as insured_nm,
				tmp2.InsuredType as insured_type,
				case when tmp1.IsRenewal = 1 then 'Renewal' else 'New' end as policy_term,
				case when trim(pr.ProductCode) = 'AU' then 'Vault Reciprocal Exchange' 
				     when tmp2.program = 'Admitted' then 'Vault Reciprocal Exchange' 
				     when tmp2.program = 'Non-Admitted' then 'Vault E & S Insurance Company' 
				     else null
				end as uw_company_nm,
				--tmp2.CompanyName as uw_company_nm,
				case when trim(pr.ProductCode) = 'AU' then 'Admitted' 
				     else tmp2.program
				end as program,
				--tmp1.State,
				tmp1.TransactionEffectiveDate,
				tmp1.OriginalEffectiveDate,
				tmp2.MailingAddressLine1,
				tmp2.MailingAddressLine2,
				tmp2.UnitFloor,
				tmp2.MailingAddressCity,
				tmp2.MailingAddressState,
				case when len(tmp2.MailingAddressZipCode) < 250 then tmp2.MailingAddressZipCode else null end MailingAddressZipCode, 
				tmp2.MailingAddressCounty,
				tmp2.MailingAddressCountry,  
				case when tmp1.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end source_system_sk,
				tmp1.CreatedDate,
				tmp1.UpdatedDate 
				,case when charindex('-',tmp1.PolicyNumber) <> 0
					 then substring(tmp1.PolicyNumber,1,charindex('-',tmp1.PolicyNumber)-1) 
					 else tmp1.PolicyNumber  
				end as original_policy_no
				,acc_prior.PolicyNumber  prior_policy_no
				,'No' as non_renewal_in
				, tmp1.renewalofpolicynumber
				, tb.billingaccount_sk
                ,case when tmp1.state = 'WIP' 
					  then 'In Progress' 
					  else upper(substring(tmp1.state,1,1)) + lower(substring(tmp1.state, 2, len(tmp1.state)-1))  
				end as [state],
				case when tmp1.ExternalSourceId is not null then 'Yes' else 'No' end  migrated_in,
				prior_pol.policy_sk prior_pol_policy_sk
				--select *
			FROM 
				edw_temp.tquote_temp1 tmp1
				--left JOIN edw_stage.AccountTransaction acct ON acct.AccountId = tmp1.Id
				--left JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id
				--inner join edw_stage.Account acc on tmp1.AccountId = acc.Id 
				left join edw_stage.Account acc_prior on tmp1.copyofAccountId = acc_prior.Id 
				left join edw_stage.BillingAccount ba on ba.id = tmp1.BillingAccountId
				left join edw_core.tbillingaccount tb on tb.billingaccount_no = ba.ReferenceCode
				left join edw_stage.Brokerage br on tmp1.BrokerageId = br.id
				left join edw_stage.Insured ins on tmp1.PrimaryInsuredId = ins.Id
				left join edw_stage.Product pr on tmp1.ProductId = pr.id
				left join edw_temp.tquote_temp2 tmp2 on tmp2.id = tmp1.Id
				left join edw_core.tpolicy prior_pol on  tmp1.renewalofpolicynumber = prior_pol.policy_no and cast(tmp1.effectivedate as date) = prior_pol.expiration_dt
				where pr.productline <> 'CommercialLines' --and tmp1.policynumber = 'CO100023657'
		) AS Source
		ON Source.PolicyNumber = Target.quote_no --and cast(Source.EffectiveDate as date) = cast(Target.effective_dt as date)
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			quote_no
           ,effective_dt
           ,expiration_dt
           ,broker_id
           ,customer_id
           ,product_cd
           ,risk_state_cd
           ,insured_nm
		   ,insured_type 
		   ,uw_company_nm
           ,program_type  
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
		   ,quote_term
		   ,prior_term_policy_no
           ,source_system_sk
		   ,billingaccount_sk
           ,quote_create_ts
           ,create_ts
           ,update_ts
           ,etl_audit_sk
           ,[quote_source_status]
		   ,migrated_in
		   ,prior_term_policy_sk
			)
		VALUES (Source.PolicyNumber, 
				Source.EffectiveDate, 
                Source.ExpirationDate, 
                Source.BrokerId, 
                Source.customer_id, 
				Source.product_cd,
				Source.RiskStateCode,
				Source.insured_nm,
				Source.insured_type, 
				Source.uw_company_nm, 
				Source.program, 
				source.original_policy_no,
				Source.OriginalEffectiveDate, 
				Source.MailingAddressLine1, 
				Source.MailingAddressLine2, 
				Source.UnitFloor, 
				Source.MailingAddressCity,
				Source.MailingAddressState, 
				Source.MailingAddressZipCode, 
				Source.MailingAddressCounty, 
				Source.MailingAddressCountry, 
				source.prior_policy_no, 
				source.policy_term,
				source.renewalofpolicynumber,
				Source.source_system_sk
		   		,Source.billingaccount_sk, 
				source.createddate,
				getdate(), getdate(), @etl_audit_sk
                ,source.state
				,source.migrated_in
				,source.prior_pol_policy_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.Effective_dt					= Source.EffectiveDate,
        Target.broker_id					= Source.BrokerId,
        Target.customer_id					= Source.customer_id,
        Target.risk_state_cd				= Source.RiskStateCode,
        Target.insured_nm					= Source.insured_nm,
        Target.insured_type					= Source.insured_type, 
        Target.uw_company_nm				= Source.uw_company_nm,
        Target.program_type					= Source.program,
        Target.original_policy_no			= Source.original_policy_no,
        Target.original_policy_effective_dt	= Source.OriginalEffectiveDate,
        Target.mailing_address_line1		= Source.MailingAddressLine1,
        Target.mailing_address_line2		= Source.MailingAddressLine2,
        Target.mailing_address_unit_no		= Source.UnitFloor,
        Target.mailing_address_city_nm		= Source.MailingAddressCity,
        Target.mailing_address_state_cd		= Source.MailingAddressState,
		Target.mailing_address_zip_cd		= Source.MailingAddressZipCode,
        Target.mailing_address_county_nm	= Source.MailingAddressCounty,
		Target.mailing_address_country_nm	= Source.MailingAddressCountry, 
		Target.prior_policy_no				= source.prior_policy_no, 
		Target.prior_term_policy_no			= source.renewalofpolicynumber, 
		Target.quote_term					= source.policy_term, 
		Target.billingaccount_sk			= source.billingaccount_sk, 
		Target.source_system_sk			    = source.source_system_sk, 
		Target.quote_source_status			= source.state, 
		Target.migrated_in			    	= source.migrated_in, 
		Target.prior_term_policy_sk			= source.prior_pol_policy_sk, 
        Target.update_ts 					= getdate()
		;

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(CreatedDate,UpdatedDate)) FROM edw_temp.tquote_temp1 t2),@last_source_extract_ts);
		

        DROP TABLE IF EXISTS edw_temp.tquote_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_temp2;
		
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

