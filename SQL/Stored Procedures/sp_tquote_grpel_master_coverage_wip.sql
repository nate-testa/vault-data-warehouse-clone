-- ========================================================================================================================================
-- Description: This procedures inserts and updates tgrpel_master_coverage 
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date		|Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 03/04/26			Yunus Mohammed				1. Created this procedure
-- ======================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_master_coverage_wip]

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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));

		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_wip_temp2;

		SELECT
			Id,PolicyNumber,EffectiveDate,0 as transaction_seq_no,ExpirationDate,CreatedDate,
			source_system_sk,
			broker_id,customer_id,product_cd,risk_state_cd,
			InsuredType as insured_type,
			case 
				when nullif(isnull(FirstName + ' ','') + isnull(LastName,''),'') is not null
				then nullif(isnull(FirstName + ' ','')	+ isnull(LastName,''),'') 
			when NamedInsured is not null then NamedInsured
			else NamedInsured 
			end as insured_nm,			
			MailingAddressLine1 as mailing_address_line1, MailingAddressLine2 as mailing_address_line2, 
			MailingAddressCity as mailing_address_city_nm, MailingAddressState as mailing_address_state_cd, 
			MailingAddressZipCode as mailing_address_zip_cd, 
			MailingAddressCounty as mailing_address_county_nm, MailingAddressCountry as mailing_address_country_nm,
			FirstName as insured_first_nm,
			LastName as insured_last_nm,
			MobilePhone as mobile_phone_no,
			Email as email,
			UnderlyingLiability as auto_liability_limit_amt,AvgHomesNumber as no_of_average_homes,
			AvgVehicleNumber as no_of_average_vehicles,
			AvgWatercraftNumber as no_of_average_watercraft,
			YouthfulDriverNumber as no_of_youthful_driver,
			MVRTriggerRule as mvr_trigger_rule,
			CommissionPercentage as commission_pc,
			MinimumPremium as minimum_premium_amt,
			PriorNFPPolicyNumber as prior_nfp_policy_no,
			NFPExpiring as prior_nfp_policy_expiring_dt
		into edw_temp.tquote_grpel_master_coverage_wip_temp1
		from
		(
			select 
				acc.Id,acc.PolicyNumber,acc.EffectiveDate,acc.ExpirationDate,acc.CreatedDate,acc.UpdatedDate,
				case when acc.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end source_system_sk,
				br.producerid as broker_id,
				ins.ReferenceCode as customer_id,
				nullif(trim(acc.ProductCode),'') product_cd,
				nullif(trim(COALESCE(acc.RiskStateCode, 'DNA')),'') as risk_state_cd,
				accof.Field,
				accof.[Value]
			from
                (
                    SELECT a.*,p.ProductCode
                    FROM [edw_stage].[Account] AS a
                    inner join edw_stage.Product p on p.Id=a.ProductId and p.ProductLine = 'GroupPersonalLines' 
                    WHERE 
                        NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(a.CreatedDate,a.UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                ) as acc
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
					and acco.ObjectType in ('Insured','GroupPersonalExcessLiability')
				left join edw_stage.Brokerage br on acc.BrokerageId = br.Id
				left join edw_stage.Insured ins on acc.PrimaryInsuredId = ins.Id				
		) as a
		PIVOT 
		(
			MAX(Value) FOR Field IN 
			(
				-- Insured
				InsuredType, NamedInsured, FirstName, LastName, MobilePhone, Email,
				MailingAddressLine1, MailingAddressLine2, MailingAddressLineUnit, 
				MailingAddressCity, MailingAddressState, MailingAddressZipCode, MailingAddressCounty, MailingAddressCountry

				-- GroupPersonalExcessLiability
				,UnderlyingLiability,AvgHomesNumber,AvgVehicleNumber,AvgWatercraftNumber,YouthfulDriverNumber,MVRTriggerRule
				,CommissionPercentage,MinimumPremium,PriorNFPPolicyNumber,NFPExpiring
			)
		) pivottable

		select 
			Id,
			DOLiabilityLimit_1MLimitPremium as non_profit_do_liability_limit_1m_premium_amt,
			DOLiabilityLimit_1MLimitPremiumOverride as non_profit_do_liability_limit_1m_override_premium_amt,
			DOLiabilityLimit_2MLimitPremium as non_profit_do_liability_limit_2m_premium_amt,
			DOLiabilityLimit_2MLimitPremiumOverride as non_profit_do_liability_limit_2m_override_premium_amt,
			DOLiabilityLimit_3MLimitPremium as non_profit_do_liability_limit_3m_premium_amt,
			DOLiabilityLimit_3MLimitPremiumOverride as non_profit_do_liability_limit_3m_override_premium_amt,
			DOLiabilityLimit_4MLimitPremium as non_profit_do_liability_limit_4m_premium_amt,
			DOLiabilityLimit_4MLimitPremiumOverride as non_profit_do_liability_limit_4m_override_premium_amt,
			DOLiabilityLimit_5MLimitPremium as non_profit_do_liability_limit_5m_premium_amt,
			DOLiabilityLimit_5MLimitPremiumOverride as non_profit_do_liability_limit_5m_override_premium_amt,
			ExcessLiabilityLimit_1MLimitPremium as excess_liability_limit_1m_premium_amt ,
			ExcessLiabilityLimit_1MLimitPremiumOverride as excess_liability_limit_1m_override_premium_amt,
			ExcessLiabilityLimit_3MLimitPremium as excess_liability_limit_3m_premium_amt,
			ExcessLiabilityLimit_3MLimitPremiumOverride as excess_liability_limit_3m_override_premium_amt,
			ExcessLiabilityLimit_5MLimitPremium as excess_liability_limit_5m_premium_amt,
			ExcessLiabilityLimit_5MLimitPremiumOverride as excess_liability_limit_5m_override_premium_amt,
			ExcessLiabilityLimit_10MLimitPremium as excess_liability_limit_10m_premium_amt,
			ExcessLiabilityLimit_10MLimitPremiumOverride as excess_liability_limit_10m_override_premium_amt,
			ExcessLiabilityLimit_15MLimitPremium as excess_liability_limit_15m_premium_amt,
			ExcessLiabilityLimit_15MLimitPremiumOverride as excess_liability_limit_15m_override_premium_amt,
			ExcessLiabilityLimit_20MLimitPremium as excess_liability_limit_20m_premium_amt,
			ExcessLiabilityLimit_20MLimitPremiumOverride as excess_liability_limit_20m_override_premium_amt,
			ExcessLiabilityLimit_30MLimitPremium as excess_liability_limit_30m_premium_amt,
			ExcessLiabilityLimit_30MLimitPremiumOverride as excess_liability_limit_30m_override_premium_amt,
			FTMLiabilityLimit_1MLimitPremium as family_trust_management_liability_limit_1m_premium_amt,
			FTMLiabilityLimit_1MLimitPremiumOverride as family_trust_management_liability_limit_1m_override_premium_amt,

			UMLiabilityLimit_1MLimitPremium as uninsured_underinsured_motorist_liability_limit_1m_premium_amt,
			UMLiabilityLimit_1MLimitPremiumOverride as uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt,
			UMLiabilityLimit_2MLimitPremium as uninsured_underinsured_motorist_liability_limit_2m_premium_amt,
			UMLiabilityLimit_2MLimitPremiumOverride as uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt,
			UMLiabilityLimit_3MLimitPremium as uninsured_underinsured_motorist_liability_limit_3m_premium_amt,
			UMLiabilityLimit_3MLimitPremiumOverride as uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt,
			UMLiabilityLimit_5MLimitPremium as uninsured_underinsured_motorist_liability_limit_5m_premium_amt,
			UMLiabilityLimit_5MLimitPremiumOverride as uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt,
			UMLiabilityLimit_10MLimitPremium as uninsured_underinsured_motorist_liability_limit_10m_premium_amt,
			UMLiabilityLimit_10MLimitPremiumOverride as uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt,
			EMPLiabilityLimit_25050025DeductiblePremium as employment_practices_liability_limit_250_250_25_premium_amt,
			EMPLiabilityLimit_25050025DeductiblePremiumOverride as employment_practices_liability_limit_250_250_25_override_premium_amt,
			EMPLiabilityLimit_50050050DeductiblePremium as employment_practices_liability_limit_500_500_50_premium_amt,
			EMPLiabilityLimit_50050050DeductiblePremiumOverride as employment_practices_liability_limit_500_500_50_override_premium_amt
		into edw_temp.tquote_grpel_master_coverage_wip_temp2
		from
		(
		select
		acc.Id,
		acco.ObjectType  + '_'+accof.Field as Field,
		accof.[Value]
		from
			edw_temp.tquote_grpel_master_coverage_wip_temp1 acc
			inner join edw_stage.AccountObject acco on acc.Id=acco.AccountId 
				and acco.ObjectType in ('DOLiabilityLimit','ExcessLiabilityLimit','EMPLiabilityLimit','FTMLiabilityLimit','UMLiabilityLimit')
			inner join edw_stage.AccountObjectField accof on acco.Id=accof.ObjectId  
		
		) as a
			PIVOT 
		(
		MAX(Value) FOR Field IN 
		(
			DOLiabilityLimit_1MLimitPremium,DOLiabilityLimit_1MLimitPremiumOverride,DOLiabilityLimit_2MLimitPremium,
			DOLiabilityLimit_2MLimitPremiumOverride,DOLiabilityLimit_3MLimitPremium,DOLiabilityLimit_3MLimitPremiumOverride,
			DOLiabilityLimit_4MLimitPremium,DOLiabilityLimit_4MLimitPremiumOverride,DOLiabilityLimit_5MLimitPremium,
			DOLiabilityLimit_5MLimitPremiumOverride,
			ExcessLiabilityLimit_1MLimitPremium,ExcessLiabilityLimit_1MLimitPremiumOverride,ExcessLiabilityLimit_3MLimitPremium,
			ExcessLiabilityLimit_3MLimitPremiumOverride,ExcessLiabilityLimit_5MLimitPremium,ExcessLiabilityLimit_5MLimitPremiumOverride,
			ExcessLiabilityLimit_10MLimitPremium,ExcessLiabilityLimit_10MLimitPremiumOverride,ExcessLiabilityLimit_15MLimitPremium,
			ExcessLiabilityLimit_15MLimitPremiumOverride,ExcessLiabilityLimit_20MLimitPremium,ExcessLiabilityLimit_20MLimitPremiumOverride,
			ExcessLiabilityLimit_30MLimitPremium,ExcessLiabilityLimit_30MLimitPremiumOverride,
			FTMLiabilityLimit_1MLimitPremium,FTMLiabilityLimit_1MLimitPremiumOverride,
			UMLiabilityLimit_1MLimitPremium,UMLiabilityLimit_1MLimitPremiumOverride,UMLiabilityLimit_2MLimitPremium,
			UMLiabilityLimit_2MLimitPremiumOverride,UMLiabilityLimit_3MLimitPremium,UMLiabilityLimit_3MLimitPremiumOverride,
			UMLiabilityLimit_5MLimitPremium,UMLiabilityLimit_5MLimitPremiumOverride,
			UMLiabilityLimit_10MLimitPremium,UMLiabilityLimit_10MLimitPremiumOverride,
			EMPLiabilityLimit_25050025DeductiblePremium,EMPLiabilityLimit_25050025DeductiblePremiumOverride,
			EMPLiabilityLimit_50050050DeductiblePremium,EMPLiabilityLimit_50050050DeductiblePremiumOverride
		)
		) pivottable

		MERGE INTO [edw_core].[tquote_grpel_master_coverage] AS Target
		USING
		(
			select
			a.PolicyNumber as grpel_master_quote_no,a.EffectiveDate as effective_dt, a.ExpirationDate as expiration_dt,
			a.transaction_seq_no,
			a.broker_id,a.customer_id,a.product_cd,a.risk_state_cd,a.insured_nm, a.insured_type,
			a.mailing_address_line1,a.mailing_address_line2,a.mailing_address_city_nm,a.mailing_address_state_cd,
			a.mailing_address_zip_cd,a.mailing_address_county_nm,a.mailing_address_country_nm,a.insured_first_nm,a.insured_last_nm,
			a.mobile_phone_no,a.email,			
			a.auto_liability_limit_amt,a.no_of_average_homes,a.no_of_average_vehicles,a.no_of_average_watercraft,a.no_of_youthful_driver,
			a.mvr_trigger_rule,
			a.commission_pc,a.minimum_premium_amt,a.prior_nfp_policy_no,a.prior_nfp_policy_expiring_dt,
			b.excess_liability_limit_1m_premium_amt,b.excess_liability_limit_1m_override_premium_amt,b.excess_liability_limit_3m_premium_amt,
			b.excess_liability_limit_3m_override_premium_amt,b.excess_liability_limit_5m_premium_amt,b.excess_liability_limit_5m_override_premium_amt,
			b.excess_liability_limit_10m_premium_amt,b.excess_liability_limit_10m_override_premium_amt,b.excess_liability_limit_15m_premium_amt,
			b.excess_liability_limit_15m_override_premium_amt,b.excess_liability_limit_20m_premium_amt,b.excess_liability_limit_20m_override_premium_amt,
			b.excess_liability_limit_30m_premium_amt,b.excess_liability_limit_30m_override_premium_amt,
			b.uninsured_underinsured_motorist_liability_limit_1m_premium_amt,b.uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt,
			b.uninsured_underinsured_motorist_liability_limit_2m_premium_amt,b.uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt,
			b.uninsured_underinsured_motorist_liability_limit_3m_premium_amt,b.uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt,
			b.uninsured_underinsured_motorist_liability_limit_5m_premium_amt,b.uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt,
			b.uninsured_underinsured_motorist_liability_limit_10m_premium_amt,b.uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt,
			b.employment_practices_liability_limit_250_250_25_premium_amt,b.employment_practices_liability_limit_250_250_25_override_premium_amt,
			b.employment_practices_liability_limit_500_500_50_premium_amt,b.employment_practices_liability_limit_500_500_50_override_premium_amt,
			b.family_trust_management_liability_limit_1m_premium_amt,b.family_trust_management_liability_limit_1m_override_premium_amt,
			b.non_profit_do_liability_limit_1m_premium_amt,b.non_profit_do_liability_limit_1m_override_premium_amt,
			b.non_profit_do_liability_limit_2m_premium_amt,b.non_profit_do_liability_limit_2m_override_premium_amt,
			b.non_profit_do_liability_limit_3m_premium_amt,b.non_profit_do_liability_limit_3m_override_premium_amt,
			b.non_profit_do_liability_limit_4m_premium_amt,b.non_profit_do_liability_limit_4m_override_premium_amt,
			b.non_profit_do_liability_limit_5m_premium_amt,b.non_profit_do_liability_limit_5m_override_premium_amt,
			a.source_system_sk,getdate() as create_ts,getdate()as update_ts,@etl_audit_sk as etl_audit_sk
		from
			edw_temp.tquote_grpel_master_coverage_wip_temp1 a
			left join edw_temp.tquote_grpel_master_coverage_wip_temp2 b on a.Id = b.Id
		where
			broker_id is not null
		) as [source]
		ON
		    target.grpel_master_quote_no = source.grpel_master_quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    target.transaction_seq_no = source.transaction_seq_no
		WHEN NOT MATCHED BY TARGET THEN
		INSERT
		(
		grpel_master_quote_no,effective_dt,expiration_dt,transaction_seq_no
		,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type
		,mailing_address_line1,mailing_address_line2,mailing_address_city_nm,mailing_address_state_cd
		,mailing_address_zip_cd,mailing_address_county_nm,mailing_address_country_nm,insured_first_nm,insured_last_nm
		,mobile_phone_no,email	
		,auto_liability_limit_amt,no_of_average_homes,no_of_average_vehicles,no_of_average_watercraft,no_of_youthful_driver,mvr_trigger_rule
		,commission_pc,minimum_premium_amt,prior_nfp_policy_no,prior_nfp_policy_expiring_dt
		,excess_liability_limit_1m_premium_amt,excess_liability_limit_1m_override_premium_amt,excess_liability_limit_3m_premium_amt
		,excess_liability_limit_3m_override_premium_amt,excess_liability_limit_5m_premium_amt,excess_liability_limit_5m_override_premium_amt
		,excess_liability_limit_10m_premium_amt,excess_liability_limit_10m_override_premium_amt,excess_liability_limit_15m_premium_amt
		,excess_liability_limit_15m_override_premium_amt,excess_liability_limit_20m_premium_amt,excess_liability_limit_20m_override_premium_amt
		,excess_liability_limit_30m_premium_amt,excess_liability_limit_30m_override_premium_amt
		,uninsured_underinsured_motorist_liability_limit_1m_premium_amt,uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt
		,uninsured_underinsured_motorist_liability_limit_2m_premium_amt,uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt
		,uninsured_underinsured_motorist_liability_limit_3m_premium_amt,uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt
		,uninsured_underinsured_motorist_liability_limit_5m_premium_amt,uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt
		,uninsured_underinsured_motorist_liability_limit_10m_premium_amt,uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt
		,employment_practices_liability_limit_250_250_25_premium_amt,employment_practices_liability_limit_250_250_25_override_premium_amt
		,employment_practices_liability_limit_500_500_50_premium_amt,employment_practices_liability_limit_500_500_50_override_premium_amt
		,family_trust_management_liability_limit_1m_premium_amt,family_trust_management_liability_limit_1m_override_premium_amt
		,non_profit_do_liability_limit_1m_premium_amt,non_profit_do_liability_limit_1m_override_premium_amt
		,non_profit_do_liability_limit_2m_premium_amt,non_profit_do_liability_limit_2m_override_premium_amt
		,non_profit_do_liability_limit_3m_premium_amt,non_profit_do_liability_limit_3m_override_premium_amt
		,non_profit_do_liability_limit_4m_premium_amt,non_profit_do_liability_limit_4m_override_premium_amt
		,non_profit_do_liability_limit_5m_premium_amt,non_profit_do_liability_limit_5m_override_premium_amt
		,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		VALUES 
		(
		[source].grpel_master_quote_no,[source].effective_dt,[source].expiration_dt,[source].transaction_seq_no
		,[source].broker_id,[source].customer_id,[source].product_cd,[source].risk_state_cd,[source].insured_nm,[source].insured_type
		,[source].mailing_address_line1,[source].mailing_address_line2,[source].mailing_address_city_nm,[source].mailing_address_state_cd
		,[source].mailing_address_zip_cd,[source].mailing_address_county_nm,[source].mailing_address_country_nm,[source].insured_first_nm,[source].insured_last_nm
		,[source].mobile_phone_no,[source].email		
		,[source].auto_liability_limit_amt,[source].no_of_average_homes,[source].no_of_average_vehicles,[source].no_of_average_watercraft,[source].no_of_youthful_driver,[source].mvr_trigger_rule
		,[source].commission_pc,[source].minimum_premium_amt,[source].prior_nfp_policy_no,[source].prior_nfp_policy_expiring_dt
		,[source].excess_liability_limit_1m_premium_amt,[source].excess_liability_limit_1m_override_premium_amt,[source].excess_liability_limit_3m_premium_amt
		,[source].excess_liability_limit_3m_override_premium_amt,[source].excess_liability_limit_5m_premium_amt,[source].excess_liability_limit_5m_override_premium_amt
		,[source].excess_liability_limit_10m_premium_amt,[source].excess_liability_limit_10m_override_premium_amt,[source].excess_liability_limit_15m_premium_amt
		,[source].excess_liability_limit_15m_override_premium_amt,[source].excess_liability_limit_20m_premium_amt,[source].excess_liability_limit_20m_override_premium_amt
		,[source].excess_liability_limit_30m_premium_amt,[source].excess_liability_limit_30m_override_premium_amt
		,[source].uninsured_underinsured_motorist_liability_limit_1m_premium_amt,[source].uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt
		,[source].uninsured_underinsured_motorist_liability_limit_2m_premium_amt,[source].uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt
		,[source].uninsured_underinsured_motorist_liability_limit_3m_premium_amt,[source].uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt
		,[source].uninsured_underinsured_motorist_liability_limit_5m_premium_amt,[source].uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt
		,[source].uninsured_underinsured_motorist_liability_limit_10m_premium_amt,[source].uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt
		,[source].employment_practices_liability_limit_250_250_25_premium_amt,[source].employment_practices_liability_limit_250_250_25_override_premium_amt
		,[source].employment_practices_liability_limit_500_500_50_premium_amt,[source].employment_practices_liability_limit_500_500_50_override_premium_amt
		,[source].family_trust_management_liability_limit_1m_premium_amt,[source].family_trust_management_liability_limit_1m_override_premium_amt
		,[source].non_profit_do_liability_limit_1m_premium_amt,[source].non_profit_do_liability_limit_1m_override_premium_amt
		,[source].non_profit_do_liability_limit_2m_premium_amt,[source].non_profit_do_liability_limit_2m_override_premium_amt
		,[source].non_profit_do_liability_limit_3m_premium_amt,[source].non_profit_do_liability_limit_3m_override_premium_amt
		,[source].non_profit_do_liability_limit_4m_premium_amt,[source].non_profit_do_liability_limit_4m_override_premium_amt
		,[source].non_profit_do_liability_limit_5m_premium_amt,[source].non_profit_do_liability_limit_5m_override_premium_amt
		,[source].source_system_sk,[source].create_ts,[source].update_ts,[source].etl_audit_sk
		)
		WHEN MATCHED THEN
		    UPDATE 
            SET
				[target]. effective_dt = source.effective_dt
				,[target].broker_id = [source].broker_id
				,[target].customer_id = [source].customer_id
				,[target].product_cd = [source].product_cd
				,[target].risk_state_cd= [source].risk_state_cd
				,[target].insured_nm= [source].insured_nm
				,[target].insured_type = [source].insured_type
				,[target].mailing_address_line1= [source].mailing_address_line1
				,[target].mailing_address_line2 = [source].mailing_address_line2
				,[target].mailing_address_city_nm= [source].mailing_address_city_nm
				,[target].mailing_address_state_cd = [source].mailing_address_state_cd
				,[target].mailing_address_zip_cd =[source].mailing_address_zip_cd
				,[target].mailing_address_county_nm = [source].mailing_address_county_nm
				,[target].mailing_address_country_nm = [source].mailing_address_country_nm
				,[target].insured_first_nm= [source].insured_first_nm
				,[target].insured_last_nm= [source].insured_last_nm
				,[target].mobile_phone_no= [source].mobile_phone_no
				,[target].email= [source].email				
				,[target].auto_liability_limit_amt=[source].auto_liability_limit_amt
				,[target].no_of_average_homes=[source].no_of_average_homes
				,[target].no_of_average_vehicles=[source].no_of_average_vehicles
				,[target].no_of_average_watercraft= [source].no_of_average_watercraft
				,[target].no_of_youthful_driver= [source].no_of_youthful_driver
				,[target].mvr_trigger_rule=[source].mvr_trigger_rule
				,[target].commission_pc=[source].commission_pc
				,[target].minimum_premium_amt=[source].minimum_premium_amt
				,[target].prior_nfp_policy_no=[source].prior_nfp_policy_no
				,[target].prior_nfp_policy_expiring_dt=[source].prior_nfp_policy_expiring_dt
				,[target].excess_liability_limit_1m_premium_amt=[source].excess_liability_limit_1m_premium_amt
				,[target].excess_liability_limit_1m_override_premium_amt= [source].excess_liability_limit_1m_override_premium_amt
				,[target].excess_liability_limit_3m_premium_amt= [source].excess_liability_limit_3m_premium_amt
				,[target].excess_liability_limit_3m_override_premium_amt=[source].excess_liability_limit_3m_override_premium_amt
				,[target].excess_liability_limit_5m_premium_amt = [source].excess_liability_limit_5m_premium_amt
				,[target].excess_liability_limit_5m_override_premium_amt =[source].excess_liability_limit_5m_override_premium_amt
				,[target].excess_liability_limit_10m_premium_amt=[source].excess_liability_limit_10m_premium_amt
				,[target].excess_liability_limit_10m_override_premium_amt= [source].excess_liability_limit_10m_override_premium_amt
				,[target].excess_liability_limit_15m_premium_amt = [source].excess_liability_limit_15m_premium_amt
				,[target].excess_liability_limit_15m_override_premium_amt = [source].excess_liability_limit_15m_override_premium_amt
				,[target].excess_liability_limit_20m_premium_amt = [source].excess_liability_limit_20m_premium_amt
				,[target].excess_liability_limit_20m_override_premium_amt= [source].excess_liability_limit_20m_override_premium_amt
				,[target].excess_liability_limit_30m_premium_amt = [source].excess_liability_limit_30m_premium_amt
				,[target].excess_liability_limit_30m_override_premium_amt = [source].excess_liability_limit_30m_override_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_1m_premium_amt = [source].uninsured_underinsured_motorist_liability_limit_1m_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt= [source].uninsured_underinsured_motorist_liability_limit_1m_override_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_2m_premium_amt = [source].uninsured_underinsured_motorist_liability_limit_2m_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt = [source].uninsured_underinsured_motorist_liability_limit_2m_override_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_3m_premium_amt = [source].uninsured_underinsured_motorist_liability_limit_3m_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt =[source].uninsured_underinsured_motorist_liability_limit_3m_override_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_5m_premium_amt= [source].uninsured_underinsured_motorist_liability_limit_5m_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt=[source].uninsured_underinsured_motorist_liability_limit_5m_override_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_10m_premium_amt = [source].uninsured_underinsured_motorist_liability_limit_10m_premium_amt
				,[target].uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt= [source].uninsured_underinsured_motorist_liability_limit_10m_override_premium_amt
				,[target].employment_practices_liability_limit_250_250_25_premium_amt=[source].employment_practices_liability_limit_250_250_25_premium_amt
				,[target].employment_practices_liability_limit_250_250_25_override_premium_amt=[source].employment_practices_liability_limit_250_250_25_override_premium_amt
				,[target].employment_practices_liability_limit_500_500_50_premium_amt=[source].employment_practices_liability_limit_500_500_50_premium_amt
				,[target].employment_practices_liability_limit_500_500_50_override_premium_amt=[source].employment_practices_liability_limit_500_500_50_override_premium_amt
				,[target].family_trust_management_liability_limit_1m_premium_amt= [source].family_trust_management_liability_limit_1m_premium_amt
				,[target].family_trust_management_liability_limit_1m_override_premium_amt =[source].family_trust_management_liability_limit_1m_override_premium_amt
				,[target].non_profit_do_liability_limit_1m_premium_amt= [source].non_profit_do_liability_limit_1m_premium_amt
				,[target].non_profit_do_liability_limit_1m_override_premium_amt = [source].non_profit_do_liability_limit_1m_override_premium_amt
				,[target].non_profit_do_liability_limit_2m_premium_amt = [source].non_profit_do_liability_limit_2m_premium_amt
				,[target].non_profit_do_liability_limit_2m_override_premium_amt = [source].non_profit_do_liability_limit_2m_override_premium_amt
				,[target].non_profit_do_liability_limit_3m_premium_amt = [source].non_profit_do_liability_limit_3m_premium_amt
				,[target].non_profit_do_liability_limit_3m_override_premium_amt =[source].non_profit_do_liability_limit_3m_override_premium_amt
				,[target].non_profit_do_liability_limit_4m_premium_amt =[source].non_profit_do_liability_limit_4m_premium_amt
				,[target].non_profit_do_liability_limit_4m_override_premium_amt= [source].non_profit_do_liability_limit_4m_override_premium_amt
				,[target].non_profit_do_liability_limit_5m_premium_amt = [source].non_profit_do_liability_limit_5m_premium_amt
				,[target].non_profit_do_liability_limit_5m_override_premium_amt=[source].non_profit_do_liability_limit_5m_override_premium_amt
				,[target].update_ts = getdate()
		;

		SET @rows_affected=@@ROWCOUNT;
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t2.CreatedDate) FROM edw_temp.tquote_grpel_master_coverage_wip_temp1 t2),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_master_coverage_wip_temp2;
		
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