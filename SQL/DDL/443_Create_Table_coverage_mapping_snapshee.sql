IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'coverage_mapping_snapsheet' AND schema_name(schema_id) = 'edw_stage')
BEGIN CREATE TABLE [edw_stage].[coverage_mapping_snapsheet](
	[product_nm] [varchar](255) NULL,
	[table_nm] [varchar](255) NULL,
	[column_nm] [varchar](255) NULL,
	[snapsheet_coverage_nm] [varchar](255) NULL,
	[snapsheet_coverage_cd] [varchar](255) NULL,
	[coverage_type] [varchar](255) NULL,
	[snapsheet_deductible_type] [varchar](255) NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL
)
END

