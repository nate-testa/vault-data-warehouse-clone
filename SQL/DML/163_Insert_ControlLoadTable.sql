DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "BrokerageServicingTeam"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "BrokerageServicingTeam"
        },
        "CopySourceSettings": {
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[BrokerageServicingTeam]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "CopySinkSettings": {
            "preCopyScript": "TRUNCATE TABLE edw_stage.BrokerageServicingTeam",
            "tableOption": "autoCreate",
			"writeBehavior": "insert",
			"sqlWriterUseTableLock": true,
			"disableMetricsCollection": false,
			"upsertSettings": null
        },
        "CopyActivitySettings": {
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "Id",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "Id",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "type": "DateTime",
                            "physicalType": "datetime2"
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
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        },
        "TopLevelPipelineName": "MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel",
        "TriggerName": [
            "Sandbox",
            "Trigger_1i1"
        ],
        "DataLoadingBehaviorSettings": {   "dataLoadingBehavior": "FullLoad",   "watermarkColumnName": null,   "watermarkColumnType": null,   "watermarkColumnStartValue": null  },
		"LastExecution": {
            "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",
            "LastExecutionTime": "00:00:00"
        },
		"CustomScript": {              "SelectStatement": "SELECT * FROM "          },
        "TaskId": 0,
        "CopyEnabled": 1
    }
]';
            INSERT INTO [edw_stage].[ControlLoadTable] (
                [SourceObjectSettings],
                [SourceConnectionSettingsName],
                [CopySourceSettings],
                [SinkObjectSettings],
                [SinkConnectionSettingsName],
                [CopySinkSettings],
                [CopyActivitySettings],
                [TopLevelPipelineName],
                [TriggerName],
                [DataLoadingBehaviorSettings],
                [LastExecution],
				[CustomScript],
				[TaskId],
                [CopyEnabled])
            SELECT * FROM OPENJSON(@MainControlMetadata)
                WITH ([SourceObjectSettings] [nvarchar](max) AS JSON,
                [SourceConnectionSettingsName] [varchar](max),
                [CopySourceSettings] [nvarchar](max) AS JSON,
                [SinkObjectSettings] [nvarchar](max) AS JSON,
                [SinkConnectionSettingsName] [varchar](max),
                [CopySinkSettings] [nvarchar](max) AS JSON,
                [CopyActivitySettings] [nvarchar](max) AS JSON,
                [TopLevelPipelineName] [varchar](max),
                [TriggerName] [nvarchar](max) AS JSON,
                [DataLoadingBehaviorSettings] [nvarchar](max) AS JSON,
				[LastExecution] [nvarchar](max) AS JSON,
				[CustomScript] [nvarchar](max) AS JSON,
                [TaskId] [int],
                [CopyEnabled] [bit])
			WHERE NOT EXISTS
			(
  				SELECT 1
  				FROM [edw_stage].[ControlLoadTable]
  				WHERE JSON_value(SourceObjectSettings,'$.table') = 'BrokerageServicingTeam'
			)