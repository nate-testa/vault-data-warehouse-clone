IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_coverage_mapping')
BEGIN
CREATE TABLE [edw_stage].[migration_coverage_mapping](
	[product_cd] [varchar](255) ,
	[sub_claimtype_nm] [varchar](255) ,
	[coverage_nm] [varchar](255) ,
	[snapsheet_coverage_nm] [varchar](255) ,
	[snapsheet_coverage_cd] [varchar](255) 
) 
END