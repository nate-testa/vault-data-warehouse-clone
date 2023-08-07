-- Create a new stored procedure called 'StoredProcedureName' in schema 'dbo'
-- Drop the stored procedure if it already exists
IF EXISTS (
SELECT *
    FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_SCHEMA = N'dbo'
    AND SPECIFIC_NAME = N'sp_test1'
    AND ROUTINE_TYPE = N'PROCEDURE'
)
DROP PROCEDURE dbo.sp_test1
GO
-- Create the stored procedure in the specified schema
CREATE PROCEDURE dbo.sp_test1
    @param1 /*parameter name*/ int /*datatype_for_param1*/ = 0, /*default_value_for_param1*/
    @param2 /*parameter name*/ int /*datatype_for_param1*/ = 0 /*default_value_for_param2*/
-- add more stored procedure parameters here
AS
BEGIN
    -- body of the stored procedure
    SELECT @param1, @param2
END
GO
