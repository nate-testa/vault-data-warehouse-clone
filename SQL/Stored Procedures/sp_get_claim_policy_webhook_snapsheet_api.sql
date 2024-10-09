SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This proceudre return policy detail for claim
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/07/23		    Yunus Mohammed				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_policy_webhook_snapsheet_api]
(
  @policy_number varchar(255),
  @dateOfLoss date
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT
	DISTINCT cancelledAt, cancelledReason, effectiveAt, expirationAt, inceptionAt, policyNumber,
			policyType, [status], [version], agentInformation, product, reservation, underwriting,
			coverages ,endorsements, notes, businesses, people,	risks, versions, deductibles, [data]
	FROM
	    edw_integration.claim_policy_webhook_snapsheet_api
	WHERE  
		policyNumber = @policy_number
		AND (
			( @dateOfLoss >= CAST([version] AS DATE))
			OR 
			( @dateOfLoss BETWEEN CAST([version] AS DATE) AND CAST(expirationAt AS date) 
			OR CAST(expirationAt AS DATE) <=  @dateOfLoss
			) 
		)
		 AND transaction_seq_no IN 
		 ( 
			SELECT MAX(cosai.transaction_seq_no)
			 FROM edw_integration.claim_policy_webhook_snapsheet_api cosai
			 WHERE cosai.policyNumber =  @policy_number
			 AND ( 
				( @dateOfLoss BETWEEN CAST(version AS DATE) AND CAST(expirationAt AS DATE) 
				OR CAST(expirationAt AS DATE) <=  @dateOfLoss
				)
				AND ( @dateOfLoss BETWEEN CAST(effectiveAt AS DATE) AND CAST(expirationAt AS DATE) ) 
			 ) 
		)
END
