SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: Returns last source extract timestamp from given process name
-- =============================================
CREATE FUNCTION [edw_core].[fn_get_last_source_extract_ts]
(
   @process_nm varchar(255)
)
RETURNS datetime2(7)
AS
BEGIN
    -- Declare the return variable here
    DECLARE @last_source_extract_ts DATETIME2(7)

    -- Add the T-SQL statements to compute the return value here
    SELECT @last_source_extract_ts=last_source_extract_ts FROM [edw_core].[tetl_control] WHERE process_nm=@process_nm
    -- Return the result of the function
    RETURN ISNULL(@last_source_extract_ts,'1900-01-01')
END
GO