update [edw_stage].[ControlLoadTable]
set CopyEnabled = 1
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersionPremiumRaterReference';

update [edw_stage].[ControlLoadTable]
set CopyEnabled = 1
where JSON_value(SourceObjectSettings,'$.table') = 'AccountRaterReference';
