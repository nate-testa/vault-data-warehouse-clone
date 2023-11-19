SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This proceudre return claim renewal rating data for home and collection
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/06/23		Mohammed Yunus				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_renewal_rating_home_collection_api]
(
  @PolicyNumber NVARCHAR(MAX)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
		crrh.PropertyOrLiability,crrh.PolicyNumber,crrh.FileNumber,crrh.ClaimStatus,crrh.Claimant,crrh.LossDate,crrh.LossIdentifier,crrh.LossType,
		crrh.SubCauseOfLoss,crrh.LossDescription,crrh.PolicyType,crrh.CatIndicator,crrh.CatCode,crrh.AddressLine1,crrh.AddressLine2,
		crrh.AddressLineUnit,crrh.AddressCity,crrh.AddressZipCode,
		crrh.AddressState,crrh.AddressCounty,crrh.AddressCountry,crrh.Coverage,crrh.ReserveExpense,crrh.ReserveIndemnity,
		crrh.PaidExpense,crrh.PaidIndemnity
	FROM
		edw_integration.claim_renewal_rating_home_collection_api AS crrh
		INNER JOIN
		OPENJSON(@PolicyNumber)
		WITH
		(
		PolicyNumber varchar(200) '$.PolicyNumber'
		) AS pn ON crrh.PolicyNumber=pn.PolicyNumber
END
GO
