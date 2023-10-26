
            
            DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
	{
		"SourceObjectSettings": {
			"tableName": "`t_clm_case_his`"
		},
		"SinkObjectSettings": {
			"schema": "edw_stage",
			"table": "t_clm_case_his"
		},
		"CopySinkSettings": {
			"preCopyScript": null,
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
							"name": "HIS_ID",
							"type": "Decimal"
						},
						"sink": {
							"name": "HIS_ID",
							"type": "Decimal"
						}
					},
					{
						"source": {
							"name": "CASE_ID",
							"type": "Decimal"
						},
						"sink": {
							"name": "CASE_ID",
							"type": "Decimal"
						}
					},
					{
						"source": {
							"name": "OLD_STATUS",
							"type": "String"
						},
						"sink": {
							"name": "OLD_STATUS",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "NEW_STATUS",
							"type": "String"
						},
						"sink": {
							"name": "NEW_STATUS",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "CLAIM_TYPE",
							"type": "String"
						},
						"sink": {
							"name": "CLAIM_TYPE",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "CLOSE_TYPE",
							"type": "String"
						},
						"sink": {
							"name": "CLOSE_TYPE",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "REJECT_REASON",
							"type": "String"
						},
						"sink": {
							"name": "REJECT_REASON",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "REOPEN_CAUSE",
							"type": "String"
						},
						"sink": {
							"name": "REOPEN_CAUSE",
							"type": "String"
						}
					},
					{
						"source": {
							"name": "REMARK",
							"type": "String"
						},
						"sink": {
							"name": "REMARK",
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
		"CustomScript": {
			"SelectStatement": "SELECT * FROM "
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