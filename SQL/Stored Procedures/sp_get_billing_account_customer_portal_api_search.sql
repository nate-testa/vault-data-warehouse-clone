/****** Object:  StoredProcedure [edw_integration].[sp_get_billing_account_customer_portal_api_search]    Script Date: 24/10/2023 10:35:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-10-05
-- Description: This stored search data related to Billing Account
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_billing_account_customer_portal_api_search]
(
  @billingEmailId varchar(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
	[billingaccount_no]
      ,[email]
      ,[auto_pay_in]
	FROM
	[edw_integration].[billing_account_customer_portal_api]
	WHERE  
		[email]=@billingEmailId
END
GO