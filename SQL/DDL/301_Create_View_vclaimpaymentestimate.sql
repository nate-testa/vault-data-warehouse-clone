IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE  TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'vclaimpaymentestimate' 
)  
DROP VIEW edw_core.vclaimpaymentestimate;

GO

CREATE VIEW [edw_core].[vclaimpaymentestimate] 
AS 
select * from edw_stage.dms_claim_payment_estimate