CREATE TABLE [edw_stage].[tvendor_report_field](
	[source] [nvarchar](4000),
	[reporttype] [nvarchar](400),
	[Category] [nvarchar](4000),
	[Group] [nvarchar](4000) null,
	[Label] [nvarchar](4000),
	[CreatedDate] [datetime2](7) NULL,
	[UpdatedDate] [datetime2](7) NULL, 
);
 
CREATE UNIQUE INDEX uidx_tvendor_report_field
ON [edw_stage].[tvendor_report_field] ([source], [reporttype], [Category], [Group], [Label]);
 
CREATE TABLE [edw_stage].[tvendor_report_field_data](
	[policynumber] [nvarchar](50),
	[effectivedate] [datetime2](7) NULL, 
	[UpdatedDate] [datetime2](7) NULL, 
	[CreatedDate] [datetime2](7) NULL,
	[dateordered] [datetime2](7) NULL, 
	[dateTimeRecieved] [datetime2](7) NULL, 
	[dateTimeCompleted] [datetime2](7) NULL, 
	[TransactionStatus] [nvarchar](4000) null,
	[source] [nvarchar](4000) null,
	[reporttype] [nvarchar](400) null,
	[field_name] [nvarchar](400) null,
	[Value]  [nvarchar](max) null
); 
 
CREATE INDEX [IX_tvendor_report_field_data_data_source] ON [edw_stage].[tvendor_report_field_data] (source);
CREATE INDEX [IX_tvendor_report_field_data_UpdatedDate] ON [edw_stage].[tvendor_report_field_data] (UpdatedDate);
CREATE INDEX [IX_tvendor_report_field_data_CreatedDate] ON [edw_stage].[tvendor_report_field_data] (CreatedDate);
CREATE INDEX [IX_tvendor_report_field_data_reporttype]  ON [edw_stage].[tvendor_report_field_data] (reporttype); 