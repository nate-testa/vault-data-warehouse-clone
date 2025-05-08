SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This proceudre return claim renewal rating data for auto and pel
---------------------------------------------------------------------------------------------------
-- Change date 			|Author									 |	Change Description
---------------------------------------------------------------------------------------------------
-- 10/06/23				Yunus Mohammed				1. Created this procedure 
-- 12/18/24				Yunus Mohammed				2. AD7660 - Added new column
-- 01/22/24				Yunus Mohammed				3. AD8090 - Added new columns
-- 05/08/25				Yunus Mohammed				4. AD9412 Added new columns
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_renewal_rating_auto_pel_api]
(
 @PolicyNumber NVARCHAR(MAX)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
		crra.IncidentDate,crra.PolicyNumber,crra.FileNumber,crra.IncidentType,crra.IncidentDescription,crra.IncidentCode,crra.IncidentStatus,
		crra.TotalPayout,crra.BodilyInjuryPayment,crra.CollisionPayment,crra.ComprehensivePayment,crra.GlassPayment,crra.MedicalExpensePayment,
		crra.MedicalPaymentPayment,crra.OtherPayment,crra.PropertyDamagePayment,crra.PersonalInjuryProtectionPayment,
		crra.RentalReimbursementPayment,crra.SpousalLiabilityPayment,crra.TowingAndLaborPayment,crra.UninsuredMotoristPayment,
		crra.UnderinsuredMotoristPayment,crra.ViolationPointClass,FirstPartyDriverName,
		crra.FaultDecision,crra.ResponsibleParty,crra.AtFaultPercent,AdjusterName,FirstPartyDriverRelationshipToInsured
	FROM
		edw_integration.claim_renewal_rating_auto_pel_api AS crra
		INNER JOIN
		OPENJSON(@PolicyNumber)
		WITH
		(
		PolicyNumber varchar(200) '$.PolicyNumber'
		) AS pn ON crra.PolicyNumber=pn.PolicyNumber
END
GO
