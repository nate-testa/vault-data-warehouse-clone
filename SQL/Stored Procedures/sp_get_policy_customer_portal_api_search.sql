/****** Object:  StoredProcedure [edw_integration].[sp_get_policy_customer_portal_api_search]    Script Date: 24/10/2023 10:35:35 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-10-05
-- Description: This stored search data related to Policy Customer
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_policy_customer_portal_api_search]
(
  @billingaccount_no varchar(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
	[policy_no]
      ,[product_nm]
      ,[insured_nm]
	FROM
	[edw_integration].[policy_customer_portal_api]
	WHERE  
		[billingaccount_no]=@billingaccount_no
END
GO