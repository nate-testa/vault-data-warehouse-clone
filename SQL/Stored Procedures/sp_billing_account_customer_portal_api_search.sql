SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-10-05
-- Description: This stored search data related to Billing Account
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_billing_account_customer_portal_api_search]
(
  @billingaccount_no varchar(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
	[billingaccount_no]
      ,[first_nm]
      ,[last_nm]
      ,[mailing_address_line_1]
      ,[mailing_address_line_2]
      ,[mailing_city_nm]
      ,[mailing_state_cd]
      ,[mailing_zip_cd]
      ,[email]
      ,[auto_pay_in]
      ,[birth_dt]
      ,[effective_dt]
      ,[expiration_dt]
      ,[payor_nm]
      ,[phone_no]
      ,[create_ts]
      ,[update_ts]
      ,[etl_audit_sk]
	FROM
	[edw_integration].[billing_account_customer_portal_api]
	WHERE  
		[billingaccount_no]=@billingaccount_no
END
GO