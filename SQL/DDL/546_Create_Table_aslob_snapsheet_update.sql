IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_NAME = 'aslob_snapsheet_update')
BEGIN
CREATE TABLE [edw_stage].[aslob_snapsheet_update](
	[product_cd] [varchar](16) NOT NULL,
	[coverage_nm] [varchar](51) NOT NULL,
	[snapsheet_coverage_cd] [varchar](30) NOT NULL,
	[aslob_cd] [varchar](3) NOT NULL
) 
END