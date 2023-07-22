IF OBJECT_ID('edw_core.z_sp_test', 'P') IS NOT NULL
    DROP PROCEDURE edw_core.z_sp_test;
GO

CREATE PROCEDURE edw_core.z_sp_test
AS
BEGIN
    PRINT '¡Test sp!dfsggasdgsdf'
END;