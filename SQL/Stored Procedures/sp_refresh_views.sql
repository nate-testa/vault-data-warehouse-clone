-- =============================================
-- Author:      Hernando Gonzalez
-- Create Date: 10/07/2024
-- Description: This procedure refreshes a list of views
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_refresh_views]
AS
BEGIN
    SET NOCOUNT ON;

    EXECUTE sp_refreshview '[edw_core].[vaoncatstore]';  
    EXECUTE sp_refreshview '[edw_core].[vcapeanalytics]'; 
    EXECUTE sp_refreshview '[edw_core].[vcarfaxmileage]';  
    EXECUTE sp_refreshview '[edw_core].[vcarfaxvalue]'; 
    EXECUTE sp_refreshview '[edw_core].[vclaimpaymentestimate]';  
    EXECUTE sp_refreshview '[edw_core].[vclueproperty]'; 
    EXECUTE sp_refreshview '[edw_core].[vguycarpenter]';  
    EXECUTE sp_refreshview '[edw_core].[vhazardhub]'; 
    EXECUTE sp_refreshview '[edw_core].[visoproperty]';  
    EXECUTE sp_refreshview '[edw_core].[visovehicle]'; 
    EXECUTE sp_refreshview '[edw_core].[vmvr]';  
    EXECUTE sp_refreshview '[edw_core].[vnhtsa]';  
    EXECUTE sp_refreshview '[edw_core].[vtransunion]'; 
    EXECUTE sp_refreshview '[edw_core].[vlc360]'; 
	EXECUTE sp_refreshview '[edw_core].[vhome_coverage_ext]';
	EXECUTE sp_refreshview '[edw_core].[vissterritory]';
	EXECUTE sp_refreshview '[edw_core].[vnfppolicy] ';
	EXECUTE sp_refreshview '[edw_core].[vquote_home_coverage_ext]';
	EXECUTE sp_refreshview '[edw_core].[vredzone]';
	EXECUTE sp_refreshview '[edw_core].[vticoplacecode]';

    SET NOCOUNT OFF;
END
GO