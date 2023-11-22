-- Broker
update edw_stage.ControlLoadTable
set DataLoadingBehaviorSettings = '{
	"dataLoadingBehavior": "FullLoad",
	"watermarkColumnName": null,
	"watermarkColumnType": null,
	"watermarkColumnStartValue": null
}'
,CopySinkSettings = '{
	"preCopyScript": null,
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": {
		"useTempDB": true
	}
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
	"preCopyScript": null,
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": {
		"useTempDB": true
	}
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
	"preCopyScript": null,
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": {
		"useTempDB": true
	}
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
	"preCopyScript": null,
	"tableOption": null,
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": {
		"useTempDB": true
	}
}'
where JSON_value(SourceObjectSettings,'$.table') = 'BrokerageCompanyTeamMember';