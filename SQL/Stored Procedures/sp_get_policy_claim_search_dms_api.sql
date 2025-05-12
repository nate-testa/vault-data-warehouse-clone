-- ================================================================================================
-- Author:		Yunus Mohammed
-- Create Date: 01/16/2025
-- Description: This procedures exposes data for policy claim search dms api
---------------------------------------------------------------------------------------------------
-- Change date		           |Author						            |	Change Description
---------------------------------------------------------------------------------------------------
-- 01/16/2025		        Yunus Mohammed				1. Created this procedure 
-- 01/31/2025               Yunus Mohammed              2. Param used in where clause
-- ================================================================================================ 

CREATE OR ALTER PROCEDURE [edw_integration].[sp_get_policy_claim_search_dms_api]
@policy_no varchar(255)
AS
BEGIN
    SELECT
     policy_no, CONCAT_WS(' | ',policy_no,claim_no) as claim_no
    FROM
        edw_integration.policy_claim_search_dms_api
    WHERE  
        policy_no like '%' + @policy_no + '%'
END
GO