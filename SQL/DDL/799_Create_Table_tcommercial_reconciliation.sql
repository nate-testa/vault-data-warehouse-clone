If not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_commercial'
and table_name = 'tcommercial_reconciliation')
begin
    CREATE TABLE [edw_commercial].[tcommercial_reconciliation]
     (
	[tcommercial_reconciliation_sk] [int] IDENTITY(1,1) NOT NULL,
	[transaction_start_dt] [date] NULL,
	[transaction_end_dt] [date] NULL,
	[source_record_ct] [int] NULL,
	[source_amt] [decimal](15, 2) NULL,
	[target_record_ct] [int] NULL,
	[target_amt] [decimal](15, 2) NULL,
	[datamart_nm] [varchar](255) NULL,
	[status_desc] [varchar](255) NULL,
	[source_system_nm] [varchar](255) NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	CONSTRAINT pk_tcommercial_reconciliation PRIMARY KEY (tcommercial_reconciliation_sk)
    )
end
