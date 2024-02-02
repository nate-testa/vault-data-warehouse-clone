update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{
    "isolationLevel": "ReadUncommitted",
    "partitionOption": "None",
    "sqlReaderQuery": null,
    "partitionLowerBound": null,
    "partitionUpperBound": null,
    "partitionColumnName": null,
    "partitionNames": null
}'
,DataLoadingBehaviorSettings = '{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'CommissionTier';

update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{
    "isolationLevel": "ReadUncommitted",
    "partitionOption": "None",
    "sqlReaderQuery": null,
    "partitionLowerBound": null,
    "partitionUpperBound": null,
    "partitionColumnName": null,
    "partitionNames": null
}'
,DataLoadingBehaviorSettings = '{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'CommissionTierBrokerage';


update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{
    "isolationLevel": "ReadUncommitted",
    "partitionOption": "None",
    "sqlReaderQuery": null,
    "partitionLowerBound": null,
    "partitionUpperBound": null,
    "partitionColumnName": null,
    "partitionNames": null
}'
,DataLoadingBehaviorSettings = '{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'CommissionGlobalExclusion';


update [edw_stage].[ControlLoadTable]
set CopySourceSettings = '{
    "isolationLevel": "ReadUncommitted",
    "partitionOption": "None",
    "sqlReaderQuery": null,
    "partitionLowerBound": null,
    "partitionUpperBound": null,
    "partitionColumnName": null,
    "partitionNames": null
}'
,DataLoadingBehaviorSettings = '{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'CommissionTierPercentage';