IF OBJECT_ID('edw_core.z_sp_test2', 'P') IS NOT NULL
    DROP PROCEDURE edw_core.z_sp_test2;
GO

CREATE PROCEDURE edw_core.z_sp_test2
AS
BEGIN
    PRINT '¡Test sp!asdfasdfsadsdfsadff--afsasdfkjsdakfj'
    PRINT 'test 20230725'
END;