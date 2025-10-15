-- ================================================================================================= 
-- Author:		Yunus Mohammed
-- Description: This procedures inserts the np01 data for carrier feed
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						        |	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 08/11/25					Yunus Mohammed			1. Created this procedure
-- 10/14/25					Yunus Mohammed			2. AD-11333 Update made for international addresses		
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_policy_current_carrier_auto_np01_feed]
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
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_np01_feed_temp1;
        DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_np01_feed_temp2;
		
        declare @isfirstday int = 0
		declare @reporting_period_begin_dt date,@reporting_period_end_dt date

        if(cast(@last_source_extract_ts as date) = '1900-01-01')
        begin
            set @isfirstday = 1
        end

        if(@isfirstday=1)
        begin
            select distinct tph.policy_history_sk
            into edw_temp.policy_current_carrier_auto_np01_feed_temp1
            from 
            edw_core.tpolicy tp
            inner join edw_core.tpolicy_history tph on tp.policy_sk = tph.policy_sk
            where tp.product_cd = 'AU'
            and tp.policy_status = 'Active'
            and cast(tph.transaction_ts as date) < = cast(dateadd(dd,-1,getdate()) as date)			
        end
        else
        begin
            select distinct tph.policy_history_sk
            into edw_temp.policy_current_carrier_auto_np01_feed_temp1
            from 
            edw_core.tpolicy tp
            inner join edw_core.tpolicy_history tph on tp.policy_sk = tph.policy_sk
            where tp.product_cd = 'AU'
            and tp.policy_status = 'Active'
            and cast(tph.transaction_ts as date)> cast(@last_source_extract_ts as date)
            and cast(tph.transaction_ts as date) < =cast(dateadd(dd,-1,getdate()) as date)
        end

		select 'NP01' AS [RecordCode],
		CASE
		WHEN tp.uw_company_nm = 'Vault Reciprocal Exchange' then '20564'
		WHEN tp.uw_company_nm ='Vault E & S Insurance Company' then '20586' 
		else ''
		end as [ContribCompanyAMBestNumber],
		case when CHARINDEX('-', tp.policy_no) >0 then 
			LEFT(tp.policy_no, CHARINDEX('-', tp.policy_no) - 1)
		else tp.policy_no end as [PolicyNumber],
		'PA' AS [InsuranceType],		
		case
			when (@isfirstday = 1 and cast(tph.effective_dt as date)<= cast(getdate() as date)) then FORMAT(getdate(),'yyyyMMdd')
			when @isfirstday = 1 then FORMAT(tph.effective_dt,'yyyyMMdd')
			else
				FORMAT(tph.transaction_effective_dt,'yyyyMMdd')
		end as [ChangeEffectiveDate],
		CASE
		WHEN tp.uw_company_nm = 'Vault Reciprocal Exchange' then 'VRE'
		WHEN tp.uw_company_nm ='Vault E & S Insurance Company' then 'VES'
		END AS [ContribCompanyName],
		'' AS [RiskType],
		'AU' AS [PolicyType],
		CASE
		WHEN tp.uw_company_nm = 'Vault Reciprocal Exchange' then '16186'
		WHEN tp.uw_company_nm ='Vault E & S Insurance Company' then '16237'
		END AS [NAICCode],
        FORMAT(		
			case 
			when tp.policy_term = 'New' and tp.original_policy_effective_dt is null then tp.effective_dt
			else tp.original_policy_effective_dt
			end ,'yyyyMMdd') as [PolicyInceptionDate],
        FORMAT(tp.expiration_dt,'yyyyMMdd') as [PolicyPeriodEndDate],
        FORMAT(tp.effective_dt,'yyyyMMdd') as [PolicyPeriodBeginDate],
		case 
			when policy_status = 'Cancelled' then FORMAT(tp.cancellation_effective_dt,'yyyyMMdd')			
		end	as [PolicyCancellationDate],
        NULL AS [PolicyPremium],
        CAST('' AS char(1)) AS [PremiumPaymentPlan],
        CAST('' AS char(3)) AS [PremiumMethodPayment],
        CAST('' AS char(1))  AS [Reserved1],
        SUBSTRING(tp.mailing_address_line1, 1, PATINDEX('%[^0-9]%', tp.mailing_address_line1 + 'x') - 1) AS [PolicyHolderMailAddressHouseNum],
        LEFT(TRIM(SUBSTRING(tp.mailing_address_line1, PATINDEX('%[^0-9]%', tp.mailing_address_line1), 30)), 20)  AS [PolicyHolderMailAddressStreetName],
        LEFT(tp.mailing_address_unit_no, 5) as [PolicyHolderMailAddressAptNum],
        LEFT(tp.mailing_address_city_nm,20) AS [PolicyHolderMailAddressCity],
		CASE
			WHEN EXISTS(select 1 from edw_core.tstate s where s.state_cd = tp.mailing_address_state_cd) THEN
       				LEFT(tp.mailing_address_state_cd,2)
			ELSE
				'YY'
		END AS [PolicyHolderMailAddressState],
		CASE
			WHEN EXISTS(select 1 from edw_core.tstate s where s.state_cd = tp.mailing_address_state_cd) THEN
       				LEFT(tp.mailing_address_zip_cd,5)
			ELSE
					'00001'
		END  AS [PolicyHolderMailAddressZip], -- Todo
        NULL AS [PolicyHolderMailAddressZipPlus4],        
        '' as [PolicyHolderTelephoneAreaCode],
        '' as [PolicyHolderTelephoneNumber],
        '' as [PolicyHolderTelephoneExtension],
		'' AS Reserved2,
		'' AS Reserved3,
		'' AS AgentIdentifier,
		tp.risk_state_cd AS PolicyState,
        tp.policy_sk,
        tp.policy_no ,
        tph.policy_history_sk,
        transaction_seq_no,
        tph.transaction_ts,
        getdate() as create_ts,
        getdate() as update_ts,
        @etl_audit_sk as etl_audit_sk
        into edw_temp.policy_current_carrier_auto_np01_feed_temp2
        from
            edw_temp.policy_current_carrier_auto_np01_feed_temp1 t
            inner join edw_core.tpolicy_history tph on t.policy_history_sk = tph.policy_history_sk
            inner join edw_core.tpolicy tp on tp.policy_sk = tph.policy_sk
				
		SELECT
		@reporting_period_begin_dt = case 
		 															when @isfirstday = 1 then min(transaction_ts)
																	else
																		(
																			select DATEADD(day, 1, MAX(reporting_period_end_dt))
																			FROM
																				edw_integration.policy_current_carrier_auto_np01_feed
																		)
																	end,
		@reporting_period_end_dt =  max(transaction_ts)
		from
			edw_temp.policy_current_carrier_auto_np01_feed_temp2
		
		INSERT INTO edw_integration.policy_current_carrier_auto_np01_feed
        (
            RecordCode,ContribCompanyAMBestNumber,PolicyNumber,InsuranceType,ChangeEffectiveDate,ContribCompanyName,
            RiskType,PolicyType,NAICCode,PolicyInceptionDate,PolicyPeriodEndDate,PolicyPeriodBeginDate,PolicyCancellationDate,PolicyPremium,
            PremiumPaymentPlan,PremiumMethodPayment,Reserved1,policyHolderMailAddressHouseNum,
            PolicyHolderMailAddressStreetName,policyHolderMailAddressAptNum,policyHolderMailAddressCity,policyHolderMailAddressState,
            policyHolderMailAddressZip,policyHolderMailAddressZipPlus4,policyHolderTelephoneAreaCode,policyHolderTelephoneNumber,
            policyHolderTelephoneExtension,Reserved2,Reserved3,AgentIdentifier,PolicyState,
            policy_sk,policy_no,policy_history_sk,transaction_seq_no,transaction_ts,reporting_period_begin_dt,reporting_period_end_dt,
            create_ts,update_ts,etl_audit_sk
        )			

		SELECT
		RecordCode,ContribCompanyAMBestNumber,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyNumber,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyNumber,
		REPLACE(REPLACE(REPLACE(ISNULL(InsuranceType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as InsuranceType,
		RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(ChangeEffectiveDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as ChangeEffectiveDate,
		LEFT(REPLACE(REPLACE(REPLACE(ISNULL(ContribCompanyName,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' '),20) as ContribCompanyName,
        REPLACE(REPLACE(REPLACE(ISNULL(RiskType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as RiskType,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyType,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyType,
		RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(NAICCode,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as NAICCode,
		RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyInceptionDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as PolicyInceptionDate,
		RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyPeriodEndDate,''), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as PolicyPeriodEndDate,
		RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyPeriodBeginDate,'00'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as PolicyPeriodBeginDate,
		RIGHT('00000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyCancellationDate,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),8) as PolicyCancellationDate,
		RIGHT('0000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyPremium,'0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),7) as PolicyPremium,
        REPLACE(REPLACE(REPLACE(ISNULL(PremiumPaymentPlan,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PremiumPaymentPlan,
		REPLACE(REPLACE(REPLACE(ISNULL(PremiumMethodPayment,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PremiumMethodPayment,
		REPLACE(REPLACE(REPLACE(ISNULL(Reserved1,''), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as Reserved1,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressHouseNum, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyHolderMailAddressHouseNum,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressStreetName, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyHolderMailAddressStreetName,
        REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressAptNum, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyHolderMailAddressAptNum,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressCity, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyHolderMailAddressCity,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressState, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') as PolicyHolderMailAddressState,
        RIGHT('00000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressZip, '0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),5) as PolicyHolderMailAddressZip,
		RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderMailAddressZipPlus4, '0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as PolicyHolderMailAddressZipPlus4,
		RIGHT('000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderTelephoneAreaCode, '0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),3) as PolicyHolderTelephoneAreaCode,
		RIGHT('0000000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderTelephoneNumber, '0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),7) as PolicyHolderTelephoneNumber,
        RIGHT('0000'+ REPLACE(REPLACE(REPLACE(ISNULL(PolicyHolderTelephoneExtension, '0'), CHAR(9), '0'), CHAR(13), '0'), CHAR(10), '0'),4) as PolicyHolderTelephoneExtension,
		Reserved2,Reserved3,
		REPLACE(REPLACE(REPLACE(ISNULL(AgentIdentifier, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ')  as AgentIdentifier,
		REPLACE(REPLACE(REPLACE(ISNULL(PolicyState, ' '), CHAR(9), ' '), CHAR(13), ' '), CHAR(10), ' ') PolicyState,
        policy_sk,policy_no,policy_history_sk,transaction_seq_no,transaction_ts,
		@reporting_period_begin_dt,@reporting_period_end_dt,
        create_ts,update_ts,etl_audit_sk
		FROM 
			edw_temp.policy_current_carrier_auto_np01_feed_temp2		
		
		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(transaction_ts) FROM edw_temp.policy_current_carrier_auto_np01_feed_temp2),@last_source_extract_ts);

		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		
		DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_np01_feed_temp1;
        DROP TABLE IF EXISTS edw_temp.policy_current_carrier_auto_np01_feed_temp2;
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