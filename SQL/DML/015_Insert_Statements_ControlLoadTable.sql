
   
            DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "AccountTransactionRequirement"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "AccountTransactionRequirement"
        },
        "CopySourceSettings": {
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "CopySinkSettings": {
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
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
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "AccountTransactionId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "AccountTransactionId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "RequirementId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RequirementId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "Message",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Message",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Prevent",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Prevent",
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
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        },
		"LastExecution": {
            "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",
            "LastExecutionTime": "00:00:00"
        },
		"CustomScript": {              "SelectStatement": "SELECT * FROM "          },
        "TaskId": 0,
        "CopyEnabled": 1
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "InsuredDocument"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "InsuredDocument"
        },
        "CopySourceSettings": {
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "CopySinkSettings": {
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        },
        "CopyActivitySettings": {
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
                            "name": "DocumentId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "DocumentId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "InsuredId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "InsuredId",
                            "type": "Guid"
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
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        },
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