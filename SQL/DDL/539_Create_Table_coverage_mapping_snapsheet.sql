IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'coverage_mapping_snapsheet')
BEGIN
CREATE TABLE [edw_stage].[coverage_mapping_snapsheet](
	product_nm varchar(255) ,
	table_nm varchar(255) ,
	column_nm varchar(255) ,
	snapsheet_coverage_nm varchar(255) ,
	snapsheet_coverage_cd varchar(255) ,
	coverage_type varchar(255) ,
	snapsheet_deductible_type varchar(255) ,
	create_ts datetime NULL,
	update_ts datetime NULL
)
END ; 