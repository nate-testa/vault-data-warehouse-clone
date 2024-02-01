DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "tableName": "t_clm_litigation"
        },
        "SinkObjectSettings": {
            "table": "t_clm_litigation",
            "schema": "edw_stage"
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
                            "name": "SUIT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUIT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CASE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CASE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OBJECT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OBJECT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_STATUS_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_STATUS_REMARK",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_CASE_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_CASE_NUMBER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_OPEN_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "SUIT_OPEN_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "AMOUNT_APEALED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "AMOUNT_APEALED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "AMTAPE_CURCODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AMTAPE_CURCODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_LOCATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUIT_LOCATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LAWYER_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LAWYER_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LAWYER_TEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LAWYER_TEL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LAWYER_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LAWYER_EMAIL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUIT_CLOSE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "SUIT_CLOSE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "DEPOSITION_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEPOSITION_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEPAMT_CURCODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DEPAMT_CURCODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSERT_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSERT_BY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSERT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INSERT_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "UPDATE_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "UPDATE_BY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "UPDATE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "UPDATE_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_OBJECT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "BUSINESS_OBJECT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DYNAMIC_FIELDS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DYNAMIC_FIELDS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LIABILITY_PERCENTAGE_ON_INSURED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LIABILITY_PERCENTAGE_ON_INSURED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ESTIMATED_FULL_PROCEEDING_LITIGATION_AWARD_AND_COST",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ESTIMATED_FULL_PROCEEDING_LITIGATION_AWARD_AND_COST",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TOTAL_SAVINGS",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TOTAL_SAVINGS",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "COVERAGE_COUNSEL_APPOINTED_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "COVERAGE_COUNSEL_APPOINTED_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "PROACTIVE_THIRD_PARTY_CLAIM_ACTIVATION_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "PROACTIVE_THIRD_PARTY_CLAIM_ACTIVATION_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_COVERAGE_COUNSEL_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_COVERAGE_COUNSEL_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_CLAIM_SETTLED_STAGE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_CLAIM_SETTLED_STAGE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_APPOINT_COVERAGE_COUNSEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_APPOINT_COVERAGE_COUNSEL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PROACTIVE_TP_CLAIMS_ACTIVATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PROACTIVE_TP_CLAIMS_ACTIVATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PROACTIVE_TP_CLAIMS_SUCCESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PROACTIVE_TP_CLAIMS_SUCCESS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_CLAIMANT_REPRESENTATIVE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_CLAIMANT_REPRESENTATIVE_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MEDIATION_SUCCESSFUL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MEDIATION_SUCCESSFUL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NAME_OF_MEDIATOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NAME_OF_MEDIATOR",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DATE_OF_MEDIATION",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DATE_OF_MEDIATION",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "MEDIATION_ENGAGED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MEDIATION_ENGAGED",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_DEFENSE_LAW_FIRM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "AW_DEFENSE_LAW_FIRM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_DEFENSE_LAW_FIRM_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_DEFENSE_LAW_FIRM_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_COVERAGE_LAW_FIRM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "AW_COVERAGE_LAW_FIRM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_COVERAGE_LAW_FIRM_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_COVERAGE_LAW_FIRM_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_CLAIMANT_LAW_FIRM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TP_CLAIMANT_LAW_FIRM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_CLAIMANT_LAW_FIRM_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_CLAIMANT_LAW_FIRM_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_CLAIMANT_LEGAL_PROCEEDING_ISSUED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_CLAIMANT_LEGAL_PROCEEDING_ISSUED",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_APPOINT_DEFENCE_COUNSEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_APPOINT_DEFENCE_COUNSEL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DATE_OF_DEFENCE_LAYER_APP",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DATE_OF_DEFENCE_LAYER_APP",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DATE_OF_SUIT_SERVED",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "TP_DATE_OF_SUIT_SERVED",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_DEFENCE_COUNSEL_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_DEFENCE_COUNSEL_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DATE_OF_LETTER_OF_DEMAND",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "TP_DATE_OF_LETTER_OF_DEMAND",
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