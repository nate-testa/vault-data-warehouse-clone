-- ==========================================================================================================
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures insert quote grpel coverage data
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 02/12/26		Dinesh Bobbili				1. Created this SP
-- 03/18/26     Yunus Mohammed              2. AD-12841 Corrected insert stmt
--                                          The positions of no_of_vehicles and reputational_injury_coverage_limit_amt are swapped
-- 04/04/26     Yunus Mohammed              2. AD-13016 -  Remove no_of_high_performance_vehicles, no_of_boats_yachts and
--                                                         reputational_injury_coverage_limit_amt columns
-- ==========================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_coverage]
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
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_coverage_temp1;
        select 
                PolicyNumber,EffectiveDate,ExpirationDate,grpel_quote_no,group_nm,quote_history_sk,source_system_sk,CreatedDate,
                transaction_seq_no,ExcessLiabilityLimit ,UMLiabilityLimit ,EMPLiabilityLimit ,DOLiabilityLimit ,FTMLiabilityLimit,
                        NumberOfVehicles ,UILiabilityLimit ,NumberOfPrivateStaff ,
                        NumberOfRecreationalVehicles ,
                        NumberOfPersonalWatercraft ,AutoInsuranceCompany ,HomeInsuranceCompany ,WatercraftInsuranceCompany
            INTO edw_temp.tquote_grpel_coverage_temp1
            from
                (
                select * 
                from
                    (
                    
                    select
                    act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
					accg.PolicyNumber as grpel_quote_no,
                    case 
                        when nullif(isnull(insg.FirstName + ' ','') + isnull(insg.LastName,''),'') is not null
                        then nullif(isnull(insg.FirstName + ' ','')	+ isnull(insg.LastName,''),'') 
                        when insg.NamedInsured is not null then insg.NamedInsured
                        else insg.NamedInsured 
                        end
                    as group_nm,
                    tqh.quote_history_sk,
                    act.[Number] AS transaction_seq_no, 
                    CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
                    act.CreatedDate,
                    atvof.Field,NULLIF(TRIM(atvof.[Value]),'') AS [Value]
                    from
                        edw_stage.Account acc
                        inner join [edw_stage].[AccountTransaction] as act on acc.Id= act.AccountId
						left join edw_stage.Account accg on acc.GroupAccountId = accg.Id
						left join edw_stage.Insured insg on insg.Id= accg.PrimaryInsuredId
                        inner join edw_stage.Product p on p.Id=act.ProductId
                        inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
                        inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
                        inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
                        left join [edw_core].[tquote_history] tqh on tqh.quote_no=act.PolicyNumber
						and tqh.effective_dt=act.EffectiveDate
						and tqh.transaction_seq_no = act.[Number]
                        left join edw_stage.Product pr on act.ProductId = pr.id
                    where act.[Stage] IN ('QUOTE','POLICY')
                        AND act.PolicyNumber IS NOT NULL
                        AND act.CreatedDate > @last_source_extract_ts
                        AND p.[Name]='Participant Personal Excess Liability'
                        and atvo.ObjectType in ('Insured','ParticipantPersonalExcessLiability')
                        and pr.ProductLine = 'PersonalLines'
                        and atvof.Field IN 
                        (
                            'ExcessLiabilityLimit', 'UMLiabilityLimit', 'EMPLiabilityLimit', 'DOLiabilityLimit', 'FTMLiabilityLimit',
                            'NumberOfVehicles', 'UILiabilityLimit', 'NumberOfPrivateStaff', 
                            'NumberOfRecreationalVehicles',
                            'NumberOfPersonalWatercraft', 'AutoInsuranceCompany', 'HomeInsuranceCompany', 'WatercraftInsuranceCompany'
                        )
                    ) as t
                ) as t
                pivot 
                (
                    max(Value) FOR Field IN 
                    (
                        ExcessLiabilityLimit ,UMLiabilityLimit ,EMPLiabilityLimit ,DOLiabilityLimit ,FTMLiabilityLimit ,
                        NumberOfVehicles ,UILiabilityLimit ,NumberOfPrivateStaff ,
                        NumberOfRecreationalVehicles ,
                        NumberOfPersonalWatercraft ,AutoInsuranceCompany ,HomeInsuranceCompany ,WatercraftInsuranceCompany
                        )
                ) as pivottable
            ;
        
        INSERT INTO [edw_core].[tquote_grpel_coverage]
		(
            quote_no,grpel_quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,group_nm,excess_liability_limit_amt
            ,uninsured_motorist_liability_limit_amt,employment_practises_liability_limit_amt,non_profit_do_liability_limit_amt
            ,family_trust_management_liability_limit_amt,uninsured_underinsured_liability_limit_amt
            ,no_of_vehicles,no_of_private_staff
            ,no_of_recreational_vehicles,no_of_personal_watercraft,underlying_auto_insurance_company_nm
            ,underlying_home_insurance_company_nm,underlying_watercraft_insurance_company_nm
            ,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
        select
            PolicyNumber AS quote_no, grpel_quote_no,EffectiveDate AS effective_dt, ExpirationDate AS expiration_dt
            ,transaction_seq_no,quote_history_sk, group_nm as group_nm, ExcessLiabilityLimit as excess_liability_limit_amt
            ,UMLiabilityLimit as uninsured_motorist_liability_limit_amt, EMPLiabilityLimit as employment_practises_liability_limit_amt
            ,DOLiabilityLimit as non_profit_do_liability_limit_amt, FTMLiabilityLimit as family_trust_management_liability_limit_amt
            ,UILiabilityLimit as uninsured_underinsured_liability_limit_amt
            ,NumberOfVehicles as no_of_vehicles, NumberOfPrivateStaff as no_of_private_staff
            , NumberOfRecreationalVehicles as	no_of_recreational_vehicles
            , NumberOfPersonalWatercraft as no_of_personal_watercraft
            ,AutoInsuranceCompany as underlying_auto_insurance_company_nm, HomeInsuranceCompany as underlying_home_insurance_company_nm
            ,WatercraftInsuranceCompany	as underlying_watercraft_insurance_company_nm
            ,source_system_sk ,getdate() AS create_ts, getdate() AS update_ts, @etl_audit_sk AS etl_audit_sk
        from edw_temp.tquote_grpel_coverage_temp1
		
		SET @rows_affected=@@ROWCOUNT;
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_grpel_coverage_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_coverage_temp1;
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