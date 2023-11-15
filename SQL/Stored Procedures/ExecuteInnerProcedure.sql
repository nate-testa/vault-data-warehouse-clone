CREATE OR ALTER PROCEDURE edw_core.ExecuteInnerProcedure
    @name NVARCHAR(100)
AS
BEGIN
    -- Execute the stored procedure using the provided name parameter
    EXEC @name;
END;
