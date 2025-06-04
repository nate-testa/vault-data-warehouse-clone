-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-28
-- Description: This stored procedure insert and update info related to tcommercial_quote.
-----------------------------------------------------------------------------------------------------------------------
-- Change date        |Author							   |	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 28/03/25           Alberto Almario				1. Created this procedure 
-- 22/04/25           Alberto Almario				2. Change PolicyNumber to Number from Account table
-- 02/05/25           Architha Gudimalla		 3. Removed quote_status
-- 14/05/25           Alberto Almario				4. Add new columns prior_policy_no and prior_term_policy_no
-- 05/29/25			 Yunus Mohammed		  	  5. AD-9649 Update Merge statement join
-- ===================================================================================================================== 
CREATE or ALTER  PROCEDURE [edw_core].[sp_tcommercial_quote]

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

		update 	edw_stage.Account
		set 	EffectiveDate = cast(createddate as date), ExpirationDate  = cast(createddate as date)
		where 	EffectiveDate is null
		AND 	greatest(CreatedDate,UpdatedDate)>@last_source_extract_ts;

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp1;
		SELECT 
			acc.*
			,CASE 
				WHEN acc.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
				ELSE 4 --(Metal)
			END source_system_sk 
		into edw_temp.tcommercial_quote_temp1
		FROM edw_stage.Account acc 
		left join edw_stage.Product pr on acc.ProductId = pr.id
		WHERE pr.ProductLine = 'CommercialLines' 
		AND greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp2;
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
		INTO edw_temp.tcommercial_quote_temp2
		FROM
			(
				SELECT  acc.id, accof.Field, accof.Value 
				FROM edw_temp.tcommercial_quote_temp1 acc
					left JOIN edw_stage.AccountObject acco ON acco.AccountId = acc.Id
					left JOIN edw_stage.AccountObjectField accof ON accof.ObjectId = acco.id
				WHERE COALESCE(LTRIM(RTRIM(accof.Field)), '''') != ''''
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (InsuredType, NamedInsured, FirstName, LastName, MiddleName, Prefix, Suffix, 
										 CompanyName, MailingAddressLine1, MailingAddressLine2, MailingAddressLineUnit, 
				MailingAddressCity, MailingAddressState, MailingAddressZipCode, MailingAddressCounty, MailingAddressCountry, Program)
			) pivottable

		-- Create last temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp3;
		SELECT 
			 CAST(tmp1.Number AS VARCHAR(255)) as quote_no
			,tmp1.EffectiveDate as effective_dt
			,tmp1.ExpirationDate as expiration_dt
			,case when br.producerid is null then '0' else br.producerid end as broker_id
			,ins.ReferenceCode as customer_id
			,nullif(trim(pr.ProductCode),'') as product_cd
			,nullif(trim(COALESCE(tmp1.RiskStateCode, 'DNA')),'') as risk_state_cd
			,case when tmp1.RenewalIndex = 0 then 'New' else 'Renewal' end as quote_term
			,tmp1.State as quote_status
			,case when tmp1.state = 'WIP' then 'In Progress' else upper(substring(tmp1.state,1,1)) + lower(substring(tmp1.state, 2, len(tmp1.state)-1)) end as quote_source_status
			,ins.NamedInsured as insured_nm
			,tmp2.MailingAddressLine1 as mailing_address_line1
			,tmp2.MailingAddressLine2 as mailing_address_line2
			,tmp2.UnitFloor as mailing_address_unit_no
			,tmp2.MailingAddressCity as mailing_address_city_nm
			,tmp2.MailingAddressState as mailing_address_state_cd
			,case when len(tmp2.MailingAddressZipCode) < 250 then tmp2.MailingAddressZipCode else null end as mailing_address_zip_cd
			,tmp1.createddate as quote_create_ts
			,NULL as policy_sk
			,prior_pol.commercial_policy_sk as prior_term_policy_sk
			,cast(NULL as date) as bind_dt
			,case when tmp1.SubmissionCloseReasonCategory is not null then tmp1.SubmissionCloseReasonDetails else tmp1.CloseReasonType end as close_reason_desc
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,tmp1.source_system_sk
			,case when acc_prior.PolicyNumber is not null then acc_prior.PolicyNumber else acc_rw.PolicyNumber end as prior_policy_no
			,tmp1.renewalofpolicynumber as prior_term_policy_no
		INTO edw_temp.tcommercial_quote_temp3
		FROM edw_temp.tcommercial_quote_temp1 tmp1
		left join edw_stage.Account acc_prior on tmp1.copyofAccountId = acc_prior.Id 
		left join edw_stage.Account acc_rw on tmp1.rewrittenfromaccountid = acc_rw.Id
		left join edw_stage.BillingAccount ba on ba.id = tmp1.BillingAccountId
		left join edw_core.tbillingaccount tb on tb.billingaccount_no = ba.ReferenceCode
		left join edw_stage.Brokerage br on tmp1.BrokerageId = br.id
		left join edw_stage.Insured ins on tmp1.PrimaryInsuredId = ins.Id
		left join edw_stage.Product pr on tmp1.ProductId = pr.id
		left join edw_temp.tcommercial_quote_temp2 tmp2 on tmp2.id = tmp1.Id
		left join edw_commercial.tcommercial_policy prior_pol on  tmp1.renewalofpolicynumber = prior_pol.policy_no and cast(tmp1.effectivedate as date) = prior_pol.expiration_dt
		where pr.productline = 'CommercialLines'
			

		-- Start Merge process
		MERGE edw_commercial.tcommercial_quote AS Target
		USING edw_temp.tcommercial_quote_temp3 AS Source
		ON Source.quote_no = Target.quote_no
			AND (
						(Source.quote_term = 'New'  AND YEAR(Target.effective_dt) = YEAR(Source.effective_dt))
						OR
						(Source.quote_term != 'New'  AND Target.effective_dt = Source.effective_dt)
    			)
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
			,quote_term
			--,quote_status
			,quote_source_status
			,insured_nm
			,mailing_address_line1
			,mailing_address_line2
			,mailing_address_unit_no
			,mailing_address_city_nm
			,mailing_address_state_cd
			,mailing_address_zip_cd
			,quote_create_ts
			,commercial_policy_sk
			,prior_term_commercial_policy_sk
			,bind_dt
			,close_reason_desc
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
			,prior_policy_no
			,prior_term_policy_no
		)
		VALUES (
			 quote_no
			,effective_dt
			,expiration_dt
			,broker_id
			,customer_id
			,product_cd
			,risk_state_cd
			,quote_term
			--,quote_status
			,quote_source_status
			,insured_nm
			,mailing_address_line1
			,mailing_address_line2
			,mailing_address_unit_no
			,mailing_address_city_nm
			,mailing_address_state_cd
			,mailing_address_zip_cd
			,quote_create_ts
			,policy_sk
			,prior_term_policy_sk
			,bind_dt
			,close_reason_desc
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
			,prior_policy_no
			,prior_term_policy_no
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			 Target.effective_dt = Source.effective_dt
			,Target.expiration_dt = Source.expiration_dt
			,Target.broker_id = Source.broker_id
			,Target.customer_id = Source.customer_id
			,Target.product_cd = Source.product_cd
			,Target.risk_state_cd = Source.risk_state_cd
			,Target.quote_term = Source.quote_term
			--,Target.quote_status = Source.quote_status
			,Target.quote_source_status = Source.quote_source_status
			,Target.insured_nm = Source.insured_nm
			,Target.mailing_address_line1 = Source.mailing_address_line1
			,Target.mailing_address_line2 = Source.mailing_address_line2
			,Target.mailing_address_unit_no = Source.mailing_address_unit_no
			,Target.mailing_address_city_nm = Source.mailing_address_city_nm
			,Target.mailing_address_state_cd = Source.mailing_address_state_cd
			,Target.mailing_address_zip_cd = Source.mailing_address_zip_cd
			,Target.quote_create_ts = Source.quote_create_ts
			,Target.commercial_policy_sk = Source.policy_sk
			,Target.prior_term_commercial_policy_sk = Source.prior_term_policy_sk
			,Target.bind_dt = Source.bind_dt
			,Target.close_reason_desc = Source.close_reason_desc
			,Target.update_ts = getdate()
			,Target.source_system_sk = Source.source_system_sk
			,Target.prior_policy_no = Source.prior_policy_no
			,Target.prior_term_policy_no = Source.prior_term_policy_no
		;

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(CreatedDate,UpdatedDate)) FROM edw_temp.tcommercial_quote_temp1 t2),@last_source_extract_ts);
		

        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_temp3;
		
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
;
