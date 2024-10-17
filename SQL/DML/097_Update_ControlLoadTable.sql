update [edw_stage].[ControlLoadTable]
set CopyActivitySettings = '{
	"translator": {
		"type": "TabularTranslator",
		"mappings": [
			{
				"source": {
					"name": "Id",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "Id",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "AccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "AccountId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "DateOrdered",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "DateOrdered",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "DateTimeRecieved",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "DateTimeRecieved",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "DateTimeCompleted",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "DateTimeCompleted",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "ReportType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ReportType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Reference",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Reference",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TransactionReferenceId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TransactionReferenceId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RequestRaw",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RequestRaw",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ResponseRaw",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ResponseRaw",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TransactionStatus",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TransactionStatus",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Source",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Source",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CreatedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "CreatedDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "UpdatedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "UpdatedDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "ReferenceUrl",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ReferenceUrl",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ExternalSourceId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ExternalSourceId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AutoOrder",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "AutoOrder",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ExternalSourceUniqueId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ExternalSourceUniqueId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsCopy",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsCopy",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsReportFromCache",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsReportFromCache",
					"type": "Boolean"
				}
			}
		],
		"typeConversion": true,
		"typeConversionSettings": {
			"allowDataTruncation": true,
			"treatBooleanAsNumber": false
		}
	}
}'
,LastExecution = '{              "LastExecutionDate": "1900-01-01T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }'
,DataLoadingBehaviorSettings = '{   "dataLoadingBehavior": "DeltaLoad",   "watermarkColumnName": "CreatedDate",   "watermarkColumnType": "DateTime",   "watermarkColumnNameUpdate": "UpdatedDate",   "watermarkColumnNameUpdatType": "DateTime",   "watermarkColumnStartValue": "1900-01-01T00:00:00.0000000"  }'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountReport';