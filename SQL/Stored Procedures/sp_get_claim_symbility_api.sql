SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================
-- Author:		Alberto Almario
-- Description: This proceudre return symbility detail for claim
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 08/28/23		Alberto Almario				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_symbility_api]
(
  @policy_number varchar(255),
  @dateOfLoss date
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	SELECT DISTINCT 
		policy_no,
		effective_dt,
		expiration_dt,
		transaction_effective_dt,
		transaction_seq_no,
		insured_type,
		first_nm,
		last_nm,
		business_nm,
		home_phone_no,
		mobile_phone_no,
		email,
		aop_deductible,
		dwelling_limit_amt,
		built_year
	FROM [edw_integration].[claim_symbility_api] csa
	WHERE policy_no=@policy_number
	AND (
			( @dateOfLoss >= CAST(transaction_effective_dt AS DATE))
			OR 
			( @dateOfLoss BETWEEN CAST(transaction_effective_dt AS DATE) AND CAST(expiration_dt AS date) OR CAST(expiration_dt AS DATE) <=  @dateOfLoss	) 
		)
	AND transaction_seq_no IN ( 
		SELECT MAX(csam.transaction_seq_no)
		FROM [edw_integration].[claim_symbility_api] csam
		WHERE csam.policy_no= @policy_number
		AND ( 
			( @dateOfLoss BETWEEN CAST(transaction_effective_dt AS DATE) AND CAST(expiration_dt AS DATE) OR CAST(expiration_dt AS DATE) <=  @dateOfLoss	)
		AND ( @dateOfLoss BETWEEN CAST(effective_dt AS DATE) AND CAST(expiration_dt AS DATE) ) 
		) 
	)
END
GO
