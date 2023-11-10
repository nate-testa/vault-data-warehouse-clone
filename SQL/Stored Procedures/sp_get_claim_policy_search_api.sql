SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This proceudre return policy detail for claim
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 08/18/23		Mohammed Yunus				1. Created this procedure 
-- 10/26/23		Mohammed Yunus				2. updated columns list returned
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_policy_search_api]
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
	DISTINCT policy_no,transaction_type,expiration_dt,effective_dt,
			product_nm,insured_type,insured_nm,policy_status,
			REPLACE(uw_company_nm,'E & S','E&S') company
	FROM
	[edw_integration].[claim_policy_search_api] cosi
	WHERE  
		policy_no=@policy_number
		AND (
			( @dateOfLoss >= CAST(transaction_effective_dt AS DATE))
			OR 
			( @dateOfLoss BETWEEN CAST(transaction_effective_dt AS DATE) AND CAST(expiration_dt AS date) 
			OR CAST(expiration_dt AS DATE) <=  @dateOfLoss
			) 
		)
		 AND transaction_seq_no IN 
		 ( 
			SELECT MAX(cosai.transaction_seq_no)
			 FROM [edw_integration].[claim_policy_search_api] cosai
			 WHERE cosai.policy_no= @policy_number
			 AND ( 
				( @dateOfLoss BETWEEN CAST(transaction_effective_dt AS DATE) AND CAST(expiration_dt AS DATE) 
				OR CAST(expiration_dt AS DATE) <=  @dateOfLoss
				)
				AND ( @dateOfLoss BETWEEN CAST(effective_dt AS DATE) AND CAST(expiration_dt AS DATE) ) 
			 ) 
		)
END
GO
