
            
            DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "tableName": "`t_clm_subclaim_type`"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "t_clm_subclaim_type"
        },
        "CopySourceSettings": {
            "query": "select * from `t_clm_subclaim_type`"
        },
        "CopySinkSettings": {
            "preCopyScript": null,
            "tableOption": "autoCreate"
        },
        "CopyActivitySettings": {
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "SUBCLAIM_TYPE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBCLAIM_TYPE_CODE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBCLAIM_TYPE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBCLAIM_TYPE_NAME",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_UNIQUE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_UNIQUE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_INSURED_OBJECT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_INSURED_OBJECT",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBCLAIM_TYPE_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBCLAIM_TYPE_DESC",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "FRAUD_SUBJECT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "FRAUD_SUBJECT_CODE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "INSERT_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSERT_BY",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSERT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INSERT_TIME",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "UPDATE_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "UPDATE_BY",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "UPDATE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "UPDATE_TIME",
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
        "TopLevelPipelineName": "MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel",
        "TriggerName": [
            "Sandbox",
            "Trigger_mqq"
        ],
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "FullLoad"
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