SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Dinesh Bobbili
-- Create Date: 2026-01-30
-- Description: This stored search data related to Broker Commission
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_broker_commission_email_api]
(
  @brokerId varchar(255)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
	broker_id,
	broker_nm,
	broker_city_nm,
	broker_state_cd,
    commission_statement_email
    FROM
        edw_integration.broker_commission_email_api
    WHERE
        broker_id = @brokerId
END
GO