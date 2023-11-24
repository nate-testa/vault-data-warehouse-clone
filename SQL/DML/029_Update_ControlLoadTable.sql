-- Broker
update edw_stage.ControlLoadTable
set DataLoadingBehaviorSettings = '{
	"dataLoadingBehavior": "FullLoad",
	"watermarkColumnName": null,
	"watermarkColumnType": null,
	"watermarkColumnStartValue": null
}'
,CopySinkSettings = '{
	"preCopyScript": "TRUNCATE TABLE edw_stage.Broker",
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": null
}'
where JSON_value(SourceObjectSettings,'$.table') = 'Broker';

-- BrokerageLicense
update edw_stage.ControlLoadTable
set DataLoadingBehaviorSettings = '{
	"dataLoadingBehavior": "FullLoad",
	"watermarkColumnName": null,
	"watermarkColumnType": null,
	"watermarkColumnStartValue": null
}'
,CopySinkSettings = '{
	"preCopyScript": "TRUNCATE TABLE edw_stage.BrokerageLicense",
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": null
}'
where JSON_value(SourceObjectSettings,'$.table') = 'BrokerageLicense';

-- BrokerageCommission
update edw_stage.ControlLoadTable
set DataLoadingBehaviorSettings = '{
	"dataLoadingBehavior": "FullLoad",
	"watermarkColumnName": null,
	"watermarkColumnType": null,
	"watermarkColumnStartValue": null
}'
,CopySinkSettings = '{
	"preCopyScript": "TRUNCATE TABLE edw_stage.BrokerageCommission",
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": null
}'
where JSON_value(SourceObjectSettings,'$.table') = 'BrokerageCommission';

-- BrokerageCompanyTeamMember
update edw_stage.ControlLoadTable
set DataLoadingBehaviorSettings = '{
	"dataLoadingBehavior": "FullLoad",
	"watermarkColumnName": null,
	"watermarkColumnType": null,
	"watermarkColumnStartValue": null
}'
,CopySinkSettings = '{
	"preCopyScript": "TRUNCATE TABLE edw_stage.BrokerageCompanyTeamMember",
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": null
}'
where JSON_value(SourceObjectSettings,'$.table') = 'BrokerageCompanyTeamMember';