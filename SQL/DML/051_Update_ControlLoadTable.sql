update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{              "isolationLevel": "ReadUncommitted",              "partitionOption": "None",              "sqlReaderQuery": null,              "partitionLowerBound": null,              "partitionUpperBound": null,              "partitionColumnName": null,              "partitionNames": null          }'
,CopySinkSettings = '{   "preCopyScript": "TRUNCATE TABLE edw_stage.CompanyTeam",   "tableOption": null,   "writeBehavior": "insert",   "sqlWriterUseTableLock": true,   "disableMetricsCollection": false,   "upsertSettings": null  }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "FullLoad",   "watermarkColumnName": null,   "watermarkColumnType": null,   "watermarkColumnStartValue": null  }'
where JSON_value(SourceObjectSettings,'$.table') = 'CompanyTeam';

update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{              "isolationLevel": "ReadUncommitted",              "partitionOption": "None",              "sqlReaderQuery": null,              "partitionLowerBound": null,              "partitionUpperBound": null,              "partitionColumnName": null,              "partitionNames": null          }'
,CopySinkSettings = '{   "preCopyScript": "TRUNCATE TABLE edw_stage.CompanyTeamBrokerage",   "tableOption": null,   "writeBehavior": "insert",   "sqlWriterUseTableLock": true,   "disableMetricsCollection": false,   "upsertSettings": null  }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "FullLoad",   "watermarkColumnName": null,   "watermarkColumnType": null,   "watermarkColumnStartValue": null  }'
where JSON_value(SourceObjectSettings,'$.table') = 'CompanyTeamBrokerage';

update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{              "isolationLevel": "ReadUncommitted",              "partitionOption": "None",              "sqlReaderQuery": null,              "partitionLowerBound": null,              "partitionUpperBound": null,              "partitionColumnName": null,              "partitionNames": null          }'
,CopySinkSettings = '{   "preCopyScript": "TRUNCATE TABLE edw_stage.CompanyTeamMember",   "tableOption": null,   "writeBehavior": "insert",   "sqlWriterUseTableLock": true,   "disableMetricsCollection": false,   "upsertSettings": null  }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "FullLoad",   "watermarkColumnName": null,   "watermarkColumnType": null,   "watermarkColumnStartValue": null  }'
where JSON_value(SourceObjectSettings,'$.table') = 'CompanyTeamMember';