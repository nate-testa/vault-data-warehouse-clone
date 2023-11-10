-- =================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2023-11-10
-- Description: This procedures inserts quote insured data
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_insured]

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

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.tquote_insured_temp1
        SELECT
			acctr.*,
			case when acctr.ExternalSourceId is not NULL then 2--(AV2) 
				 Else 4 --(Metal)
			end ssk
		INTO edw_temp.tquote_insured_temp1
		FROM edw_stage.AccountTransaction acctr
		left join edw_stage.Product pr on acctr.ProductId = pr.id
		WHERE PolicyNumber is not null 
		  and acctr.State ='ISSUED' --- Review BOUND transactions
		  and pr.ProductLine='PersonalLines'
		  AND acctr.IssuedDate>@last_source_extract_ts

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tquote_insured_temp2; 
		SELECT	AccountTransactionId, versionobjectid, 
				nullif(trim(NamedInsured),'') NamedInsured, 
				nullif(trim(DBA),'') DBA ,
				nullif(trim(FirstName),'') FirstName, 
				nullif(trim(MiddleName),'') MiddleName ,
				nullif(trim(LastName),'') LastName ,
				nullif(trim(InsuredType),'') InsuredType ,
				replace(replace(nullif(trim(IsPrimaryInsured),''),'True','Yes'),'False','No') IsPrimaryInsured ,
				nullif(trim(Birthdate),'') Birthdate ,
				nullif(trim(HomePhone),'') HomePhone ,
				nullif(trim(MobilePhone),'') MobilePhone ,
				nullif(trim(Prefix),'') Prefix ,
				nullif(trim(Suffix),'') Suffix ,
				nullif(trim(MailingAddressLine1),'') MailingAddressLine1 ,
				nullif(trim(MailingAddressLine2),'') MailingAddressLine2 ,
				nullif(trim(UnitFloor),'') UnitFloor ,
				nullif(trim(MailingAddressCity),'') MailingAddressCity ,
				nullif(trim(MailingAddressState),'') MailingAddressState ,
				nullif(trim(MailingAddressZipCode),'') MailingAddressZipCode ,
				nullif(trim(MailingAddressCounty),'') MailingAddressCounty ,
				nullif(trim(MailingAddressCountry),'') MailingAddressCountry, 
				nullif(trim(IncludeOnDec),'') IncludeOnDec ,
				nullif(trim(Email),'') Email,
				nullif(trim(Employer),'') Employer,
				nullif(trim(InsuranceScore),'') InsuranceScore,
				nullif(trim(InsuranceScoreCode1),'') InsuranceScoreCode1,
				nullif(trim(InsuranceScoreCode2),'') InsuranceScoreCode2,
				nullif(trim(InsuranceScoreCode3),'') InsuranceScoreCode3,
				nullif(trim(InsuranceScoreCode4),'') InsuranceScoreCode4,
				nullif(trim(SubscriberContributionEndDate),'') SubscriberContributionEndDate,
				nullif(trim(IsCoInsured),'') IsCoInsured,
				nullif(trim(Title),'') Title
				
		INTO edw_temp.tquote_insured_temp2
		FROM
			(
				SELECT  acctv.AccountTransactionId, versionobjectid,
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tquote_insured_temp1 acc
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id --acctv.AccountTransactionId = acc.Id
				INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
				INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') != '''' --and acc.policynumber = 'HO100024581' 
				and acctvo.objecttype='Insured' 
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (NamedInsured, DBA, FirstName, MiddleName, LastName, InsuredType, IsPrimaryInsured, 
										 Birthdate, HomePhone, MobilePhone, Prefix, Suffix, 
										 MailingAddressLine1, MailingAddressLine2, UnitFloor, MailingAddressCity, 
										 MailingAddressState, MailingAddressZipCode, MailingAddressCounty, MailingAddressCountry, 
										 IncludeOnDec, Email, Employer, InsuranceScore,
										 InsuranceScoreCode1, InsuranceScoreCode2, InsuranceScoreCode3, InsuranceScoreCode4,
										 SubscriberContributionEndDate, IsCoInsured, Title)
			) pivottable

		INSERT into edw_core.tquote_insured
			(
				quote_no, effective_dt, transaction_effective_dt, transaction_seq_no, quote_history_sk, 
				insured_nm, dba_nm, first_nm, middle_nm, last_nm, insured_type, primary_insured_in, 
				coinsured_in, birth_dt, home_phone_no, mobile_phone_no, title, prefix, suffix, 
				mailing_address_line_1, mailing_address_line_2, mailing_address_unit_no, 
				mailing_address_city_nm, mailing_address_state_cd, mailing_address_zip_cd, mailing_address_county_nm, mailing_address_country_nm, 
				include_on_dec_in, email, employer_nm, insurance_score, 
				insurance_score_cd1, insurance_score_desc1, insurance_score_cd2, insurance_score_desc2, 
				insurance_score_cd3, insurance_score_desc3, insurance_score_cd4, insurance_score_desc4, subscriber_contribution_end_dt,
				source_system_sk, create_ts, update_ts, etl_audit_sk 
			)
		select 	t1.PolicyNumber, t1.EffectiveDate, t1.TransactionEffectiveDate, t1.PolicyChangeNumber, qh.quote_history_sk, 
				case when nullif(trim(isnull(t2.Prefix + ' ','') + isnull(t2.FirstName + ' ','') 
				+ isnull(t2.LastName + ' ','') + isnull(t2.MiddleName + ' ','') + isnull(t2.Suffix,'')),'') is null
				then NamedInsured else nullif(trim(isnull(t2.Prefix + ' ','') + isnull(t2.FirstName + ' ','') 
				+ isnull(t2.LastName + ' ','') + isnull(t2.MiddleName + ' ','') + isnull(t2.Suffix,'')),'') end as  NamedInsured, 
				t2.DBA, t2.FirstName, t2.MiddleName, t2.LastName, t2.InsuredType,t2.IsPrimaryInsured, 
				t2.IsCoInsured, t2.Birthdate, t2.HomePhone, t2.MobilePhone, t2.Title, t2.Prefix, t2.Suffix, 
				t2.MailingAddressLine1, t2.MailingAddressLine2, t2.UnitFloor, t2.MailingAddressCity, 
				t2.MailingAddressState, t2.MailingAddressZipCode, t2.MailingAddressCounty, t2.MailingAddressCountry, 
				t2.IncludeOnDec, t2.Email, t2.Employer, t2.InsuranceScore,
				t2.InsuranceScoreCode1, '', InsuranceScoreCode2, '', InsuranceScoreCode3, '', InsuranceScoreCode4, '', 
				t2.SubscriberContributionEndDate, t1.ssk, getdate(), getdate(), @etl_audit_sk
		FROM 	edw_temp.tquote_insured_temp1 t1
		INNER JOIN edw_temp.tquote_insured_temp2 t2 on t1.id = t2.AccountTransactionId
		LEFT JOIN edw_core.tquote quo on t1.PolicyNumber = quo.quote_no and cast(t1.EffectiveDate as date) = quo.effective_dt
		LEFT JOIN edw_core.tquote_history qh on qh.quote_no = quo.quote_no and qh.effective_dt = quo.effective_dt and qh.transaction_seq_no = t1.PolicyChangeNumber 
		;

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX((t1.IssuedDate)) FROM edw_temp.tquote_insured_temp1 t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.tquote_insured_temp1
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
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

