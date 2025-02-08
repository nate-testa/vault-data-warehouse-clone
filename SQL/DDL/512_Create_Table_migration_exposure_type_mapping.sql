IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_exposure_type_mapping')
BEGIN
CREATE TABLE [edw_stage].[migration_exposure_type_mapping](
	[product_cd] [varchar](3) NOT NULL,
	[coverage_name] [varchar](255) ,
	[subclaim_type_name] [varchar](255) ,
	[snapsheet_exposure_type] [varchar](28) NOT NULL
)
END