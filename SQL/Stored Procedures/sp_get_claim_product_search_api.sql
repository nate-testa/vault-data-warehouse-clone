-- =================================================================================================
-- Description: This procedures get data for claim product search api 
---------------------------------------------------------------------------------------------------
-- Change date			|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 01/31/24				Yunus Mohammed				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_claim_product_search_api]
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		product_nm, ebao_product_cd
	FROM
		edw_integration.claim_product_search_api
END