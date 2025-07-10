-- =================================================================================================
-- Description: This procedures provides total_loss_incurred differences between snapsheet and edw
---------------------------------------------------------------------------------------------------
-- Change date			|Author						               |	Change Description
---------------------------------------------------------------------------------------------------
-- 03/19/25				Yunus Mohammed				1. Created this procedure 
-- 06/13/25             Sandeep Gundreddy           2. updated EDW query logic to -ve expense subro and salvage recovery amounts
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_reconciliation_claim_snapsheet]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY		
		DECLARE @etl_audit_sk INT		
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		
        EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;		
		drop table if exists edw_temp.sp_reconciliation_claim_snapsheet_temp1
        drop table if exists edw_temp.sp_reconciliation_claim_snapsheet_temp2
        drop table if exists edw_temp.snapsheet_edw_claim_loss_reconciliation

        declare @max_transaction_ts datetime2(6)

        select @max_transaction_ts = max(transaction_ts) from edw_core.tclaim_transaction

        select
        res.claim_number,res.claim_id,res.exposure_id,res.cost_type,
        --res.reserve_method,
        res.financial_transaction_type ,
        --res.remote_identifier,
        res.exposure_type,
        res.cost_category,
        res.reserve_amt,pay.payment_amt,-1*res.recovery_reserve_amt as recovery_reserve_amt,-1 * pay.recovery_amt as recovery_amt, 
        (res.reserve_amt+isnull(pay.payment_amt,0)+(-1*res.recovery_reserve_amt)+(-1 * isnull(pay.recovery_amt,0))) as total_loss_incurred
        into edw_temp.sp_reconciliation_claim_snapsheet_temp1
        from
        (  select * from 
            (
                select rank() over(partition by fri.claim_id,fri.exposure_id,fri.cost_type,fri.cost_category,ft.financial_transaction_type 
                    order by fri.created_at desc,ft.id desc) as row_no,
                c.claim_number,
                fri.claim_id,fri.exposure_id,fri.cost_type,fri.reserve_method,ft.financial_transaction_type ,
                ft.remote_identifier,exps.exposure_type,fri.cost_category,
                case when ft.financial_transaction_type='indemnity' then fri.amount else 0 end as reserve_amt,
                case when ft.financial_transaction_type='recovery' then fri.amount else 0 end as recovery_reserve_amt
                from
                edw_stage_snapsheet.claims c
                inner join edw_stage_snapsheet.exposures exps on c.id= exps.claim_id
                inner join edw_stage_snapsheet.financial_reserve_items fri on fri.exposure_id = exps.id
                inner join edw_stage_snapsheet.financial_transactions ft on ft.id = fri.financial_transaction_id 
                where ft.approved_at is not null and ft.created_at< = @max_transaction_ts
            )reserves where row_no = 1
        ) as res
        left join 
        (
            select fpi.claim_id,fpi.exposure_id,fpi.cost_type ,ft.financial_transaction_type ,fpi.cost_category
                ,sum( case when ft.financial_transaction_type='indemnity' and ft.stage in ('submitted','cleared','issued') then amount else 0 end) as payment_amt
                ,sum( case when ft.financial_transaction_type='recovery' and ft.stage in ('submitted','cleared','issued') then amount else 0 end) as recovery_amt
            from
                edw_stage_snapsheet.claims c
                inner join edw_stage_snapsheet.exposures exps on c.id= exps.claim_id
                inner join edw_stage_snapsheet.financial_transactions ft on ft.claim_id = c.id
                inner join edw_stage_snapsheet.financial_payment_items fpi on fpi.exposure_id = exps.id and fpi.financial_transaction_id = ft.id
            where ft.created_at<= @max_transaction_ts
            group by fpi.claim_id,fpi.exposure_id,fpi.cost_type,ft.financial_transaction_type,fpi.cost_category
        ) as pay on res.claim_id = pay.claim_id and res.exposure_id = pay.exposure_id and res.cost_type=pay.cost_type and res.financial_transaction_type=pay.financial_transaction_type
        and res.cost_category=pay.cost_category
        order by claim_number,exposure_id,financial_transaction_type

        ---######## EDW Financial Query at EXPOSURE/CLAIM FEATURE LEVEL 
        select c.claim_feature_sk,b.claim_no,c.claim_coverage_cd,
        SUM(
                        ct.loss_reserve_amt+ct.expense_reserve_amt+ct.defense_reserve_amt
        ) AS reserve_amt,
        SUM(
                        ct.subrogation_recovery_reserve_amt+ct.salvage_recovery_reserve_amt+
                        (case when ct.source_system_sk=3 then -1*ct.salvage_recovery_expense_reserve_amt else ct.salvage_recovery_expense_reserve_amt end)+
                        (case when ct.source_system_sk=3 then -1*ct.subrogation_recovery_expense_reserve_amt else ct.subrogation_recovery_expense_reserve_amt end)+
                        ct.deductible_recovery_reserve_amt+
                        ct.reinsurance_recovery_reserve_amt+ct.overpayment_recovery_reserve_amt+ct.deductible_recovery_expense_reserve_amt+
                        ct.reinsurance_recovery_expense_reserve_amt+ct.overpayment_recovery_expense_reserve_amt+
                        ct.subrogation_recovery_defense_reserve_amt+ct.salvage_recovery_defense_reserve_amt+
                        ct.deductible_recovery_defense_reserve_amt+ct.reinsurance_recovery_defense_reserve_amt+
                        ct.overpayment_recovery_defense_reserve_amt
        ) AS recovery_reserve_amt,
        SUM(
                        ct.loss_paid_amt+ct.expense_paid_amt+ct.defense_paid_amt
        ) AS paid_amt,
        SUM(
                        ct.subrogation_recovery_amt+ct.salvage_recovery_amt+(-1*ct.salvage_expense_recovery_amt)+
                        (-1*ct.subrogation_expense_recovery_amt)+ct.deductible_recovery_amt+
                        ct.reinsurance_recovery_amt+ct.overpayment_recovery_amt+ct.deductible_expense_recovery_amt+
                        ct.reinsurance_expense_recovery_amt+ct.overpayment_expense_recovery_amt+ct.subrogation_defense_recovery_amt+
                        ct.salvage_defense_recovery_amt+ct.deductible_defense_recovery_amt+
                        ct.reinsurance_defense_recovery_amt+ct.overpayment_defense_recovery_amt
        ) AS recovery_amt,
        SUM(       ct.loss_reserve_amt+ct.expense_reserve_amt+ct.defense_reserve_amt   +ct.subrogation_recovery_reserve_amt+ct.salvage_recovery_reserve_amt+
                        (case when ct.source_system_sk=3 then -1*ct.salvage_recovery_expense_reserve_amt else ct.salvage_recovery_expense_reserve_amt end)+
                        (case when ct.source_system_sk=3 then -1*ct.subrogation_recovery_expense_reserve_amt else ct.subrogation_recovery_expense_reserve_amt end)+
                        ct.deductible_recovery_reserve_amt+
                        ct.reinsurance_recovery_reserve_amt+ct.overpayment_recovery_reserve_amt+ct.deductible_recovery_expense_reserve_amt+
                        ct.reinsurance_recovery_expense_reserve_amt+ct.overpayment_recovery_expense_reserve_amt+
                        ct.subrogation_recovery_defense_reserve_amt+ct.salvage_recovery_defense_reserve_amt+
                        ct.deductible_recovery_defense_reserve_amt+ct.reinsurance_recovery_defense_reserve_amt+
                        ct.overpayment_recovery_defense_reserve_amt+ct.loss_paid_amt+ct.expense_paid_amt+ct.defense_paid_amt+
                        ct.subrogation_recovery_amt+ct.salvage_recovery_amt+
                        (-1*ct.salvage_expense_recovery_amt)+
                        (-1*ct.subrogation_expense_recovery_amt)+ct.deductible_recovery_amt+
                        ct.reinsurance_recovery_amt+ct.overpayment_recovery_amt+ct.deductible_expense_recovery_amt+
                        ct.reinsurance_expense_recovery_amt+ct.overpayment_expense_recovery_amt+ct.subrogation_defense_recovery_amt+
                        ct.salvage_defense_recovery_amt+ct.deductible_defense_recovery_amt+
                        ct.reinsurance_defense_recovery_amt+ct.overpayment_defense_recovery_amt
        ) as total_loss_incurred
                    INTO edw_temp.sp_reconciliation_claim_snapsheet_temp2
        from edw_core.tclaim_transaction ct, edw_core.tclaim b ,edw_core.tclaim_feature c
        where
        ct.claim_sk=b.claim_sk and ct.claim_feature_sk=c.claim_feature_sk
        group by c.claim_feature_sk,b.claim_no,c.claim_coverage_cd

        ----########FINAL query to IDENTIFY loss incurred mismatches between SNAPSHEET AND EDW
        SELECT b.claim_no,c.claim_sk, cf.claim_feature_sk,
        a.exposure_id,a.total_loss_incurred as snapsheet_loss_incurred,b.total_loss_incurred,a.total_loss_incurred-b.total_loss_incurred as [difference]
        INTO edw_temp.snapsheet_edw_claim_loss_reconciliation 
        from
        (
        select claim_number, exposure_id,sum(total_loss_incurred) as total_loss_incurred from edw_temp.sp_reconciliation_claim_snapsheet_temp1 --where claim_number='C21HOA00007'
        group by claim_number, exposure_id
        )a,
        edw_temp.sp_reconciliation_claim_snapsheet_temp2 b,
        edw_core.tclaim c,
        edw_core.tclaim_feature cf,
        edw_stage_snapsheet.claims cl,
        edw_stage_snapsheet.exposures ex
        where a.claim_number=b.claim_no and a.exposure_id=b.claim_coverage_cd and a.total_loss_incurred!=b.total_loss_incurred
        and b.claim_no=c.claim_no 
        and b.claim_feature_sk=cf.claim_feature_sk
        and c.claim_no=cl.claim_number
        and cf.claim_coverage_cd=ex.id
        and cf.claim_feature_sk not in (select claim_feature_sk from edw_core.tclaim_feature where source_system_sk=3 and (loss_reserve_amt<0 or expense_reserve_amt<0))
        and a.exposure_id not in (1613080,1628118,1700485,1700486,1614121,1627800,1608086,1603515)--> ebao issues
        ORDER BY claim_no desc

        drop table if exists edw_temp.sp_reconciliation_claim_snapsheet_temp1
        drop table if exists edw_temp.sp_reconciliation_claim_snapsheet_temp2
        
		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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