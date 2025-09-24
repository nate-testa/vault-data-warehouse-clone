-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This proceudre generates marine monthly report
---------------------------------------------------------------------------------------------------
-- Change date 			|Author									 |	Change Description
---------------------------------------------------------------------------------------------------
-- 09/24/25				Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_marine_monthly_report]
(
 @accounting_month VARCHAR(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON
      select 
        p.insured_nm as [Insured Name],
        p.policy_no as [Policy Number],
        p.risk_state_cd as [Risk State],
        concat_ws('-',cast(p.effective_dt as varchar(20)),cast(p.expiration_dt as varchar(20))) as [Policy Term],
        pr.[product_nm] as [Product],
        pay.payment_plan as [Pay Plan],
        pay.underwriting_company_code as [UW Co],
        sum(cast( replace(replace(pay.amount,'$',''),'-','') as decimal(18,2))) as [Payment Collected],
        sum(case when pay.receivable_type = 'Premium' then cast(replace(replace(pay.amount,'$',''),'-','') as decimal(18,2)) else 0 end) as [Commission Premium Collected],
        '20' as [Comm %],
        cast(sum(case when pay.receivable_type = 'Premium' then cast(replace(replace(pay.amount,'$',''),'-','') as decimal(18,2)) else 0 end)*0.20 as decimal(18,2)) as [Commission Paid this Period],
        (
        select cast(sum(case when pay1.receivable_type = 'Premium' then cast(replace(replace(pay1.amount,'$',''),'-','') as decimal(18,2)) else 0 end)*0.20 as decimal(18,2))
        from
        edw_core.vmajescocashactivity pay1
        where
        pay1.policy_no = p.policy_no
        and cast(pay1.policy_effective_date as date) = p.effective_dt
        ) as [Commission Paid to Date]
    from
    edw_core.tpolicy p
    inner join edw_core.tproduct pr on p.product_cd = pr.product_cd
    inner join edw_core.vmajescocashactivity pay on pay.policy_no = p.policy_no
    and cast(pay.policy_effective_date as date) = p.effective_dt
    where
    p.product_cd = 'BY'
    and pay.accounting_month  = @accounting_month
    group by p.policy_no,p.effective_dt,p.expiration_dt,p.insured_nm, pr.[product_nm],p.risk_state_cd,pay.underwriting_company_code,
    policy_term, pay.payment_plan,pay.accounting_month
 
END
GO
