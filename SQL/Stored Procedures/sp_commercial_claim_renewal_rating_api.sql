-- =================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 04/16/2026
-- Description: This procedures inserts and updates data for commercial claim renewal rating
---------------------------------------------------------------------------------------------------
-- Change date	    |Author					| Change Description
---------------------------------------------------------------------------------------------------
-- 04/16/2026		Yunus Mohammed			1. Created this procedure
-- 05/11/2026		Yunus Mohammed			2. AD-13339 Added throw statement in catch block
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_commercial_claim_renewal_rating_api]

AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;

		DROP TABLE IF EXISTS edw_temp.commercial_claim_renewal_rating_api_temp1

        SELECT *
		INTO edw_temp.commercial_claim_renewal_rating_api_temp1
        FROM
        (
        SELECT ROW_NUMBER()over(partition by cl.claim_no order by (
        cfa.loss_paid_amt + cfa.subrogation_recovery_amt + cfa.salvage_recovery_amt + cfa.overpayment_recovery_amt
        ) DESC) as rn,
		cl.loss_dt AS [DateOfLoss],
        cl.policy_no AS [PolicyNumber],
		cl.litigation_in as [Litigation],
		cl.litigation_complete_in as LitigationComplete,
		cl.claim_no AS [ClaimNumber],
		cl.claim_status AS [ClaimStatus],
		cfa.claimant_nm as [Claimant],
		cl.claim_last_updated_ts as [LastUpdate],
		l.cause_of_loss_desc as [CauseOfLoss],
		cl.loss_desc as [FactOfLoss],
		cl.loss_location_desc as [AdditionalFactOfLoss],
        cl.large_loss_in as LargeLoss,
		cl.loss_reserve_amt AS [CurrentIndemnityReserve],
        (cl.loss_paid_amt + cl.subrogation_recovery_amt + cl.salvage_recovery_amt + cl.overpayment_recovery_amt) as TotalIndemnityPayment,
		cl.expense_reserve_amt  as CurrentExpenseReserve,
		(cl.expense_paid_amt + cl.subrogation_expense_recovery_amt + cl.salvage_expense_recovery_amt + cl.overpayment_expense_recovery_amt) as TotalExpensePayment ,
		cl.defense_reserve_amt AS CurrentLegalDefenseReserve,
		(cl.defense_paid_amt + cl.subrogation_defense_recovery_amt + cl.salvage_defense_recovery_amt + cl.overpayment_defense_recovery_amt) TotalLegalDefensePayment,
		(cl.loss_paid_amt + cl.subrogation_recovery_amt + cl.salvage_recovery_amt + cl.overpayment_recovery_amt + 
			cl.expense_paid_amt + cl.subrogation_expense_recovery_amt + cl.salvage_expense_recovery_amt + cl.overpayment_expense_recovery_amt + 
			cl.defense_paid_amt + cl.subrogation_defense_recovery_amt + cl.salvage_defense_recovery_amt + cl.overpayment_defense_recovery_amt) 
		 as TotalIncurredPayment,
		cfa.claim_adjuster_nm as AdjusterName       
        FROM
        edw_commercial.tcommercial_claim cl
        inner join edw_core.tproduct tp on tp.product_sk=cl.product_sk
        LEFT JOIN edw_core.tcause_of_loss l on cl.cause_of_loss_sk = l.cause_of_loss_sk 
        Left join edw_core.tpolicy p on p.policy_no = cl.policy_no 
        INNER JOIN
        (
        SELECT 
        row_number() over(partition by commercial_claim_sk order by 
        sum(
            clf.loss_paid_amt + clf.subrogation_recovery_amt + clf.salvage_recovery_amt + clf.overpayment_recovery_amt
            ) desc
            ) as row_no, 
        commercial_claim_sk,claim_coverage_cd
        FROM
        edw_commercial.tcommercial_claim_feature clf
        group by commercial_claim_sk,claim_coverage_cd

    ) cf on cf.commercial_claim_sk= cl.commercial_claim_sk and cf.row_no = 1
    LEFT JOIN edw_commercial.tcommercial_claim_feature cfa on cfa.commercial_claim_sk = cf.commercial_claim_sk and cfa.claim_coverage_cd = cf.claim_coverage_cd
    ) as a
    where
    rn = 1
 
		

	MERGE edw_integration.commercial_claim_renewal_rating_api AS [Target]
	USING edw_temp.commercial_claim_renewal_rating_api_temp1 AS [Source]
	ON [Source].[ClaimNumber] = [Target].[ClaimNumber]
	-- For Inserts
	WHEN NOT MATCHED BY Target THEN
	INSERT
		(
            DateOfLoss, PolicyNumber, Litigation, LitigationComplete, ClaimNumber, ClaimStatus,
            Claimant, LastUpdate, CauseOfLoss, FactOfLoss, AdditionalFactOfLoss, LargeLoss,
            CurrentIndemnityReserve, TotalIndemnityPayment, CurrentExpenseReserve, TotalExpensePayment,
            CurrentLegalDefenseReserve, TotalLegalDefensePayment, TotalIncurredPayment, AdjusterName,
            create_ts, update_ts, etl_audit_sk
		)
	VALUES
		(
            DateOfLoss, PolicyNumber, Litigation, LitigationComplete, ClaimNumber, ClaimStatus,
            Claimant, LastUpdate, CauseOfLoss, FactOfLoss, AdditionalFactOfLoss, LargeLoss,
            CurrentIndemnityReserve, TotalIndemnityPayment, CurrentExpenseReserve, TotalExpensePayment,
            CurrentLegalDefenseReserve, TotalLegalDefensePayment, TotalIncurredPayment, AdjusterName,        
			GETDATE(),GETDATE(),@etl_audit_sk
		)
	-- For Updates
	WHEN MATCHED THEN UPDATE 
	SET
        [Target].DateOfLoss = [Source].DateOfLoss,
        [Target].PolicyNumber= [Source].PolicyNumber,
        [Target].Litigation = [Source].Litigation,
        [Target].LitigationComplete = [Source].LitigationComplete,        
        [Target].ClaimStatus = [Source].ClaimStatus,
        [Target].Claimant = [Source].Claimant,
        [Target].LastUpdate = [Source].LastUpdate,
        [Target].CauseOfLoss =  [Source].CauseOfLoss,
        [Target].FactOfLoss = [Source].FactOfLoss,
        [Target].AdditionalFactOfLoss = [Source].AdditionalFactOfLoss,
        [Target].LargeLoss = [Source].LargeLoss,
        [Target].CurrentIndemnityReserve = [Source].CurrentIndemnityReserve,
        [Target].TotalIndemnityPayment = [Source].TotalIndemnityPayment,
        [Target].CurrentExpenseReserve = [Source].CurrentExpenseReserve,
        [Target].TotalExpensePayment = [Source].TotalExpensePayment,
        [Target].CurrentLegalDefenseReserve = [Source].CurrentLegalDefenseReserve,
        [Target].TotalLegalDefensePayment = [Source].TotalLegalDefensePayment,
        [Target].TotalIncurredPayment = [Source].TotalIncurredPayment,
        [Target].AdjusterName = [Source].AdjusterName,
        [Target].update_ts = GETDATE();

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.commercial_claim_renewal_rating_api_temp1;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
        THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END