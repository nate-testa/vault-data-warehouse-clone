            DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "tableName": "`t_pty_party_type`"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "t_pty_party_type"
        },
        "CopySourceSettings": {
            "query": "select * from `t_pty_party_type`"
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
                            "name": "PARTY_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TYPE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TYPE_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_ORG_PARTY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_ORG_PARTY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DESCRIPTION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DESCRIPTION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_CATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PARTY_CATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RECORD_USAGE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RECORD_USAGE",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
    },
    {
        "SourceObjectSettings": {
            "tableName": "`t_pty_party`"
        },
        "SinkObjectSettings": {
            "schema": "edw_stage",
            "table": "t_pty_party"
        },
        "CopySourceSettings": {
            "query": "select * from `t_pty_party`"
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
                            "name": "PARTY_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PARTY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
                            "name": "MERGED_PARTY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "MERGED_PARTY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_CODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_ALIAS_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_ALIAS_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_COUNTRY_OF_BIRTH",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_COUNTRY_OF_BIRTH",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_COURTESY_TITLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_COURTESY_TITLE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_DATE_OF_BIRTH",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INDI_DATE_OF_BIRTH",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_DATE_OF_DEATH",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INDI_DATE_OF_DEATH",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_GENDER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_GENDER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_ID_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_ID_NUMBER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_ID_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_ID_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_LANGUAGE_PREFERRED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_LANGUAGE_PREFERRED",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_MARITAL_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_MARITAL_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_NATIONALITY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INDI_NATIONALITY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_RACE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INDI_RACE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_RELIGION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_RELIGION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_DATE_OF_REGISTRATION",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "ORG_DATE_OF_REGISTRATION",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_INDUSTRY_CATEGORY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_INDUSTRY_CATEGORY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_LEGAL_STATUS",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_LEGAL_STATUS",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_ORGANIZATION_ID_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ORG_ORGANIZATION_ID_NUMBER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_ORGANIZATION_ID_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ORG_ORGANIZATION_ID_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_REGISTRATION_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ORG_REGISTRATION_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PRIMARY_ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PRIMARY_ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PRIMARY_CONTACT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PRIMARY_CONTACT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_CONTACT_PERSON_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_CONTACT_PERSON_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_CONTACT_PERSON_ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_CONTACT_PERSON_ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_CONTACT_PERSON_CONTACT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_CONTACT_PERSON_CONTACT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
                            "name": "ORG_PARENT_ORG_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_PARENT_ORG_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "USER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_ORG_PARTY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_ORG_PARTY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_NATIONALITY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_NATIONALITY_CODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RECORD_USAGE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RECORD_USAGE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "VERSION_SEQ",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "VERSION_SEQ",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYMENT_METHOD_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PAYMENT_METHOD_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DESCRIPTION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DESCRIPTION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VEN_JOINT_VENTURE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VEN_JOINT_VENTURE_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "GROUP_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "GROUP_ID",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INDI_SUPERVISOR_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INDI_SUPERVISOR_ID",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_REF_NO_REP",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_REF_NO_REP",
                            "type": "String",
                            "physicalType": "nvarchar"
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