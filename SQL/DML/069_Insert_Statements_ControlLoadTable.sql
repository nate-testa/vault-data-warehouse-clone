DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "tableName": "`DmsDocument`"
        },
        "SinkObjectSettings": {
            "table": "DmsDocument",
            "schema": "edw_stage"
        },
        "CopySourceSettings": {
            "query": "SELECT dd.dmsDocumentId, dd.claimNumber, ddd.type AS document_type, ddd.subType, dd.documentName, dd.fileName as document_fileName, dda.name as attachedTo, dd.createDate, dd.documentDate, dd.createBy,\"Unknown\" as paymentStatus, \r\nnow() as create_ts\r\nFROM dms_core.DmsDocument dd,\r\ndms_core.DmsDocumentDetail ddd,\r\ndms_core.DmsDocumentAttachTo dda\r\nWHERE dd.dmsDocumentId = dda.dmsDocumentId \r\nand ddd.dmsDocumentId = dda.dmsDocumentId\r\nand ddd.type = ''Claim''\r\nand ddd.subType IN (''Estimate of Damages'',''BI/UM Demand'')\r\norder by dd.createDate desc"
        },
        "CopySinkSettings": {
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false
        },
        "CopyActivitySettings": {
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "dmsDocumentId",
                            "type": "Int32"
                        },
                        "sink": {
                            "name": "dmsDocumentId",
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "claimNumber",
                            "type": "String"
                        },
                        "sink": {
                            "name": "claimNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "document_type",
                            "type": "String"
                        },
                        "sink": {
                            "name": "document_type",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "subType",
                            "type": "String"
                        },
                        "sink": {
                            "name": "subType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "documentName",
                            "type": "String"
                        },
                        "sink": {
                            "name": "documentName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "document_fileName",
                            "type": "String"
                        },
                        "sink": {
                            "name": "document_fileName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "attachedTo",
                            "type": "String"
                        },
                        "sink": {
                            "name": "attachedTo",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "documentDate",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "documentDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "createBy",
                            "type": "String"
                        },
                        "sink": {
                            "name": "createBy",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "queryRunDate",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "queryRunDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "paymentStatus",
                            "type": "String"
                        },
                        "sink": {
                            "name": "paymentStatus",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "create_ts",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "create_ts",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        },
        "TopLevelPipelineName": "MetadataDrivenCopy_LS_AWS_DMS_dd8_TopLevel",
        "TriggerName": [
            "Sandbox",
            "Trigger_dd8"
        ],
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "FullLoad"
        },
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
                [TaskId] [int],
                [CopyEnabled] [bit])