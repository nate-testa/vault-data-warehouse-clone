SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This stored return billing data with policy no for majesco file processing
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 02/08/24		    Yunus Mohammed				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_billing_account_majesco_api]
(
  @policy_no varchar(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	select
        billingaccount_no,
        product_nm,
        policy_no,
        insured_nm
    from edw_integration.policy_customer_portal_api
    where policy_no like @policy_no + '%'
END
GO