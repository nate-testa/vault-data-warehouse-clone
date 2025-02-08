IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_stage'
and TABLE_name = 'migration_loss_type_mapping')
BEGIN
CREATE TABLE [edw_stage].[migration_loss_type_mapping](
	[product_cd] [varchar](255) ,
	[cause_of_loss_cd] [varchar](255) ,
	[cause_of_loss_desc] [varchar](255) ,
	[sub_cause_of_loss_cd] [varchar](255) ,
	[sub_cause_of_loss_desc] [varchar](255) ,
	[lossType] [varchar](255) 
) ON [PRIMARY]
END