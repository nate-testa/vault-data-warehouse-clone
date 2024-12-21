update [edw_stage].[ControlLoadTable]
set CopySinkSettings = '{   "preCopyScript": "TRUNCATE TABLE edw_stage.ProductObjectFieldValueDisplay",   "tableOption": "autoCreate",   "writeBehavior": "insert",   "sqlWriterUseTableLock": true,   "disableMetricsCollection": false,   "upsertSettings": null  }'
where JSON_value(SourceObjectSettings,'$.table') = 'ProductObjectFieldValueDisplay';