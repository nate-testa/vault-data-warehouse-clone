IF OBJECT_ID('edw_core.sp_tclaim_tag', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE edw_core.sp_tclaim_tag;
END;


IF OBJECT_ID('edw_temp.tclaim_tag_temp1', 'U') IS NOT NULL
BEGIN
    DROP TABLE edw_temp.tclaim_tag_temp1
END;


