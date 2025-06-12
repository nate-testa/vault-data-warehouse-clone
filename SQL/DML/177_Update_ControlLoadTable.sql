update [edw_stage].[ControlLoadTable]
set DataLoadingBehaviorSettings = '{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }'
,CopySinkSettings = '{
	"preCopyScript": "TRUNCATE TABLE edw_stage.AccountSubjectivity",
	"tableOption": "autoCreate",
	"writeBehavior": "insert",
	"sqlWriterUseTableLock": true,
	"disableMetricsCollection": false,
	"upsertSettings": null
}'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountSubjectivity';