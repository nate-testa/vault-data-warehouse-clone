-- This is needed 
DELETE FROM [edw_stage].[ControlLoadTable] WHERE SourceObjectSettings like '%DmsDocument%';

DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "tableName": "`DmsDocument`"
        },
        "SinkObjectSettings": {
            "table": "dms_claim_payment_estimate",
            "schema": "edw_stage"
        },
        "CopySourceSettings": {
            "query": "SELECT \r\n  dd.dmsDocumentId, \r\n  dd.claimNumber, \r\n  ddd.type AS document_type, \r\n  ddd.subType, \r\n  dd.documentName, \r\n  dd.fileName as document_fileName, \r\n  dda.name as attached_To, \r\n  dd.createDate, \r\n  dd.documentDate, \r\n  dd.createBy, \r\n  \"Unknown\" as paymentStatus, \r\n  now() as create_ts \r\nFROM \r\n  dms_core.DmsDocument dd, \r\n  dms_core.DmsDocumentDetail ddd, \r\n  dms_core.DmsDocumentAttachTo dda \r\nWHERE \r\n  dd.dmsDocumentId = dda.dmsDocumentId \r\n  and ddd.dmsDocumentId = dda.dmsDocumentId \r\n  and ddd.type = ''Claim'' \r\n  and ddd.subType IN (\r\n    ''Estimate of Damages'', ''BI/UM Demand''\r\n  ) \r\norder by \r\n  dd.createDate desc\r\n"
        },
        "CopySinkSettings": {
            "preCopyScript": null,
            "tableOption": null
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
                            "physicalType": "varchar"
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
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "subType",
                            "type": "String"
                        },
                        "sink": {
                            "name": "subtype",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "varchar"
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
                            "name": "attached_To",
                            "type": "String"
                        },
                        "sink": {
                            "name": "attached_to",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "createDate",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "createDate",
                            "type": "DateTime",
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
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
                            "physicalType": "varchar"
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
                            "physicalType": "varchar"
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
                            "physicalType": "datetime"
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
        "TopLevelPipelineName": "MetadataDrivenCopy_LS_AWS_DMS_dd8_TopLevel",
        "TriggerName": [
            "Sandbox",
            "Manual"
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