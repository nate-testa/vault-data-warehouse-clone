-- ==========================================================================================================
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures insert quote grpel coverage data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 02/12/26		Dinesh Bobbili				1. Created this SP
-- ==========================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_coverage_wip]
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
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_coverage_wip_temp1;
        select 
                PolicyNumber,grpel_quote_no,group_nm,
				EffectiveDate,ExpirationDate,quote_history_sk,source_system_sk,CreatedDate,UpdatedDate,
                transaction_seq_no,ExcessLiabilityLimit ,UMLiabilityLimit ,EMPLiabilityLimit ,DOLiabilityLimit ,FTMLiabilityLimit,
				NumberOfVehicles ,UILiabilityLimit ,ReputationalInjuryLimit ,NumberOfPrivateStaff ,
				NumberOfHighPerformansVehicles ,NumberOfRecreationalVehicles ,NumberOfWatercraft ,
				NumberOfPersonalWatercraft ,AutoInsuranceCompany ,HomeInsuranceCompany ,WatercraftInsuranceCompany
            INTO edw_temp.tquote_grpel_coverage_wip_temp1
            from
                (
                select * 
                from
                    (                    
                    select
                    acc.PolicyNumber,accg.PolicyNumber as grpel_quote_no,                    
                    case 
                        when nullif(isnull(insg.FirstName + ' ','') + isnull(insg.LastName,''),'') is not null
                        then nullif(isnull(insg.FirstName + ' ','')	+ isnull(insg.LastName,''),'') 
                        when insg.NamedInsured is not null then insg.NamedInsured
                        else insg.NamedInsured 
                    end as group_nm,
					CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
                    tqh.quote_history_sk,
                    0 AS transaction_seq_no, 
                    CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
                    acc.CreatedDate,acc.UpdatedDate,
                    accof.Field,NULLIF(TRIM(accof.[Value]),'') AS [Value]
                    from
                    (
                        SELECT *
                        FROM [edw_stage].[Account] AS a
                        WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                    ) acc
					left join edw_stage.Account accg on acc.GroupAccountId = accg.Id
					left join edw_stage.Insured insg on insg.Id= accg.PrimaryInsuredId
                    inner join edw_stage.Product p on p.Id=acc.ProductId
                    inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                    inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                    left join [edw_core].[tquote_history] tqh on tqh.quote_no=acc.PolicyNumber
                            and tqh.effective_dt=acc.EffectiveDate
                            and tqh.transaction_seq_no = 0
                    left join edw_stage.Product pr on acc.ProductId = pr.id
                    where acc.PolicyNumber is not null
                        AND p.[Name]='Participant Personal Excess Liability'
                        and acco.ObjectType in ('Insured','ParticipantPersonalExcessLiability')
                        and pr.ProductLine = 'PersonalLines'
                        and accof.Field IN 
                        (
                            'ExcessLiabilityLimit', 'UMLiabilityLimit', 'EMPLiabilityLimit', 'DOLiabilityLimit', 'FTMLiabilityLimit',
                            'NumberOfVehicles', 'UILiabilityLimit', 'ReputationalInjuryLimit', 'NumberOfPrivateStaff', 
                            'NumberOfHighPerformansVehicles', 'NumberOfRecreationalVehicles', 'NumberOfWatercraft', 
                            'NumberOfPersonalWatercraft', 'AutoInsuranceCompany', 'HomeInsuranceCompany', 'WatercraftInsuranceCompany'
                        )
						

                    ) as t
                ) as t
                pivot 
                (
                    max(Value) FOR Field IN 
                    (
                        ExcessLiabilityLimit ,UMLiabilityLimit ,EMPLiabilityLimit ,DOLiabilityLimit ,FTMLiabilityLimit ,
                        NumberOfVehicles ,UILiabilityLimit ,ReputationalInjuryLimit ,NumberOfPrivateStaff ,
                        NumberOfHighPerformansVehicles ,NumberOfRecreationalVehicles ,NumberOfWatercraft ,
                        NumberOfPersonalWatercraft ,AutoInsuranceCompany ,HomeInsuranceCompany ,WatercraftInsuranceCompany
                        )
                ) as pivottable
            ;
        
        MERGE INTO [edw_core].[tquote_grpel_coverage] AS target
        USING (
            SELECT
                PolicyNumber AS quote_no,
                grpel_quote_no,
				group_nm,
                EffectiveDate AS effective_dt,
                ExpirationDate AS expiration_dt,
                transaction_seq_no,
                quote_history_sk,                
                ExcessLiabilityLimit AS excess_liability_limit_amt,
                UMLiabilityLimit AS uninsured_motorist_liability_limit_amt,
                EMPLiabilityLimit AS employment_practises_liability_limit_amt,
                DOLiabilityLimit AS non_profit_do_liability_limit_amt,
                FTMLiabilityLimit AS family_trust_management_liability_limit_amt,
                UILiabilityLimit AS uninsured_underinsured_liability_limit_amt,
                ReputationalInjuryLimit AS reputational_injury_coverage_limit_amt,
                NumberOfVehicles AS no_of_vehicles,
                NumberOfPrivateStaff AS no_of_private_staff,
                NumberOfHighPerformansVehicles AS no_of_high_performance_vehicles,
                NumberOfRecreationalVehicles AS no_of_recreational_vehicles,
                NumberOfWatercraft AS no_of_boats_yachts,
                NumberOfPersonalWatercraft AS no_of_personal_watercraft,
                AutoInsuranceCompany AS underlying_auto_insurance_company_nm,
                HomeInsuranceCompany AS underlying_home_insurance_company_nm,
                WatercraftInsuranceCompany AS underlying_watercraft_insurance_company_nm,
                source_system_sk,
                GETDATE() AS create_ts,
                GETDATE() AS update_ts,
                @etl_audit_sk AS etl_audit_sk
            FROM edw_temp.tquote_grpel_coverage_wip_temp1	
		
        ) AS [source]
        ON
            target.quote_no = source.quote_no
            AND target.effective_dt = source.effective_dt
            AND target.transaction_seq_no = source.transaction_seq_no

        WHEN MATCHED THEN
            UPDATE SET
				target.grpel_quote_no = source.grpel_quote_no,
				target.group_nm= source.group_nm,
                target.effective_dt = source.effective_dt,
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,               
                target.excess_liability_limit_amt = source.excess_liability_limit_amt,
                target.uninsured_motorist_liability_limit_amt = source.uninsured_motorist_liability_limit_amt,
                target.employment_practises_liability_limit_amt = source.employment_practises_liability_limit_amt,
                target.non_profit_do_liability_limit_amt = source.non_profit_do_liability_limit_amt,
                target.family_trust_management_liability_limit_amt = source.family_trust_management_liability_limit_amt,
                target.uninsured_underinsured_liability_limit_amt = source.uninsured_underinsured_liability_limit_amt,
                target.reputational_injury_coverage_limit_amt = source.reputational_injury_coverage_limit_amt,
                target.no_of_vehicles = source.no_of_vehicles,
                target.no_of_private_staff = source.no_of_private_staff,
                target.no_of_high_performance_vehicles = source.no_of_high_performance_vehicles,
                target.no_of_recreational_vehicles = source.no_of_recreational_vehicles,
                target.no_of_boats_yachts = source.no_of_boats_yachts,
                target.no_of_personal_watercraft = source.no_of_personal_watercraft,
                target.underlying_auto_insurance_company_nm = source.underlying_auto_insurance_company_nm,
                target.underlying_home_insurance_company_nm = source.underlying_home_insurance_company_nm,
                target.underlying_watercraft_insurance_company_nm = source.underlying_watercraft_insurance_company_nm,
                target.source_system_sk = source.source_system_sk,
                target.update_ts = source.update_ts,
                target.etl_audit_sk = source.etl_audit_sk

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                quote_no,
				grpel_quote_no,
				group_nm,
                effective_dt,
                expiration_dt,
                transaction_seq_no,
                quote_history_sk,
                excess_liability_limit_amt,
                uninsured_motorist_liability_limit_amt,
                employment_practises_liability_limit_amt,
                non_profit_do_liability_limit_amt,
                family_trust_management_liability_limit_amt,
                uninsured_underinsured_liability_limit_amt,
                reputational_injury_coverage_limit_amt,
                no_of_vehicles,
                no_of_private_staff,
                no_of_high_performance_vehicles,
                no_of_recreational_vehicles,
                no_of_boats_yachts,
                no_of_personal_watercraft,
                underlying_auto_insurance_company_nm,
                underlying_home_insurance_company_nm,
                underlying_watercraft_insurance_company_nm,
                source_system_sk,
                create_ts,
                update_ts,
                etl_audit_sk
            )
            VALUES (
                source.quote_no,
				source.grpel_quote_no,
				source.group_nm,
                source.effective_dt,
                source.expiration_dt,
                source.transaction_seq_no,
                source.quote_history_sk,
                source.excess_liability_limit_amt,
                source.uninsured_motorist_liability_limit_amt,
                source.employment_practises_liability_limit_amt,
                source.non_profit_do_liability_limit_amt,
                source.family_trust_management_liability_limit_amt,
                source.uninsured_underinsured_liability_limit_amt,
                source.reputational_injury_coverage_limit_amt,
                source.no_of_vehicles,
                source.no_of_private_staff,
                source.no_of_high_performance_vehicles,
                source.no_of_recreational_vehicles,
                source.no_of_boats_yachts,
                source.no_of_personal_watercraft,
                source.underlying_auto_insurance_company_nm,
                source.underlying_home_insurance_company_nm,
                source.underlying_watercraft_insurance_company_nm,
                source.source_system_sk,
                source.create_ts,
                source.update_ts,
                source.etl_audit_sk
            );

		SET @rows_affected=@@ROWCOUNT;
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_grpel_coverage_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_coverage_wip_temp1;
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