-- ==============================================================================
-- Author:		Yunus Mohammed 
-- Description: This view returns claim payment estimate
---------------------------------------------------------------------------------
-- Change date			|Author						|	Change Description
---------------------------------------------------------------------------------
-- 06/0706/2024 		Yunus Mohammed				1. Created this view 
-- ==============================================================================

CREATE OR ALTER VIEW [edw_core].[vclaimpaymentestimate] 
AS 
select * from edw_stage.dms_claim_payment_estimate
GO