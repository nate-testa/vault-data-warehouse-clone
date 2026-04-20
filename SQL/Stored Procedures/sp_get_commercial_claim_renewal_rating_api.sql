-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This proceudre return commercial claim renewal rating data
---------------------------------------------------------------------------------------------------
-- Change date 			|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/17/26				Yunus Mohammed				1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_commercial_claim_renewal_rating_api]
(
  @PolicyNumber NVARCHAR(MAX)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
        crrc.DateOfLoss, crrc.PolicyNumber, crrc.Litigation, crrc.LitigationComplete, crrc.ClaimNumber, crrc.ClaimStatus,
        crrc.Claimant, crrc.LastUpdate, crrc.CauseOfLoss, crrc.FactOfLoss, crrc.AdditionalFactOfLoss, crrc.LargeLoss,
        crrc.CurrentIndemnityReserve, crrc.TotalIndemnityPayment, crrc.CurrentExpenseReserve, crrc.TotalExpensePayment,
        crrc.CurrentLegalDefenseReserve, crrc.TotalLegalDefensePayment, crrc.TotalIncurredPayment, crrc.AdjusterName
	FROM
		edw_integration.commercial_claim_renewal_rating_api AS crrc
		INNER JOIN
		OPENJSON(@PolicyNumber)
		WITH
		(
		PolicyNumber varchar(200) '$.PolicyNumber'
		) AS pn ON crrc.PolicyNumber=pn.PolicyNumber
END
GO
