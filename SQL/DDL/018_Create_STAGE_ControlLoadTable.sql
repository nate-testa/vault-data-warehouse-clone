CREATE TABLE [edw_stage].[ControlLoadTable](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SourceObjectSettings] [nvarchar](max) NULL,
	[SourceConnectionSettingsName] [nvarchar](max) NULL,
	[CopySourceSettings] [nvarchar](max) NULL,
	[SinkObjectSettings] [nvarchar](max) NULL,
	[SinkConnectionSettingsName] [nvarchar](max) NULL,
	[CopySinkSettings] [nvarchar](max) NULL,
	[CopyActivitySettings] [nvarchar](max) NULL,
	[TopLevelPipelineName] [nvarchar](max) NULL,
	[TriggerName] [nvarchar](max) NULL,
	[DataLoadingBehaviorSettings] [nvarchar](max) NULL,
	[LastExecution] [nvarchar](max) NULL,
	[CustomScript] [nvarchar](max) NULL,
	[TaskId] [int] NULL,
	[CopyEnabled] [bit] NULL
);


SET IDENTITY_INSERT [edw_stage].[ControlLoadTable] ON;

INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (211, N'{
            "schema": "dbo",
            "table": "__EFMigrationsHistory"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[__EFMigrationsHistory]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "__EFMigrationsHistory"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "MigrationId"
                ]
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "MigrationId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MigrationId",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ProductVersion",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ProductVersion",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (340, N'{
            "tableName": "t_clm_note"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_note"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "NOTE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "NOTE_ID",
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
                            "name": "NOTE_SUBJECT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_SUBJECT",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTE_CONTENT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_CONTENT",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTE_CATEGORY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_CATEGORY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SEND_MESSAGE_TO",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SEND_MESSAGE_TO",
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTE_LEVEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_LEVEL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTE_USER_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_USER_TYPE",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTE_OVERVIEW",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NOTE_OVERVIEW",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (341, N'{
            "tableName": "t_clm_object"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_object"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
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
                            "name": "CLAIMANT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CLAIMANT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIMANT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIMANT_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DRIVER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBCLAIM_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBCLAIM_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RISK_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RISK_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_SEVERITY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_SEVERITY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OBJECT_PLACE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OBJECT_PLACE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_DESC",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_IS_INSURED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVER_IS_INSURED",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_SUBROGATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_SUBROGATION",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_SALVAGE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_SALVAGE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_USER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "APPRAISAL_USER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "APPRAISAL_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_APPROVER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "APPRAISAL_APPROVER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_APPROVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "APPRAISAL_APPROVE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "LAST_DOC_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LAST_DOC_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "RECEIVED_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "RECEIVED_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "WORKSHOP_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "WORKSHOP_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PLACETOGO_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PLACETOGO_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FRAUD_SCORE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "FRAUD_SCORE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SEQ_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SEQ_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TOTAL_LOSS_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TOTAL_LOSS_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SALVAGE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SALVAGE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_OWNER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CAR_OWNER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OWNER_ID",
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "LITIGATION_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LITIGATION_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ASSIGN_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OWNER_ASSIGN_BY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ASSIGN_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "OWNER_ASSIGN_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "ESTIMATED_LOSS_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ESTIMATED_LOSS_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ESTIMATED_LOSS_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ESTIMATED_LOSS_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_CAR_SERVICE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RENTAL_CAR_SERVICE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_CAR_COMPANY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RENTAL_CAR_COMPANY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_RENTAL_TOWN",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CAR_RENTAL_TOWN",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DAILY_RENTAL_FEE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DAILY_RENTAL_FEE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_PERIOD",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RENTAL_PERIOD",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TOTAL_RENTAL_FEE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TOTAL_RENTAL_FEE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "COMPANY_CARE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COMPANY_CARE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_PROVIDER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CARE_PROVIDER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_CALL_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CARE_CALL_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_SERVICE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CARE_SERVICE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_OPERATOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CARE_OPERATOR",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURANCE_COMPANY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURANCE_COMPANY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVER_REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DRIVER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TP_DRIVER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DRIVER_BIRTH_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "TP_DRIVER_BIRTH_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_PLATE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_PLATE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_TEL_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_TEL_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID_ONE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID_ONE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID_TWO",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID_TWO",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SEVERITY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SEVERITY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_CLASS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BUSINESS_CLASS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (212, N'{
            "schema": "dbo",
            "table": "Account"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Account"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"PrimaryInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PrimaryInsuredId","type":"Guid"}},{"source":{"name":"UnderwriterUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UnderwriterUserId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"BrokerId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerId","type":"Guid"}},{"source":{"name":"Stage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Stage","type":"String"}},{"source":{"name":"State","type":"String","physicalType":"nvarchar"},"sink":{"name":"State","type":"String"}},{"source":{"name":"ReferralState","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReferralState","type":"String"}},{"source":{"name":"IsPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsPolicyChange","type":"Boolean"}},{"source":{"name":"IsRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewal","type":"Boolean"}},{"source":{"name":"MustClear","type":"Boolean","physicalType":"bit"},"sink":{"name":"MustClear","type":"Boolean"}},{"source":{"name":"Number","type":"Int32","physicalType":"int"},"sink":{"name":"Number","type":"Int32"}},{"source":{"name":"PolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyNumber","type":"String"}},{"source":{"name":"RenewalOfPolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"RenewalOfPolicyNumber","type":"String"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"TransactionEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"TransactionEffectiveDate","type":"DateTime"}},{"source":{"name":"RateDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"RateDate","type":"DateTime"}},{"source":{"name":"MinimumEarnedPremiumPercent","type":"Int32","physicalType":"int"},"sink":{"name":"MinimumEarnedPremiumPercent","type":"Int32"}},{"source":{"name":"IsCreatingFromOcr","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsCreatingFromOcr","type":"Boolean"}},{"source":{"name":"MustRate","type":"Boolean","physicalType":"bit"},"sink":{"name":"MustRate","type":"Boolean"}},{"source":{"name":"ChangeOccuredSinceLastTransaction","type":"Boolean","physicalType":"bit"},"sink":{"name":"ChangeOccuredSinceLastTransaction","type":"Boolean"}},{"source":{"name":"RiskStateCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"RiskStateCode","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"FailedClearance","type":"Boolean","physicalType":"bit"},"sink":{"name":"FailedClearance","type":"Boolean"}},{"source":{"name":"RateServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RateServiceName","type":"String"}},{"source":{"name":"RuleServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RuleServiceName","type":"String"}},{"source":{"name":"RiskStateCodeSet","type":"Boolean","physicalType":"bit"},"sink":{"name":"RiskStateCodeSet","type":"Boolean"}},{"source":{"name":"RulesReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"RulesReferenceUrl","type":"String"}},{"source":{"name":"FormReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormReferenceUrl","type":"String"}},{"source":{"name":"FormServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormServiceName","type":"String"}},{"source":{"name":"CoInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CoInsuredId","type":"Guid"}},{"source":{"name":"NewBrokerId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"NewBrokerId","type":"Guid"}},{"source":{"name":"NewBrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"NewBrokerageId","type":"Guid"}},{"source":{"name":"NotificationBrokerId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"NotificationBrokerId","type":"Guid"}},{"source":{"name":"RelatedAccountsId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"RelatedAccountsId","type":"Guid"}},{"source":{"name":"CopyOfAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CopyOfAccountId","type":"Guid"}},{"source":{"name":"CloseReasonType","type":"String","physicalType":"nvarchar"},"sink":{"name":"CloseReasonType","type":"String"}},{"source":{"name":"RoundPremiumToNearestDollar","type":"Boolean","physicalType":"bit"},"sink":{"name":"RoundPremiumToNearestDollar","type":"Boolean"}},{"source":{"name":"BillingAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillingAccountId","type":"Guid"}},{"source":{"name":"IsReviseBinder","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReviseBinder","type":"Boolean"}},{"source":{"name":"ExternalSourceGroupId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceGroupId","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"NonRenewalState","type":"String","physicalType":"nvarchar"},"sink":{"name":"NonRenewalState","type":"String"}},{"source":{"name":"InitialRenewalOfPolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"InitialRenewalOfPolicyNumber","type":"String"}},{"source":{"name":"IsRenewed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewed","type":"Boolean"}},{"source":{"name":"RenewalIndex","type":"Int32","physicalType":"int"},"sink":{"name":"RenewalIndex","type":"Int32"}},{"source":{"name":"BillToType","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillToType","type":"String"}},{"source":{"name":"RenewalStatus","type":"String","physicalType":"nvarchar"},"sink":{"name":"RenewalStatus","type":"String"}},{"source":{"name":"RenewalAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"RenewalAccountId","type":"Guid"}},{"source":{"name":"CancellationNoticeCancellationEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CancellationNoticeCancellationEffectiveDate","type":"DateTime"}},{"source":{"name":"IsRenewalLapsePending","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewalLapsePending","type":"Boolean"}},{"source":{"name":"IsUnderCancellationNotice","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsUnderCancellationNotice","type":"Boolean"}},{"source":{"name":"RenewalLapsePendingAsOfDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"RenewalLapsePendingAsOfDate","type":"DateTime"}},{"source":{"name":"MustCheckForms","type":"Boolean","physicalType":"bit"},"sink":{"name":"MustCheckForms","type":"Boolean"}},{"source":{"name":"MustCheckRules","type":"Boolean","physicalType":"bit"},"sink":{"name":"MustCheckRules","type":"Boolean"}},{"source":{"name":"Program","type":"String","physicalType":"nvarchar"},"sink":{"name":"Program","type":"String"}},{"source":{"name":"CancellationRequestedEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CancellationRequestedEffectiveDate","type":"DateTime"}},{"source":{"name":"CancellationRequestedReason","type":"String","physicalType":"nvarchar"},"sink":{"name":"CancellationRequestedReason","type":"String"}},{"source":{"name":"IsCancellationRequested","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsCancellationRequested","type":"Boolean"}},{"source":{"name":"OriginalEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"OriginalEffectiveDate","type":"DateTime"}},{"source":{"name":"CopyOfAccountNumber","type":"Int32","physicalType":"int"},"sink":{"name":"CopyOfAccountNumber","type":"Int32"}},{"source":{"name":"RenewalOfAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"RenewalOfAccountId","type":"Guid"}},{"source":{"name":"IsReviseQuote","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReviseQuote","type":"Boolean"}},{"source":{"name":"ReviseQuoteTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ReviseQuoteTransactionId","type":"Guid"}},{"source":{"name":"IsCopiedFromRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsCopiedFromRenewal","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:12:28.8468825"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-1"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (213, N'{
            "schema": "dbo",
            "table": "AccountActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:14:37.0777177"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:41"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (347, N'{
            "tableName": "t_clm_settle_item"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_settle_item"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "SETTLE_ITEM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_ITEM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_PAYEE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_PAYEE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLEMENT_ITEM_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLEMENT_ITEM_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ITEM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ITEM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYMENT_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYMENT_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PAY_FINAL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAY_FINAL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLE_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RESERVE_SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOCAL_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LOCAL_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LOCAL_SETTLE_AMOUNT",
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
                            "name": "DYNAMIC_FIELDS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DYNAMIC_FIELDS",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "TAX_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TAX_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TAX_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TAX_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TAX_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TAX_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "GST_CAL_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "GST_CAL_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "GST_RECOVERABLE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "GST_RECOVERABLE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "GST_PAYABLE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "GST_PAYABLE",
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (214, N'{
            "schema": "dbo",
            "table": "AccountBillingPreference"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountBillingPreference"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"BillToType","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillToType","type":"String"}},{"source":{"name":"IsFinanced","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFinanced","type":"Boolean"}},{"source":{"name":"FinanceCompanyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FinanceCompanyName","type":"String"}},{"source":{"name":"BillToMortgageeId","type":"Int32","physicalType":"int"},"sink":{"name":"BillToMortgageeId","type":"Int32"}},{"source":{"name":"PaymentPlan","type":"String","physicalType":"nvarchar"},"sink":{"name":"PaymentPlan","type":"String"}},{"source":{"name":"ContactType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactType","type":"String"}},{"source":{"name":"ContactInfoIsInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"ContactInfoIsInsured","type":"Boolean"}},{"source":{"name":"ContactEntityName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactEntityName","type":"String"}},{"source":{"name":"ContactPrefix","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactPrefix","type":"String"}},{"source":{"name":"ContactFirstName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactFirstName","type":"String"}},{"source":{"name":"ContactMiddleName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactMiddleName","type":"String"}},{"source":{"name":"ContactLastName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactLastName","type":"String"}},{"source":{"name":"ContactSuffix","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactSuffix","type":"String"}},{"source":{"name":"ContactPhone","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactPhone","type":"String"}},{"source":{"name":"ContactEmail","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactEmail","type":"String"}},{"source":{"name":"BillingAddressIsMailingAddress","type":"Boolean","physicalType":"bit"},"sink":{"name":"BillingAddressIsMailingAddress","type":"Boolean"}},{"source":{"name":"BillingAddressLine1","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressLine1","type":"String"}},{"source":{"name":"BillingAddressLine2","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressLine2","type":"String"}},{"source":{"name":"BillingAddressCity","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressCity","type":"String"}},{"source":{"name":"BillingAddressState","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressState","type":"String"}},{"source":{"name":"BillingAddressZipCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressZipCode","type":"String"}},{"source":{"name":"BillingAddressCounty","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressCounty","type":"String"}},{"source":{"name":"BillingAddressCountry","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressCountry","type":"String"}},{"source":{"name":"BillingAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillingAccountId","type":"Guid"}},{"source":{"name":"BillToBrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillToBrokerageId","type":"Guid"}},{"source":{"name":"IsNewBillingAccount","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsNewBillingAccount","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"BillingAddressLineUnit","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillingAddressLineUnit","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:17:02.8506767"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:35"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (215, N'{
            "schema": "dbo",
            "table": "AccountChange"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountChange"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ObjectGroupIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectGroupIdentifier","type":"String"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"PreviousValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousValue","type":"String"}},{"source":{"name":"CurrentValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"CurrentValue","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CurrentValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"CurrentValueFormatted","type":"String"}},{"source":{"name":"IgnoreChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IgnoreChange","type":"Boolean"}},{"source":{"name":"PreviousValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousValueFormatted","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T14:02:36.835303"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:07"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (350, N'{
            "tableName": "t_dd_busi_data_table_record"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_dd_busi_data_table_record"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "RECORD_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RECORD_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DATA_TABLE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DATA_TABLE_ID",
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
                            "physicalType": "text"
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
                            "name": "INSERT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INSERT_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
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
                            "name": "BUSINESS_OBJECT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "BUSINESS_OBJECT_ID",
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (216, N'{
            "schema": "dbo",
            "table": "AccountDocument"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountDocument"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"DocumentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"DocumentId","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-09T19:23:56.212149"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:25"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (217, N'{
            "schema": "dbo",
            "table": "AccountDocumentDelivery"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountDocumentDelivery"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"SendOnlyToBroker","type":"Boolean","physicalType":"bit"},"sink":{"name":"SendOnlyToBroker","type":"Boolean"}},{"source":{"name":"EmailPrimaryInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"EmailPrimaryInsured","type":"Boolean"}},{"source":{"name":"MailPrimaryInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"MailPrimaryInsured","type":"Boolean"}},{"source":{"name":"EmaiCoInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"EmaiCoInsured","type":"Boolean"}},{"source":{"name":"MailCoInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"MailCoInsured","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-10T09:08:04.43288"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:25"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (218, N'{
            "schema": "dbo",
            "table": "AccountDocumentDeliveryRecipient"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountDocumentDeliveryRecipient"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"FullName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FullName","type":"String"}},{"source":{"name":"DeliveryPreference","type":"String","physicalType":"nvarchar"},"sink":{"name":"DeliveryPreference","type":"String"}},{"source":{"name":"Email","type":"String","physicalType":"nvarchar"},"sink":{"name":"Email","type":"String"}},{"source":{"name":"MailingAddressLine1","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressLine1","type":"String"}},{"source":{"name":"MailingAddressLine2","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressLine2","type":"String"}},{"source":{"name":"MailingAddressCity","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressCity","type":"String"}},{"source":{"name":"MailingAddressState","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressState","type":"String"}},{"source":{"name":"MailingAddressZipCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressZipCode","type":"String"}},{"source":{"name":"MailingAddressCounty","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressCounty","type":"String"}},{"source":{"name":"MailingAddressCountry","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressCountry","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"MailingAddressLineUnit","type":"String","physicalType":"nvarchar"},"sink":{"name":"MailingAddressLineUnit","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-07-28T19:20:30.6910304"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:14"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (219, N'{
            "schema": "dbo",
            "table": "AccountEligibilityQuestion"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountEligibilityQuestion"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Question","type":"String","physicalType":"nvarchar"},"sink":{"name":"Question","type":"String"}},{"source":{"name":"Parent","type":"String","physicalType":"nvarchar"},"sink":{"name":"Parent","type":"String"}},{"source":{"name":"ParentTriggerAnswer","type":"String","physicalType":"nvarchar"},"sink":{"name":"ParentTriggerAnswer","type":"String"}},{"source":{"name":"Answer","type":"String","physicalType":"nvarchar"},"sink":{"name":"Answer","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-10T09:08:04.7128465"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:13"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (220, N'{
            "schema": "dbo",
            "table": "AccountForm"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountForm"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"Number","type":"String","physicalType":"nvarchar"},"sink":{"name":"Number","type":"String"}},{"source":{"name":"Edition","type":"String","physicalType":"nvarchar"},"sink":{"name":"Edition","type":"String"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"FormType","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormType","type":"String"}},{"source":{"name":"IsRemoved","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRemoved","type":"Boolean"}},{"source":{"name":"IsRemovedByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"IsRemovedByUserId","type":"Guid"}},{"source":{"name":"IsAddedByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"IsAddedByUserId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"DocumentType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DocumentType","type":"String"}},{"source":{"name":"IsAttached","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttached","type":"Boolean"}},{"source":{"name":"IsOptional","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsOptional","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IsAttachedToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttachedToPolicyChange","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.4066725"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:18"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (221, N'{
            "schema": "dbo",
            "table": "AccountInsight"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountInsight"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"AccountObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountObjectId","type":"Int32"}},{"source":{"name":"Category","type":"String","physicalType":"nvarchar"},"sink":{"name":"Category","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"ValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"ValueFormatted","type":"String"}},{"source":{"name":"Highlight","type":"Boolean","physicalType":"bit"},"sink":{"name":"Highlight","type":"Boolean"}},{"source":{"name":"InternalUserOnly","type":"Boolean","physicalType":"bit"},"sink":{"name":"InternalUserOnly","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-07-07T15:29:05.2557238"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:14"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (222, N'{
            "schema": "dbo",
            "table": "AccountInvoice"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountInvoice"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"UniqueTransactionId","type":"String","physicalType":"nvarchar"},"sink":{"name":"UniqueTransactionId","type":"String"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"PrimaryInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PrimaryInsuredId","type":"Guid"}},{"source":{"name":"TransactionType","type":"String","physicalType":"nvarchar"},"sink":{"name":"TransactionType","type":"String"}},{"source":{"name":"AccountingEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"AccountingEffectiveDate","type":"DateTime"}},{"source":{"name":"TransactionEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"TransactionEffectiveDate","type":"DateTime"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"DueDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"DueDate","type":"DateTime"}},{"source":{"name":"RiskStateCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"RiskStateCode","type":"String"}},{"source":{"name":"TotalPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPremium","type":"Decimal"}},{"source":{"name":"TotalReceivable","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalReceivable","type":"Decimal"}},{"source":{"name":"TotalPayable","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPayable","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"CommissionAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionAmount","type":"Decimal"}},{"source":{"name":"TotalFees","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalFees","type":"Decimal"}},{"source":{"name":"TotalTaxes","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalTaxes","type":"Decimal"}},{"source":{"name":"Product","type":"String","physicalType":"nvarchar"},"sink":{"name":"Product","type":"String"}},{"source":{"name":"BrokerageCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"BrokerageCode","type":"String"}},{"source":{"name":"BrokerageName","type":"String","physicalType":"nvarchar"},"sink":{"name":"BrokerageName","type":"String"}},{"source":{"name":"IsReversal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversal","type":"Boolean"}},{"source":{"name":"IsReversed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversed","type":"Boolean"}},{"source":{"name":"ReversalOfId","type":"Int32","physicalType":"int"},"sink":{"name":"ReversalOfId","type":"Int32"}},{"source":{"name":"NumberOfInstallments","type":"Int32","physicalType":"int"},"sink":{"name":"NumberOfInstallments","type":"Int32"}},{"source":{"name":"DownPaymentAmount","type":"Int32","physicalType":"int"},"sink":{"name":"DownPaymentAmount","type":"Int32"}},{"source":{"name":"InvoiceDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"InvoiceDate","type":"DateTime"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"BillingAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillingAccountId","type":"Guid"}},{"source":{"name":"BrokerageReferenceCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"BrokerageReferenceCode","type":"String"}},{"source":{"name":"ProductCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductCode","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:59:02.5707821"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:05"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (223, N'{
            "schema": "dbo",
            "table": "AccountInvoiceLineItem"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountInvoiceLineItem"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountInvoiceId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountInvoiceId","type":"Int32"}},{"source":{"name":"Amount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Amount","type":"Decimal"}},{"source":{"name":"ReceivableAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"ReceivableAmount","type":"Decimal"}},{"source":{"name":"PayableAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"PayableAmount","type":"Decimal"}},{"source":{"name":"PayableToType","type":"String","physicalType":"nvarchar"},"sink":{"name":"PayableToType","type":"String"}},{"source":{"name":"ReceivableFromType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReceivableFromType","type":"String"}},{"source":{"name":"NetAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetAmount","type":"Decimal"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"AsLob","type":"String","physicalType":"nvarchar"},"sink":{"name":"AsLob","type":"String"}},{"source":{"name":"FinancialCoverageId","type":"String","physicalType":"nvarchar"},"sink":{"name":"FinancialCoverageId","type":"String"}},{"source":{"name":"FinancialCoverageName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FinancialCoverageName","type":"String"}},{"source":{"name":"Category","type":"String","physicalType":"nvarchar"},"sink":{"name":"Category","type":"String"}},{"source":{"name":"SubCategory","type":"String","physicalType":"nvarchar"},"sink":{"name":"SubCategory","type":"String"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"CommissionAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionAmount","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:59:02.5707757"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:18"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (224, N'{
            "schema": "dbo",
            "table": "AccountIssue"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountIssue"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "IssueId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "IssueId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferralLevel",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "ReferralLevel",
                            "type": "Int32"
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
                            "name": "ExternalMessage",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalMessage",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CanRefer",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "CanRefer",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsApproved",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsApproved",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsRiskAppetite",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsRiskAppetite",
                            "type": "Boolean"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.3916467"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:48"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (225, N'{
            "schema": "dbo",
            "table": "AccountObject"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountObject"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"ParentObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ParentObjectId","type":"Int32"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"ObjectGroupIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectGroupIdentifier","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"MaxAllowed","type":"Int32","physicalType":"int"},"sink":{"name":"MaxAllowed","type":"Int32"}},{"source":{"name":"IsForm","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsForm","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"TableIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"TableIdentifier","type":"String"}},{"source":{"name":"UniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UniqueId","type":"Guid"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"IsDeletedOnPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsDeletedOnPolicyChange","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.9406083"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (226, N'{
            "schema": "dbo",
            "table": "AccountObjectField"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountObjectField"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"DataType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DataType","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"IsEncrypted","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsEncrypted","type":"Boolean"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"IsHidden","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsHidden","type":"Boolean"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"IsDisabled","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsDisabled","type":"Boolean"}},{"source":{"name":"IsPostBindDisable","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsPostBindDisable","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IgnorePolicyChangeTracking","type":"Boolean","physicalType":"bit"},"sink":{"name":"IgnorePolicyChangeTracking","type":"Boolean"}},{"source":{"name":"IsOverrideByUser","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsOverrideByUser","type":"Boolean"}},{"source":{"name":"OverrideByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"OverrideByUserId","type":"Guid"}},{"source":{"name":"ReferenceObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ReferenceObjectId","type":"Int32"}},{"source":{"name":"ReferenceObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReferenceObjectType","type":"String"}},{"source":{"name":"ShowOnReferencedField","type":"Boolean","physicalType":"bit"},"sink":{"name":"ShowOnReferencedField","type":"Boolean"}},{"source":{"name":"IsManualSave","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsManualSave","type":"Boolean"}},{"source":{"name":"ManualSaveGroup","type":"String","physicalType":"nvarchar"},"sink":{"name":"ManualSaveGroup","type":"String"}},{"source":{"name":"ManualSaveLabel","type":"String","physicalType":"nvarchar"},"sink":{"name":"ManualSaveLabel","type":"String"}},{"source":{"name":"IsMaskedExternally","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsMaskedExternally","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.9412401"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:41"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (227, N'{
            "schema": "dbo",
            "table": "AccountPayment"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPayment"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"PrimaryInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PrimaryInsuredId","type":"Guid"}},{"source":{"name":"PaymentFrom","type":"String","physicalType":"nvarchar"},"sink":{"name":"PaymentFrom","type":"String"}},{"source":{"name":"Amount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Amount","type":"Decimal"}},{"source":{"name":"PaidVia","type":"String","physicalType":"nvarchar"},"sink":{"name":"PaidVia","type":"String"}},{"source":{"name":"PaymentDateTime","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"PaymentDateTime","type":"DateTime"}},{"source":{"name":"IsReversed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversed","type":"Boolean"}},{"source":{"name":"IsReversal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversal","type":"Boolean"}},{"source":{"name":"ReversalOfId","type":"Int32","physicalType":"int"},"sink":{"name":"ReversalOfId","type":"Int32"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"BillingAccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillingAccountId","type":"Guid"}},{"source":{"name":"ReferenceCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReferenceCode","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-08T09:42:37.3296697"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:35"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (228, N'{
            "schema": "dbo",
            "table": "AccountPremium"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremium"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"TotalPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPremium","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"CommissionAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionAmount","type":"Decimal"}},{"source":{"name":"NetPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetPremium","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"SummaryDisplayType","type":"String","physicalType":"nvarchar"},"sink":{"name":"SummaryDisplayType","type":"String"}},{"source":{"name":"GrossPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremium","type":"Decimal"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CommissionPercentOverride","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercentOverride","type":"Decimal"}},{"source":{"name":"CommissionPercentOverrideByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CommissionPercentOverrideByUserId","type":"Guid"}},{"source":{"name":"CommissionPercentOverrideRetention","type":"String","physicalType":"nvarchar"},"sink":{"name":"CommissionPercentOverrideRetention","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6297627"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:05"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (229, N'{
            "schema": "dbo",
            "table": "AccountPremiumCoverage"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumCoverage"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Premium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Premium","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AsLob","type":"String","physicalType":"nvarchar"},"sink":{"name":"AsLob","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Commission","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Commission","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}},{"source":{"name":"CededPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CededPremium","type":"Decimal"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.9761688"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-3"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (230, N'{
            "schema": "dbo",
            "table": "AccountPremiumFactor"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumFactor"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"RaterIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterIdentifier","type":"String"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Factor","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Factor","type":"Decimal"}},{"source":{"name":"FactorMin","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"FactorMin","type":"Decimal"}},{"source":{"name":"FactorMax","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"FactorMax","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CustomName","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomName","type":"String"}},{"source":{"name":"FactorMethod","type":"String","physicalType":"nvarchar"},"sink":{"name":"FactorMethod","type":"String"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"CustomId","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomId","type":"String"}},{"source":{"name":"Reason","type":"String","physicalType":"nvarchar"},"sink":{"name":"Reason","type":"String"}},{"source":{"name":"Retention","type":"String","physicalType":"nvarchar"},"sink":{"name":"Retention","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6348044"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:06"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (231, N'{
            "schema": "dbo",
            "table": "AccountPremiumRaterReference"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumRaterReference"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"ProductInternalName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductInternalName","type":"String"}},{"source":{"name":"RaterReferenceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterReferenceId","type":"String"}},{"source":{"name":"RaterReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterReferenceUrl","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Extension","type":"String","physicalType":"nvarchar"},"sink":{"name":"Extension","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6528927"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-1"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (232, N'{
            "schema": "dbo",
            "table": "AccountPremiumSummary"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumSummary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ValueAsNumber","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"ValueAsNumber","type":"Decimal"}},{"source":{"name":"CustomName","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomName","type":"String"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6365432"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:10"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (233, N'{
            "schema": "dbo",
            "table": "AccountPremiumTaxAndFee"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumTaxAndFee"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"Type","type":"String","physicalType":"nvarchar"},"sink":{"name":"Type","type":"String"}},{"source":{"name":"Amount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Amount","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AppliesToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"AppliesToPolicyChange","type":"Boolean"}},{"source":{"name":"IsFullyEarned","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFullyEarned","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6543752"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (316, N'{
            "schema": "dbo",
            "table": "BrokerageBankingDetailCommissionStatementEmail"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageBankingDetailCommissionStatementEmail"
        }', NULL, N'{
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
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "Email",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Email",
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
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Manual"
        ]', N'{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-08T14:45:22.8801802"
        }', N'{              "LastExecutionDate": "2023-09-26T18:15:58.752896Z",              "LastExecutionTime": "00:01:34"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (234, N'{
            "schema": "dbo",
            "table": "AccountPremiumTransactionSummary"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountPremiumTransactionSummary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountPremiumId","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:08.6370067"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:30"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (235, N'{
            "schema": "dbo",
            "table": "AccountReport"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountReport"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"DateOrdered","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"DateOrdered","type":"DateTime"}},{"source":{"name":"DateTimeRecieved","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"DateTimeRecieved","type":"DateTime"}},{"source":{"name":"DateTimeCompleted","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"DateTimeCompleted","type":"DateTime"}},{"source":{"name":"ReportType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReportType","type":"String"}},{"source":{"name":"Reference","type":"String","physicalType":"nvarchar"},"sink":{"name":"Reference","type":"String"}},{"source":{"name":"TransactionReferenceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"TransactionReferenceId","type":"String"}},{"source":{"name":"RequestRaw","type":"String","physicalType":"nvarchar"},"sink":{"name":"RequestRaw","type":"String"}},{"source":{"name":"ResponseRaw","type":"String","physicalType":"nvarchar"},"sink":{"name":"ResponseRaw","type":"String"}},{"source":{"name":"TransactionStatus","type":"String","physicalType":"nvarchar"},"sink":{"name":"TransactionStatus","type":"String"}},{"source":{"name":"Source","type":"String","physicalType":"nvarchar"},"sink":{"name":"Source","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReferenceUrl","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AutoOrder","type":"Boolean","physicalType":"bit"},"sink":{"name":"AutoOrder","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:35.8015094"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:04"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (236, N'{
            "schema": "dbo",
            "table": "AccountReportItem"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountReportItem"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"ReportId","type":"Int32","physicalType":"int"},"sink":{"name":"ReportId","type":"Int32"}},{"source":{"name":"Category","type":"String","physicalType":"nvarchar"},"sink":{"name":"Category","type":"String"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"ValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"ValueFormatted","type":"String"}},{"source":{"name":"Path","type":"String","physicalType":"nvarchar"},"sink":{"name":"Path","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"Highlight","type":"Boolean","physicalType":"bit"},"sink":{"name":"Highlight","type":"Boolean"}},{"source":{"name":"FieldFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"FieldFormatted","type":"String"}},{"source":{"name":"IsUsed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsUsed","type":"Boolean"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ValueMapped","type":"String","physicalType":"nvarchar"},"sink":{"name":"ValueMapped","type":"String"}},{"source":{"name":"RelatedObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"RelatedObjectId","type":"Int32"}},{"source":{"name":"DataName","type":"String","physicalType":"nvarchar"},"sink":{"name":"DataName","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:35.801509"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-5"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (237, N'{
            "schema": "dbo",
            "table": "AccountSubjectivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountSubjectivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Required",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Required",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Description",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Description",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IsCompleted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsCompleted",
                            "type": "Boolean"
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
                            "name": "Index",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "Index",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "IsSignaturePackage",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsSignaturePackage",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsUploadRequired",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsUploadRequired",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsSignatureDocument",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsSignatureDocument",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "UploadedDocumentId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "UploadedDocumentId",
                            "type": "Guid"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-04T08:33:25.8329982"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:18"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (238, N'{
            "schema": "dbo",
            "table": "AccountTransaction"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransaction"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"Stage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Stage","type":"String"}},{"source":{"name":"State","type":"String","physicalType":"nvarchar"},"sink":{"name":"State","type":"String"}},{"source":{"name":"Number","type":"Int32","physicalType":"int"},"sink":{"name":"Number","type":"Int32"}},{"source":{"name":"PolicyChangeNumber","type":"Int32","physicalType":"int"},"sink":{"name":"PolicyChangeNumber","type":"Int32"}},{"source":{"name":"TransactionEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"TransactionEffectiveDate","type":"DateTime"}},{"source":{"name":"ProRateFactor","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"ProRateFactor","type":"Decimal"}},{"source":{"name":"MinimumEarnedPremiumPercent","type":"Int32","physicalType":"int"},"sink":{"name":"MinimumEarnedPremiumPercent","type":"Int32"}},{"source":{"name":"TotalPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPremium","type":"Decimal"}},{"source":{"name":"GrossPremiumOverride","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremiumOverride","type":"Decimal"}},{"source":{"name":"GrossPremiumDeltaProRatedOverride","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremiumDeltaProRatedOverride","type":"Decimal"}},{"source":{"name":"NetPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetPremium","type":"Decimal"}},{"source":{"name":"Commission","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Commission","type":"Decimal"}},{"source":{"name":"GrossPremiumDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremiumDeltaProRated","type":"Decimal"}},{"source":{"name":"NetPremiumDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetPremiumDeltaProRated","type":"Decimal"}},{"source":{"name":"CommissionDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionDeltaProRated","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"Cleared","type":"Boolean","physicalType":"bit"},"sink":{"name":"Cleared","type":"Boolean"}},{"source":{"name":"Referred","type":"Boolean","physicalType":"bit"},"sink":{"name":"Referred","type":"Boolean"}},{"source":{"name":"IsLatestBoundTransaction","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsLatestBoundTransaction","type":"Boolean"}},{"source":{"name":"IsHidden","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsHidden","type":"Boolean"}},{"source":{"name":"Note","type":"String","physicalType":"nvarchar"},"sink":{"name":"Note","type":"String"}},{"source":{"name":"NotTakenReason","type":"String","physicalType":"nvarchar"},"sink":{"name":"NotTakenReason","type":"String"}},{"source":{"name":"CancellationReason","type":"String","physicalType":"nvarchar"},"sink":{"name":"CancellationReason","type":"String"}},{"source":{"name":"PolicyChangeNotes","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyChangeNotes","type":"String"}},{"source":{"name":"BindDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"BindDate","type":"DateTime"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"GrossPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremium","type":"Decimal"}},{"source":{"name":"PreBindComplete","type":"Boolean","physicalType":"bit"},"sink":{"name":"PreBindComplete","type":"Boolean"}},{"source":{"name":"ReferredByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ReferredByUserId","type":"Guid"}},{"source":{"name":"SubmitById","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"SubmitById","type":"Guid"}},{"source":{"name":"CreatedById","type":"String","physicalType":"nvarchar"},"sink":{"name":"CreatedById","type":"String"}},{"source":{"name":"ReviewedById","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ReviewedById","type":"Guid"}},{"source":{"name":"ApproveNote","type":"String","physicalType":"nvarchar"},"sink":{"name":"ApproveNote","type":"String"}},{"source":{"name":"DenyNote","type":"String","physicalType":"nvarchar"},"sink":{"name":"DenyNote","type":"String"}},{"source":{"name":"IsRevision","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRevision","type":"Boolean"}},{"source":{"name":"QuoteNote","type":"String","physicalType":"nvarchar"},"sink":{"name":"QuoteNote","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"TotalPremiumDeltaProRated","type":"Decimal","physicalType":"decimal","scale":2,"precision":18},"sink":{"name":"TotalPremiumDeltaProRated","type":"Decimal"}},{"source":{"name":"CommissionDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionDelta","type":"Decimal"}},{"source":{"name":"GrossPremiumDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremiumDelta","type":"Decimal"}},{"source":{"name":"NetPremiumDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetPremiumDelta","type":"Decimal"}},{"source":{"name":"TotalPremiumDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPremiumDelta","type":"Decimal"}},{"source":{"name":"SubmitToBindById","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"SubmitToBindById","type":"Guid"}},{"source":{"name":"PolicyChangeGeneratedNotes","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyChangeGeneratedNotes","type":"String"}},{"source":{"name":"PolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyNumber","type":"String"}},{"source":{"name":"NotTakenNote","type":"String","physicalType":"nvarchar"},"sink":{"name":"NotTakenNote","type":"String"}},{"source":{"name":"IssuedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"IssuedDate","type":"DateTime"}},{"source":{"name":"PreviousStage","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousStage","type":"String"}},{"source":{"name":"PreviousState","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousState","type":"String"}},{"source":{"name":"IsReversal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversal","type":"Boolean"}},{"source":{"name":"IsReversed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsReversed","type":"Boolean"}},{"source":{"name":"ReversalOfTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ReversalOfTransactionId","type":"Guid"}},{"source":{"name":"IsExternallySubmitted","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsExternallySubmitted","type":"Boolean"}},{"source":{"name":"TransactionReferenceCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"TransactionReferenceCode","type":"String"}},{"source":{"name":"StateUpdateDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"StateUpdateDate","type":"DateTime"}},{"source":{"name":"IsRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewal","type":"Boolean"}},{"source":{"name":"DeclineNote","type":"String","physicalType":"nvarchar"},"sink":{"name":"DeclineNote","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4018481"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:04"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (239, N'{
            "schema": "dbo",
            "table": "AccountTransactionCoveragePremium"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionCoveragePremium"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Premium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Premium","type":"Decimal"}},{"source":{"name":"PremiumDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"PremiumDeltaProRated","type":"Decimal"}},{"source":{"name":"ProRateFactor","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"ProRateFactor","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"RoundPremiumToNearestDollar","type":"Boolean","physicalType":"bit"},"sink":{"name":"RoundPremiumToNearestDollar","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AsLob","type":"String","physicalType":"nvarchar"},"sink":{"name":"AsLob","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"PremiumDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"PremiumDelta","type":"Decimal"}},{"source":{"name":"Commission","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Commission","type":"Decimal"}},{"source":{"name":"CommissionDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionDelta","type":"Decimal"}},{"source":{"name":"CommissionDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionDeltaProRated","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}},{"source":{"name":"CededPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CededPremium","type":"Decimal"}},{"source":{"name":"CededPremiumDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CededPremiumDelta","type":"Decimal"}},{"source":{"name":"CededPremiumDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CededPremiumDeltaProRated","type":"Decimal"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4018657"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:00"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (240, N'{
            "schema": "dbo",
            "table": "AccountTransactionIssue"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionIssue"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"IssueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"IssueId","type":"Guid"}},{"source":{"name":"ReferralLevel","type":"Int32","physicalType":"int"},"sink":{"name":"ReferralLevel","type":"Int32"}},{"source":{"name":"Message","type":"String","physicalType":"nvarchar"},"sink":{"name":"Message","type":"String"}},{"source":{"name":"CanRefer","type":"Boolean","physicalType":"bit"},"sink":{"name":"CanRefer","type":"Boolean"}},{"source":{"name":"IsApproved","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsApproved","type":"Boolean"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4018544"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:10"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (241, N'{
            "schema": "dbo",
            "table": "AccountTransactionSummary"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionSummary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Label",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Label",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Value",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Value",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4018707"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:08"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (242, N'{
            "schema": "dbo",
            "table": "AccountTransactionTaxAndFee"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionTaxAndFee"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"Amount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Amount","type":"Decimal"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"Type","type":"String","physicalType":"nvarchar"},"sink":{"name":"Type","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AppliesToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"AppliesToPolicyChange","type":"Boolean"}},{"source":{"name":"AmountDeltaProRated","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"AmountDeltaProRated","type":"Decimal"}},{"source":{"name":"IsFullyEarned","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFullyEarned","type":"Boolean"}},{"source":{"name":"AmountDelta","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"AmountDelta","type":"Decimal"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4018746"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (243, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersion"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersion"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"PrimaryInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PrimaryInsuredId","type":"Guid"}},{"source":{"name":"UnderwriterUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UnderwriterUserId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"BrokerId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerId","type":"Guid"}},{"source":{"name":"Stage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Stage","type":"String"}},{"source":{"name":"State","type":"String","physicalType":"nvarchar"},"sink":{"name":"State","type":"String"}},{"source":{"name":"IsRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewal","type":"Boolean"}},{"source":{"name":"Number","type":"Int32","physicalType":"int"},"sink":{"name":"Number","type":"Int32"}},{"source":{"name":"PolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyNumber","type":"String"}},{"source":{"name":"RenewalOfPolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"RenewalOfPolicyNumber","type":"String"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"RateDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"RateDate","type":"DateTime"}},{"source":{"name":"RiskStateCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"RiskStateCode","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"RulesReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"RulesReferenceUrl","type":"String"}},{"source":{"name":"FormReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormReferenceUrl","type":"String"}},{"source":{"name":"CoInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CoInsuredId","type":"Guid"}},{"source":{"name":"RoundPremiumToNearestDollar","type":"Boolean","physicalType":"bit"},"sink":{"name":"RoundPremiumToNearestDollar","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"MinimumEarnedPremiumPercent","type":"Int32","physicalType":"int"},"sink":{"name":"MinimumEarnedPremiumPercent","type":"Int32"}},{"source":{"name":"InitialRenewalOfPolicyNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"InitialRenewalOfPolicyNumber","type":"String"}},{"source":{"name":"IsRenewed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRenewed","type":"Boolean"}},{"source":{"name":"NonRenewalState","type":"String","physicalType":"nvarchar"},"sink":{"name":"NonRenewalState","type":"String"}},{"source":{"name":"RenewalIndex","type":"Int32","physicalType":"int"},"sink":{"name":"RenewalIndex","type":"Int32"}},{"source":{"name":"Program","type":"String","physicalType":"nvarchar"},"sink":{"name":"Program","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"OriginalEffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"OriginalEffectiveDate","type":"DateTime"}},{"source":{"name":"IsCopiedFromRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsCopiedFromRenewal","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.409026"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:10"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (244, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionChange"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionChange"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ObjectGroupIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectGroupIdentifier","type":"String"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"PreviousValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousValue","type":"String"}},{"source":{"name":"CurrentValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"CurrentValue","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CurrentValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"CurrentValueFormatted","type":"String"}},{"source":{"name":"PreviousValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"PreviousValueFormatted","type":"String"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"IgnoreChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IgnoreChange","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:58:03.0222493"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (245, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionEligibilityQuestion"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionEligibilityQuestion"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"Question","type":"String","physicalType":"nvarchar"},"sink":{"name":"Question","type":"String"}},{"source":{"name":"Answer","type":"String","physicalType":"nvarchar"},"sink":{"name":"Answer","type":"String"}},{"source":{"name":"Parent","type":"String","physicalType":"nvarchar"},"sink":{"name":"Parent","type":"String"}},{"source":{"name":"ParentTriggerAnswer","type":"String","physicalType":"nvarchar"},"sink":{"name":"ParentTriggerAnswer","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4090484"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:15"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (246, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionForm"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionForm"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"Number","type":"String","physicalType":"nvarchar"},"sink":{"name":"Number","type":"String"}},{"source":{"name":"Edition","type":"String","physicalType":"nvarchar"},"sink":{"name":"Edition","type":"String"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"FormType","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormType","type":"String"}},{"source":{"name":"IsRemoved","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsRemoved","type":"Boolean"}},{"source":{"name":"IsRemovedByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"IsRemovedByUserId","type":"Guid"}},{"source":{"name":"IsAddedByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"IsAddedByUserId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"IsAddedOnCurrentTransaction","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAddedOnCurrentTransaction","type":"Boolean"}},{"source":{"name":"DocumentType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DocumentType","type":"String"}},{"source":{"name":"IsAttached","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttached","type":"Boolean"}},{"source":{"name":"IsOptional","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsOptional","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IsAttachedToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttachedToPolicyChange","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4090429"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:08"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (247, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionInsight"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionInsight"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"AccountObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountObjectId","type":"Int32"}},{"source":{"name":"Category","type":"String","physicalType":"nvarchar"},"sink":{"name":"Category","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"ValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"ValueFormatted","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Highlight","type":"Boolean","physicalType":"bit"},"sink":{"name":"Highlight","type":"Boolean"}},{"source":{"name":"InternalUserOnly","type":"Boolean","physicalType":"bit"},"sink":{"name":"InternalUserOnly","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-06-02T08:53:44.8206109"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:11"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (248, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionObject"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionObject"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"ParentObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ParentObjectId","type":"Int32"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ObjectGroupIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectGroupIdentifier","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"MaxAllowed","type":"Int32","physicalType":"int"},"sink":{"name":"MaxAllowed","type":"Int32"}},{"source":{"name":"IsForm","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsForm","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"TableIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"TableIdentifier","type":"String"}},{"source":{"name":"UniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UniqueId","type":"Guid"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"IsDeletedOnPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsDeletedOnPolicyChange","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4091196"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:05"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (249, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionObjectField"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionObjectField"
        }', NULL, N'{              "preCopyScript": null,              "tableOption": null,              "writeBehavior": "upsert",              "sqlWriterUseTableLock": false,              "disableMetricsCollection": false,              "upsertSettings": {                  "useTempDB": true,                  "keys": [                      "Id"                  ]              }          }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"VersionObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"VersionObjectId","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"DataType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DataType","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"IsEncrypted","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsEncrypted","type":"Boolean"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"IsHidden","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsHidden","type":"Boolean"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"IsDisabled","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsDisabled","type":"Boolean"}},{"source":{"name":"IsPostBindDisable","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsPostBindDisable","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IgnorePolicyChangeTracking","type":"Boolean","physicalType":"bit"},"sink":{"name":"IgnorePolicyChangeTracking","type":"Boolean"}},{"source":{"name":"IsOverrideByUser","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsOverrideByUser","type":"Boolean"}},{"source":{"name":"OverrideByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"OverrideByUserId","type":"Guid"}},{"source":{"name":"ReferenceObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ReferenceObjectId","type":"Int32"}},{"source":{"name":"ReferenceObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ReferenceObjectType","type":"String"}},{"source":{"name":"ShowOnReferencedField","type":"Boolean","physicalType":"bit"},"sink":{"name":"ShowOnReferencedField","type":"Boolean"}},{"source":{"name":"IsManualSave","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsManualSave","type":"Boolean"}},{"source":{"name":"ManualSaveGroup","type":"String","physicalType":"nvarchar"},"sink":{"name":"ManualSaveGroup","type":"String"}},{"source":{"name":"ManualSaveLabel","type":"String","physicalType":"nvarchar"},"sink":{"name":"ManualSaveLabel","type":"String"}},{"source":{"name":"IsMaskedExternally","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsMaskedExternally","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4091263"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT [Id]
      ,[VersionObjectId]
      ,[Label]
      ,[Field]
      ,NULLIF(TRIM([Value]),'''') AS [Value]
      ,[DataType]
      ,[CreatedDate]
      ,[UpdatedDate]
      ,[Group]
      ,[IsEncrypted]
      ,[Index]
      ,[IsHidden]
      ,[Description]
      ,[IsDisabled]
      ,[IsPostBindDisable]
      ,[ExternalSourceId]
      ,[IgnorePolicyChangeTracking]
      ,[IsOverrideByUser]
      ,[OverrideByUserId]
      ,[ReferenceObjectId]
      ,[ReferenceObjectType]
      ,[ShowOnReferencedField]
      ,[IsManualSave]
      ,[ManualSaveGroup]
      ,[ManualSaveLabel]
      ,[IsMaskedExternally] FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (250, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremium"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremium"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionId","type":"Int32"}},{"source":{"name":"TotalPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"TotalPremium","type":"Decimal"}},{"source":{"name":"CommissionAmount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionAmount","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"NetPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"NetPremium","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"GrossPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"GrossPremium","type":"Decimal"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CommissionPercentOverride","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercentOverride","type":"Decimal"}},{"source":{"name":"CommissionPercentOverrideByUserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CommissionPercentOverrideByUserId","type":"Guid"}},{"source":{"name":"CommissionPercentOverrideRetention","type":"String","physicalType":"nvarchar"},"sink":{"name":"CommissionPercentOverrideRetention","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4090491"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:04"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (251, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumCoverage"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumCoverage"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Premium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Premium","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AsLob","type":"String","physicalType":"nvarchar"},"sink":{"name":"AsLob","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Commission","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Commission","type":"Decimal"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}},{"source":{"name":"CededPremium","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CededPremium","type":"Decimal"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T18:13:22.4090663"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (252, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumFactor"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumFactor"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"RaterIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterIdentifier","type":"String"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Factor","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Factor","type":"Decimal"}},{"source":{"name":"FactorMin","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"FactorMin","type":"Decimal"}},{"source":{"name":"FactorMax","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"FactorMax","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CustomId","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomId","type":"String"}},{"source":{"name":"CustomName","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomName","type":"String"}},{"source":{"name":"FactorMethod","type":"String","physicalType":"nvarchar"},"sink":{"name":"FactorMethod","type":"String"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Reason","type":"String","physicalType":"nvarchar"},"sink":{"name":"Reason","type":"String"}},{"source":{"name":"Retention","type":"String","physicalType":"nvarchar"},"sink":{"name":"Retention","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:10:26.5359206Z",
            "LastExecutionTime": "00:01:13"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (253, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumRaterReference"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumRaterReference"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"ProductInternalName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductInternalName","type":"String"}},{"source":{"name":"RaterReferenceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterReferenceId","type":"String"}},{"source":{"name":"RaterReferenceUrl","type":"String","physicalType":"nvarchar"},"sink":{"name":"RaterReferenceUrl","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Extension","type":"String","physicalType":"nvarchar"},"sink":{"name":"Extension","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:10:26.5359206Z",
            "LastExecutionTime": "00:03:02"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (254, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumSummary"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumSummary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"Coverage","type":"String","physicalType":"nvarchar"},"sink":{"name":"Coverage","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"Group","type":"String","physicalType":"nvarchar"},"sink":{"name":"Group","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ValueAsNumber","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"ValueAsNumber","type":"Decimal"}},{"source":{"name":"CustomName","type":"String","physicalType":"nvarchar"},"sink":{"name":"CustomName","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}},{"source":{"name":"ObjectId","type":"Int32","physicalType":"int"},"sink":{"name":"ObjectId","type":"Int32"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"ObjectUniqueId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ObjectUniqueId","type":"Guid"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:10:26.5359206Z",
            "LastExecutionTime": "00:03:15"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (255, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumTaxAndFee"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumTaxAndFee"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"Type","type":"String","physicalType":"nvarchar"},"sink":{"name":"Type","type":"String"}},{"source":{"name":"Amount","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Amount","type":"Decimal"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AppliesToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"AppliesToPolicyChange","type":"Boolean"}},{"source":{"name":"IsFullyEarned","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFullyEarned","type":"Boolean"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:10:26.5359206Z",
            "LastExecutionTime": "00:02:50"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (256, N'{
            "schema": "dbo",
            "table": "AccountTransactionVersionPremiumTransactionSummary"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountTransactionVersionPremiumTransactionSummary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountTransactionVersionPremiumId","type":"Int32","physicalType":"int"},"sink":{"name":"AccountTransactionVersionPremiumId","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:10:26.5359206Z",
            "LastExecutionTime": "00:01:13"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (257, N'{
            "schema": "dbo",
            "table": "BillingAccount"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BillingAccount"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"InsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"InsuredId","type":"Guid"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"BillToType","type":"String","physicalType":"nvarchar"},"sink":{"name":"BillToType","type":"String"}},{"source":{"name":"BillToBrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BillToBrokerageId","type":"Guid"}},{"source":{"name":"IsFinanced","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFinanced","type":"Boolean"}},{"source":{"name":"FinanceCompanyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FinanceCompanyName","type":"String"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"ReferenceCode","type":"Int32","physicalType":"int"},"sink":{"name":"ReferenceCode","type":"Int32"}},{"source":{"name":"BillingAddressIsMailingAddress","type":"Boolean","physicalType":"bit"},"sink":{"name":"BillingAddressIsMailingAddress","type":"Boolean"}},{"source":{"name":"AddressLine1","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressLine1","type":"String"}},{"source":{"name":"AddressLine2","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressLine2","type":"String"}},{"source":{"name":"AddressCity","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressCity","type":"String"}},{"source":{"name":"AddressState","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressState","type":"String"}},{"source":{"name":"AddressZipCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressZipCode","type":"String"}},{"source":{"name":"AddressCounty","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressCounty","type":"String"}},{"source":{"name":"AddressCountry","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressCountry","type":"String"}},{"source":{"name":"ContactInfoIsInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"ContactInfoIsInsured","type":"Boolean"}},{"source":{"name":"ContactEntityName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactEntityName","type":"String"}},{"source":{"name":"ContactPrefix","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactPrefix","type":"String"}},{"source":{"name":"ContactFirstName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactFirstName","type":"String"}},{"source":{"name":"ContactMiddleName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactMiddleName","type":"String"}},{"source":{"name":"ContactLastName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactLastName","type":"String"}},{"source":{"name":"ContactSuffix","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactSuffix","type":"String"}},{"source":{"name":"ContactPhone","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactPhone","type":"String"}},{"source":{"name":"ContactEmail","type":"String","physicalType":"nvarchar"},"sink":{"name":"ContactEmail","type":"String"}},{"source":{"name":"MortgageeLoanNumber","type":"String","physicalType":"nvarchar"},"sink":{"name":"MortgageeLoanNumber","type":"String"}},{"source":{"name":"PaymentPlan","type":"String","physicalType":"nvarchar"},"sink":{"name":"PaymentPlan","type":"String"}},{"source":{"name":"PaymentMethod","type":"String","physicalType":"nvarchar"},"sink":{"name":"PaymentMethod","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"AddressLineUnit","type":"String","physicalType":"nvarchar"},"sink":{"name":"AddressLineUnit","type":"String"}},{"source":{"name":"AutoPayMethod","type":"String","physicalType":"nvarchar"},"sink":{"name":"AutoPayMethod","type":"String"}},{"source":{"name":"AutoPayToken","type":"String","physicalType":"nvarchar"},"sink":{"name":"AutoPayToken","type":"String"}},{"source":{"name":"IsAutoPay","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAutoPay","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:53:58.6812936"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:00"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (258, N'{
            "schema": "dbo",
            "table": "Broker"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Broker"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "FirstName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "FirstName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LastName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LastName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Title",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Title",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PreferredName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PreferredName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Phone",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Phone",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Email",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Email",
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
                            "name": "HasProfilePhoto",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "HasProfilePhoto",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "UserId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "UserId",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "NationalProducerNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "NationalProducerNumber",
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
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:17:03.2577425"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:06"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (259, N'{
            "schema": "dbo",
            "table": "Brokerage"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Brokerage"
        }', NULL, N'{              "preCopyScript": null,              "tableOption": "autoCreate",              "writeBehavior": "upsert",              "sqlWriterUseTableLock": false,              "disableMetricsCollection": false,              "upsertSettings": {                  "useTempDB": true,                  "keys": [                      "Id"                  ]              }          }', N'{
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
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Name",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "TaxIdNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "TaxIdNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressLine1",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressLine1",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressLine2",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressLine2",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressCity",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressCity",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressState",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressState",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressZipCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressZipCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressCountry",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressCountry",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Code",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Code",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ProducerId",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "ProducerId",
                            "type": "Int32"
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
                            "name": "Dba",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Dba",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressCounty",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressCounty",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "HasProfilePhoto",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "HasProfilePhoto",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferenceCode",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "ReferenceCode",
                            "type": "Int32"
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
                            "name": "Status",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Status",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AddressLineUnit",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AddressLineUnit",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "TaxIdNumberType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "TaxIdNumberType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AgencyManagementSystem",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AgencyManagementSystem",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ClaimsContactEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ClaimsContactEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressCity",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressCity",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressCountry",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressCountry",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressCounty",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressCounty",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressLine1",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressLine1",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressLine2",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressLine2",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressLineUnit",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressLineUnit",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressSameAsPrimary",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "CommissionAddressSameAsPrimary",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressState",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressState",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionAddressZipCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CommissionAddressZipCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "EntityType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "EntityType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "EntityTypeLLC",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "EntityTypeLLC",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IVANSUserName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "IVANSUserName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IVANSYAccount",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "IVANSYAccount",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "InsuranceCompanyName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "InsuranceCompanyName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "InsurancePolicyEffectiveDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "InsurancePolicyEffectiveDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "InsurancePolicyExpirationDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "InsurancePolicyExpirationDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "InsurancePolicyLimit",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "InsurancePolicyLimit",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "InsurancePolicyNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "InsurancePolicyNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LegacySystemNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LegacySystemNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LexisNexisCompanyCodeSuffix",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LexisNexisCompanyCodeSuffix",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressCity",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressCity",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressCountry",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressCountry",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressCounty",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressCounty",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressLine1",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressLine1",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressLine2",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressLine2",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressLineUnit",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressLineUnit",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressSameAsPrimary",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "LocationAddressSameAsPrimary",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressState",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressState",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LocationAddressZipCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LocationAddressZipCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressCity",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressCity",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressCountry",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressCountry",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressCounty",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressCounty",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressLine1",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressLine1",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressLine2",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressLine2",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressLineUnit",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressLineUnit",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressSameAsPrimary",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "MailingAddressSameAsPrimary",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressState",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressState",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MailingAddressZipCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MailingAddressZipCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "NewBusinessContactEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "NewBusinessContactEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PolicyChangeContactEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PolicyChangeContactEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PrimaryBrokerId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "PrimaryBrokerId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "PrimaryEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PrimaryEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PrimaryPhoneNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PrimaryPhoneNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "RenewalContactEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "RenewalContactEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "BrokerageType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "BrokerageType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "StatusUpdateDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "StatusUpdateDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "TerminatedDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "TerminatedDate",
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
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'

{
            "dataLoadingBehavior": "DeltaLoad",
			            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
			            "watermarkColumnNameUpdate": "UpdatedDate",
						            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:17:02.5924612"
			        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:02"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (260, N'{
            "schema": "dbo",
            "table": "BrokerageActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-26T17:17:03.3153457"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:00"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (261, N'{
            "schema": "dbo",
            "table": "BrokerageBankingDetail"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageBankingDetail"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "CompanyName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CompanyName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "BankName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "BankName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "RoutingNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "RoutingNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "AccountNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AccountNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "TypeOfAccount",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "TypeOfAccount",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "TokenId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "TokenId",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-05T21:45:43.4358159"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (262, N'{
            "schema": "dbo",
            "table": "BrokerageCommission"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageCommission"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"CoverageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CoverageId","type":"Guid"}},{"source":{"name":"State","type":"String","physicalType":"nvarchar"},"sink":{"name":"State","type":"String"}},{"source":{"name":"ProgramType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProgramType","type":"String"}},{"source":{"name":"BusinessType","type":"String","physicalType":"nvarchar"},"sink":{"name":"BusinessType","type":"String"}},{"source":{"name":"CommissionPercent","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"CommissionPercent","type":"Decimal"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"IsExpired","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsExpired","type":"Boolean"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-21T16:54:19.6037999"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (263, N'{
            "schema": "dbo",
            "table": "BrokerageCompanyTeamMember"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageCompanyTeamMember"
        }', NULL, N'{              "preCopyScript": null,              "tableOption": "autoCreate",              "writeBehavior": "upsert",              "sqlWriterUseTableLock": false,              "disableMetricsCollection": false,              "upsertSettings": {                  "useTempDB": true,                  "keys": [                      "Id"                  ]              }          }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"State","type":"String","physicalType":"nvarchar"},"sink":{"name":"State","type":"String"}},{"source":{"name":"ProgramType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProgramType","type":"String"}},{"source":{"name":"TeamMemberType","type":"String","physicalType":"nvarchar"},"sink":{"name":"TeamMemberType","type":"String"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-26T02:00:16.5485065"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (264, N'{
            "schema": "dbo",
            "table": "BrokerageDocument"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageDocument"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"DocumentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"DocumentId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-07-21T08:32:45.279227"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-1"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (265, N'{
            "schema": "dbo",
            "table": "BrokerageLicense"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageLicense"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "License",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "License",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "StateCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "StateCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ExpirationDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ExpirationDate",
                            "type": "DateTime"
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
                            "name": "ResidencyCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ResidencyCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "BrokerId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "EffectiveDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "EffectiveDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "HolderName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "HolderName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LicenseCategory",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LicenseCategory",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-07T12:39:20.8744496"
        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-2"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (266, N'{
            "schema": "dbo",
            "table": "BrokerageProduct"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageProduct"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsEnabled",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsEnabled",
                            "type": "Boolean"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-04T07:41:05.2684386"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:00"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (267, N'{
            "schema": "dbo",
            "table": "BrokerageRelation"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerageRelation"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "RelatedBrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RelatedBrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "RelationBrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RelationBrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsBillingOffice",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsBillingOffice",
                            "type": "Boolean"
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
                            "name": "RelationshipType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "RelationshipType",
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
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-21T19:42:16.855481"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:05"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (268, N'{
            "schema": "dbo",
            "table": "BrokerAttribute"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerAttribute"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "AttributeId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "AttributeId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "Value",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Value",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-14T07:52:37.1538183"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-7"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (269, N'{
            "schema": "dbo",
            "table": "BrokerAttributeList"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerAttributeList"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Name",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IsEnabled",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsEnabled",
                            "type": "Boolean"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-09-30T23:04:56.823139"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:26"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (270, N'{
            "schema": "dbo",
            "table": "BrokerBrokerageRelation"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerBrokerageRelation"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "BrokerId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "CanAccess",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "CanAccess",
                            "type": "Boolean"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-14T07:53:02.7166299"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:02"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (271, N'{
            "schema": "dbo",
            "table": "BrokerOfRecordChange"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerOfRecordChange"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"BrokerOfRecordChangeType","type":"String","physicalType":"nvarchar"},"sink":{"name":"BrokerOfRecordChangeType","type":"String"}},{"source":{"name":"ProcessDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ProcessDate","type":"DateTime"}},{"source":{"name":"OldBrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"OldBrokerageId","type":"Guid"}},{"source":{"name":"NewBrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"NewBrokerageId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-29T15:17:09.3042893"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (272, N'{
            "schema": "dbo",
            "table": "BrokerOfRecordChangeDetail"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerOfRecordChangeDetail"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"BrokerOfRecordChangeId","type":"Int32","physicalType":"int"},"sink":{"name":"BrokerOfRecordChangeId","type":"Int32"}},{"source":{"name":"BrokerId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerId","type":"Guid"}},{"source":{"name":"PolicyNumbers","type":"String","physicalType":"nvarchar"},"sink":{"name":"PolicyNumbers","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-29T15:17:09.3042899"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:-3"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (273, N'{
            "schema": "dbo",
            "table": "BrokerProduct"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "BrokerProduct"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "BrokerId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BrokerId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsEnabled",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsEnabled",
                            "type": "Boolean"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-14T08:15:11.1744788"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:01"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (274, N'{
            "schema": "dbo",
            "table": "Cache_Insights"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[Cache_Insights]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Cache_Insights"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "Id",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Id",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Value",
                            "type": "Byte[]",
                            "physicalType": "varbinary"
                        },
                        "sink": {
                            "name": "Value",
                            "type": "Byte[]"
                        }
                    },
                    {
                        "source": {
                            "name": "ExpiresAtTime",
                            "type": "DateTimeOffset",
                            "physicalType": "datetimeoffset"
                        },
                        "sink": {
                            "name": "ExpiresAtTime",
                            "type": "DateTimeOffset"
                        }
                    },
                    {
                        "source": {
                            "name": "SlidingExpirationInSeconds",
                            "type": "Int64",
                            "physicalType": "bigint"
                        },
                        "sink": {
                            "name": "SlidingExpirationInSeconds",
                            "type": "Int64"
                        }
                    },
                    {
                        "source": {
                            "name": "AbsoluteExpiration",
                            "type": "DateTimeOffset",
                            "physicalType": "datetimeoffset"
                        },
                        "sink": {
                            "name": "AbsoluteExpiration",
                            "type": "DateTimeOffset"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (275, N'{
            "schema": "dbo",
            "table": "Cache_Metal"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[Cache_Metal]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Cache_Metal"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "Id",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Id",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Value",
                            "type": "Byte[]",
                            "physicalType": "varbinary"
                        },
                        "sink": {
                            "name": "Value",
                            "type": "Byte[]"
                        }
                    },
                    {
                        "source": {
                            "name": "ExpiresAtTime",
                            "type": "DateTimeOffset",
                            "physicalType": "datetimeoffset"
                        },
                        "sink": {
                            "name": "ExpiresAtTime",
                            "type": "DateTimeOffset"
                        }
                    },
                    {
                        "source": {
                            "name": "SlidingExpirationInSeconds",
                            "type": "Int64",
                            "physicalType": "bigint"
                        },
                        "sink": {
                            "name": "SlidingExpirationInSeconds",
                            "type": "Int64"
                        }
                    },
                    {
                        "source": {
                            "name": "AbsoluteExpiration",
                            "type": "DateTimeOffset",
                            "physicalType": "datetimeoffset"
                        },
                        "sink": {
                            "name": "AbsoluteExpiration",
                            "type": "DateTimeOffset"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (276, N'{
            "schema": "dbo",
            "table": "Carrier"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Carrier"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "CarrierName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CarrierName",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "Id",
            "watermarkColumnType": "Int32",
            "watermarkColumnNameUpdate": "Id",
            "watermarkColumnNameUpdatType": "Int32",
            "watermarkColumnStartValue": "2203"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:01:32"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (277, N'{
            "schema": "dbo",
            "table": "Coverage"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Coverage"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Name",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Number",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "Number",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "AsLob",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AsLob",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ShortName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ShortName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ObjectType",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-29T00:00:00"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (278, N'{
            "schema": "dbo",
            "table": "Document"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Document"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Extension",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Extension",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Description",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Description",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DocumentTypeId",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "DocumentTypeId",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "OriginalBlobIdentifier",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "OriginalBlobIdentifier",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IsOcrCompleted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsOcrCompleted",
                            "type": "Boolean"
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
                            "name": "IsDeleted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsDeleted",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsDeletedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "IsDeletedByUserId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsDeletedOn",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "IsDeletedOn",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "IsExternallyShared",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsExternallyShared",
                            "type": "Boolean"
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
                            "name": "UploadedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "UploadedByUserId",
                            "type": "Guid"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-09T19:23:56.2120337"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:-7"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (279, N'{
            "schema": "dbo",
            "table": "DocumentIndex"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "DocumentIndex"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"PageNumber","type":"Int32","physicalType":"int"},"sink":{"name":"PageNumber","type":"Int32"}},{"source":{"name":"IndexTypeId","type":"Int32","physicalType":"int"},"sink":{"name":"IndexTypeId","type":"Int32"}},{"source":{"name":"DocumentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"DocumentId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (280, N'{
            "schema": "dbo",
            "table": "DocumentIndexType"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "DocumentIndexType"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (281, N'{
            "schema": "dbo",
            "table": "DocumentOcrResult"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "DocumentOcrResult"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"Value","type":"String","physicalType":"nvarchar"},"sink":{"name":"Value","type":"String"}},{"source":{"name":"PageNumber","type":"Int32","physicalType":"int"},"sink":{"name":"PageNumber","type":"Int32"}},{"source":{"name":"Confidence","type":"Decimal","physicalType":"decimal","scale":4,"precision":16},"sink":{"name":"Confidence","type":"Decimal"}},{"source":{"name":"BoundingPolygon","type":"String","physicalType":"nvarchar"},"sink":{"name":"BoundingPolygon","type":"String"}},{"source":{"name":"DocumentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"DocumentId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"DataType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DataType","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"ValueFormatted","type":"String","physicalType":"nvarchar"},"sink":{"name":"ValueFormatted","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-09T19:24:54.7491477"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (282, N'{
            "schema": "dbo",
            "table": "DocumentOcrResultField"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "DocumentOcrResultField"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"DocumentOcrResultId","type":"Int32","physicalType":"int"},"sink":{"name":"DocumentOcrResultId","type":"Int32"}},{"source":{"name":"FieldId","type":"Int32","physicalType":"int"},"sink":{"name":"FieldId","type":"Int32"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-06-13T07:38:35.3610883"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:01:08"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (283, N'{
            "schema": "dbo",
            "table": "DocumentType"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "DocumentType"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"Category","type":"String","physicalType":"nvarchar"},"sink":{"name":"Category","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-10T14:25:48.22"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:-2"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (284, N'{
            "schema": "dbo",
            "table": "EmailProcessLog"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "EmailProcessLog"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "EmailId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "EmailId",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "EmailSubject",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "EmailSubject",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IsProcessed",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsProcessed",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "EmailRecievedOnUtc",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "EmailRecievedOnUtc",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "ProcessedOnUTC",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ProcessedOnUTC",
                            "type": "DateTime"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (285, N'{
            "schema": "dbo",
            "table": "Form"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Form"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"Index","type":"Int32","physicalType":"int"},"sink":{"name":"Index","type":"Int32"}},{"source":{"name":"Number","type":"String","physicalType":"nvarchar"},"sink":{"name":"Number","type":"String"}},{"source":{"name":"Edition","type":"String","physicalType":"nvarchar"},"sink":{"name":"Edition","type":"String"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"FormType","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormType","type":"String"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"ExpirationDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"ExpirationDate","type":"DateTime"}},{"source":{"name":"IsAlwaysOn","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAlwaysOn","type":"Boolean"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"DocumentType","type":"String","physicalType":"nvarchar"},"sink":{"name":"DocumentType","type":"String"}},{"source":{"name":"IsAttached","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttached","type":"Boolean"}},{"source":{"name":"IsOptional","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsOptional","type":"Boolean"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IsAttachedToPolicyChange","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsAttachedToPolicyChange","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-06T03:21:00.1617182"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (286, N'{
            "schema": "dbo",
            "table": "GraphSubscription"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "GraphSubscription"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"Identifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"Identifier","type":"String"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (287, N'{
            "schema": "dbo",
            "table": "IndustryCode"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "IndustryCode"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Code","type":"Int32","physicalType":"int"},"sink":{"name":"Code","type":"Int32"}},{"source":{"name":"Description","type":"String","physicalType":"nvarchar"},"sink":{"name":"Description","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-01T20:07:30.3925183"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (288, N'{
            "schema": "dbo",
            "table": "InspectionTransactionLog"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "InspectionTransactionLog"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "TransactionId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "TransactionId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsProcessed",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsProcessed",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "DateCreated",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "DateCreated",
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
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "Id",
            "watermarkColumnType": "Int32",
            "watermarkColumnNameUpdate": "Id",
            "watermarkColumnNameUpdatType": "Int32",
            "watermarkColumnStartValue": "1482"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:-4"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (351, N'{
            "tableName": "t_int_address"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_int_address"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "T_ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "T_ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SOURCE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SOURCE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_SOURCE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUB_SOURCE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_PAGE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS_PAGE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "datetime"
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (289, N'{
            "schema": "dbo",
            "table": "Insured"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[Insured]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Insured"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                    "name": "NamedInsured",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "NamedInsured",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "TaxIdNumber",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "TaxIdNumber",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Dba",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Dba",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressLine1",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressLine1",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressLine2",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressLine2",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressCity",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressCity",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressState",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressState",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressZipCode",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressZipCode",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressCountry",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressCountry",
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
            },
            {
                "source": {
                    "name": "MailingAddressCounty",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressCounty",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Email",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Email",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "FirstName",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "FirstName",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "InsuredType",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "InsuredType",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "LastName",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "LastName",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MobilePhone",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MobilePhone",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "PreferredName",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "PreferredName",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Prefix",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Prefix",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Suffix",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Suffix",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Title",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Title",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Birthdate",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Birthdate",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MiddleName",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MiddleName",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "Occupation",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Occupation",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "ReferenceCode",
                    "type": "Int32",
                    "physicalType": "int"
                },
                "sink": {
                    "name": "ReferenceCode",
                    "type": "Int32",
                    "physicalType": "int"
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
                    "name": "IsVip",
                    "type": "Boolean",
                    "physicalType": "bit"
                },
                "sink": {
                    "name": "IsVip",
                    "type": "Boolean",
                    "physicalType": "bit"
                }
            },
            {
                "source": {
                    "name": "InsuredScore",
                    "type": "Int32",
                    "physicalType": "int"
                },
                "sink": {
                    "name": "InsuredScore",
                    "type": "Int32",
                    "physicalType": "int"
                }
            },
            {
                "source": {
                    "name": "Employer",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "Employer",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "SubscriberContributionEndDate",
                    "type": "DateTime",
                    "physicalType": "datetime2"
                },
                "sink": {
                    "name": "SubscriberContributionEndDate",
                    "type": "DateTime",
                    "physicalType": "datetime2"
                }
            },
            {
                "source": {
                    "name": "HomePhone",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "HomePhone",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "MailingAddressLineUnit",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "MailingAddressLineUnit",
                    "type": "String",
                    "physicalType": "nvarchar"
                }
            },
            {
                "source": {
                    "name": "TaxIdNumberType",
                    "type": "String",
                    "physicalType": "nvarchar"
                },
                "sink": {
                    "name": "TaxIdNumberType",
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
}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (290, N'{
            "schema": "dbo",
            "table": "InsuredActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "InsuredActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"InsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"InsuredId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-25T14:32:54.8719789"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (352, N'{
            "tableName": "t_pub_user"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_pub_user"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "USER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "USER_ID",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ORG_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORG_ID",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PASSWORD",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PASSWORD",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "REAL_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REAL_NAME",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CREATE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CREATE_DATE",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "USER_NAME",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PASSWORD_CHANGE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "PASSWORD_CHANGE",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "NEED_CHANGE_PASS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NEED_CHANGE_PASS",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DEFAULT_LANG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DEFAULT_LANG",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_DISABLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "USER_DISABLE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DISABLE_CAUSE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DISABLE_CAUSE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "INVALID_LOGIN",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INVALID_LOGIN",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_IP",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LATEST_IP",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_IP_OLD",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LATEST_IP_OLD",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_LOGIN_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LATEST_LOGIN_TIME",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_LOGIN_OLD",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LATEST_LOGIN_OLD",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_LOGOUT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LATEST_LOGOUT_TIME",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "LATEST_ACCESS_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LATEST_ACCESS_TIME",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_TYPE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "USER_TYPE",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PARTY_ID",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_ROLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_ROLE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DEPT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEPT_ID",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "EMAIL",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DISABLE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DISABLE_DATE",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "CUSTOMER_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CUSTOMER_ID",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ID_CARD",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ID_CARD",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ACTIVATE_PASSWORD",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACTIVATE_PASSWORD",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_ON_LEAVE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "USER_ON_LEAVE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "DISABLE_CAUSE_DETAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DISABLE_CAUSE_DETAIL",
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
                            "name": "UPDATE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "UPDATE_TIME",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "DYNAMIC_FIELDS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DYNAMIC_FIELDS",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MOBILE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MOBILE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ORGAN_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORGAN_ID",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CODE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ON_LEAVE_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ON_LEAVE_FLAG",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "REGISTER_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REGISTER_CODE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "REGISTER_EXPIRE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "REGISTER_EXPIRE_DATE",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "TITLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TITLE",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "INACTIVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INACTIVE_DATE",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "DIRECT_USER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DIRECT_USER",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PRINT_FORMAT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRINT_FORMAT",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PASSWORD_VALIDITY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PASSWORD_VALIDITY",
                            "type": "Decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "USER_ACCOUNT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "USER_ACCOUNT",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "SIGNATURE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SIGNATURE",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (291, N'{
            "schema": "dbo",
            "table": "InsuredRelationship"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "InsuredRelationship"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "RelationInsuredId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RelationInsuredId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "RelatedInsuredId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RelatedInsuredId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "RelationshipType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "RelationshipType",
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
                            "name": "IsCoInsured",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsCoInsured",
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
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-07-28T18:58:31.3357586"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (292, N'{
            "schema": "dbo",
            "table": "Issue"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Issue"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "Stage",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Stage",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IssueType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "IssueType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferralLevel",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "ReferralLevel",
                            "type": "Int32"
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
                            "name": "CanOverride",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "CanOverride",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "OverrideAuthorityLevel",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "OverrideAuthorityLevel",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "EffectiveDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "EffectiveDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "ExpirationDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ExpirationDate",
                            "type": "DateTime"
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-06T20:02:02.139204"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (293, N'{
            "schema": "dbo",
            "table": "LogSearchAccount"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "LogSearchAccount"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Keyword","type":"String","physicalType":"nvarchar"},"sink":{"name":"Keyword","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-04-06T16:16:08.1790037"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:01:32"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (294, N'{
            "schema": "dbo",
            "table": "LogSearchInsured"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "LogSearchInsured"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"PrimaryInsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PrimaryInsuredId","type":"Guid"}},{"source":{"name":"Keyword","type":"String","physicalType":"nvarchar"},"sink":{"name":"Keyword","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-04-06T07:48:39.6190064"
        }', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:00:27"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (346, N'{
            "tableName": "t_clm_reserve_his"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_reserve_his"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
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
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ITEM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ITEM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OUTSTANDING_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OUTSTANDING_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OUTSTANDING_CHANGED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OUTSTANDING_CHANGED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_CHANGED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_CHANGED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CURRENCY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CURRENCY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CHANGE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CHANGE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_INSTANCE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "BUSINESS_INSTANCE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TRANS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TRANS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OLD_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OLD_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NEW_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NEW_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REJECT_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REJECT_REASON",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REOPEN_CAUSE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REOPEN_CAUSE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REMARK",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "POST_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "POST_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "RETROACTIVE_ADJUST",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RETROACTIVE_ADJUST",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_LEVEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_LEVEL",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_UPDATE_TRIGGER_FROM",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_UPDATE_TRIGGER_FROM",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (295, N'{
            "schema": "dbo",
            "table": "Note"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Note"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"Content","type":"String","physicalType":"nvarchar"},"sink":{"name":"Content","type":"String"}},{"source":{"name":"ParentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ParentId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"TaggedUserIds","type":"String","physicalType":"nvarchar"},"sink":{"name":"TaggedUserIds","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"DocumentIds","type":"String","physicalType":"nvarchar"},"sink":{"name":"DocumentIds","type":"String"}},{"source":{"name":"IsExternallyShared","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsExternallyShared","type":"Boolean"}},{"source":{"name":"IsFlagged","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsFlagged","type":"Boolean"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-08-10T07:30:49.7661626"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:01:32"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (296, N'{
            "schema": "dbo",
            "table": "Ofac"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Ofac"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "AccountId"
                ]
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
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
                            "name": "NamedInsured",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "NamedInsured",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "OfacResult",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "OfacResult",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "ExpirationDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ExpirationDate",
                            "type": "DateTime"
                        }
                    },
                    {
                        "source": {
                            "name": "ResultDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ResultDate",
                            "type": "DateTime"
                        }
                    },
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-06-26T07:37:28.6196156"
        }
', N'{
            "LastExecutionDate": "2023-08-10T09:01:45.9591017Z",
            "LastExecutionTime": "00:01:32"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (297, N'{
            "schema": "dbo",
            "table": "Product"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Product"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"InternalName","type":"String","physicalType":"nvarchar"},"sink":{"name":"InternalName","type":"String"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"IsEnabled","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsEnabled","type":"Boolean"}},{"source":{"name":"ProductLine","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductLine","type":"String"}},{"source":{"name":"RateDefinitionServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RateDefinitionServiceName","type":"String"}},{"source":{"name":"RulesDefinitionServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RulesDefinitionServiceName","type":"String"}},{"source":{"name":"FormDefinitionServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"FormDefinitionServiceName","type":"String"}},{"source":{"name":"ExternalUserCanBind","type":"Boolean","physicalType":"bit"},"sink":{"name":"ExternalUserCanBind","type":"Boolean"}},{"source":{"name":"ExternalUserCanOffer","type":"Boolean","physicalType":"bit"},"sink":{"name":"ExternalUserCanOffer","type":"Boolean"}},{"source":{"name":"RoundPremiumToNearestDollar","type":"Boolean","physicalType":"bit"},"sink":{"name":"RoundPremiumToNearestDollar","type":"Boolean"}},{"source":{"name":"CanBillToBrokerage","type":"Boolean","physicalType":"bit"},"sink":{"name":"CanBillToBrokerage","type":"Boolean"}},{"source":{"name":"CanBillToInsured","type":"Boolean","physicalType":"bit"},"sink":{"name":"CanBillToInsured","type":"Boolean"}},{"source":{"name":"CanBillToMortgagee","type":"Boolean","physicalType":"bit"},"sink":{"name":"CanBillToMortgagee","type":"Boolean"}},{"source":{"name":"ProductCode","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductCode","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"IncrementPolicyNumberOnRenewal","type":"Boolean","physicalType":"bit"},"sink":{"name":"IncrementPolicyNumberOnRenewal","type":"Boolean"}},{"source":{"name":"GeneratePolicyNumberOnCreation","type":"Boolean","physicalType":"bit"},"sink":{"name":"GeneratePolicyNumberOnCreation","type":"Boolean"}},{"source":{"name":"PrimaryInsuredMustBeIndividual","type":"Boolean","physicalType":"bit"},"sink":{"name":"PrimaryInsuredMustBeIndividual","type":"Boolean"}},{"source":{"name":"AllowPolicyNumberOverride","type":"Boolean","physicalType":"bit"},"sink":{"name":"AllowPolicyNumberOverride","type":"Boolean"}},{"source":{"name":"CanBindWithoutIssuance","type":"Boolean","physicalType":"bit"},"sink":{"name":"CanBindWithoutIssuance","type":"Boolean"}},{"source":{"name":"AllowedStates","type":"String","physicalType":"nvarchar"},"sink":{"name":"AllowedStates","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-05-02T02:21:27.7805436"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (298, N'{
            "schema": "dbo",
            "table": "ProductActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"Field","type":"String","physicalType":"nvarchar"},"sink":{"name":"Field","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-17T16:12:19.4924016"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (299, N'{
            "schema": "dbo",
            "table": "ProductAdditionalEngineMap"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductAdditionalEngineMap"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferenceObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ReferenceObjectType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ConvertObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ConvertObjectType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "EngineReferenceProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "EngineReferenceProductId",
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
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-05-29T00:00:00"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (300, N'{
            "schema": "dbo",
            "table": "ProductCoverages"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[ProductCoverages]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductCoverages"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "CoveragesId",
                    "ProductsId"
                ]
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "CoveragesId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "CoveragesId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ProductsId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductsId",
                            "type": "Guid"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{
            "LastExecutionDate": null,
            "LastExecutionTime": null
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (301, N'{
            "schema": "dbo",
            "table": "ProductDefinition"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductDefinition"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"ServiceName","type":"String","physicalType":"nvarchar"},"sink":{"name":"ServiceName","type":"String"}},{"source":{"name":"EffectiveDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"EffectiveDate","type":"DateTime"}},{"source":{"name":"Definition","type":"String","physicalType":"nvarchar"},"sink":{"name":"Definition","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"VersionId","type":"String","physicalType":"nvarchar"},"sink":{"name":"VersionId","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"Version","type":"String","physicalType":"nvarchar"},"sink":{"name":"Version","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-25T10:26:29.8994615"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
GO
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (302, N'{
            "schema": "dbo",
            "table": "ProductObject"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductObject"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"ProductId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ProductId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Label","type":"String","physicalType":"nvarchar"},"sink":{"name":"Label","type":"String"}},{"source":{"name":"AutoAdd","type":"Boolean","physicalType":"bit"},"sink":{"name":"AutoAdd","type":"Boolean"}},{"source":{"name":"MaxAllowed","type":"Int32","physicalType":"int"},"sink":{"name":"MaxAllowed","type":"Int32"}},{"source":{"name":"ParentObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ParentObjectType","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"IsForm","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsForm","type":"Boolean"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"TableIdentifier","type":"String","physicalType":"nvarchar"},"sink":{"name":"TableIdentifier","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'

{
            "dataLoadingBehavior": "DeltaLoad",
			            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
			            "watermarkColumnNameUpdate": "UpdatedDate",
						            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-17T16:12:15.0880725"
			        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (303, N'{
            "schema": "dbo",
            "table": "ProductObjectField"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductObjectField"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "ProductObjectId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductObjectId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "Label",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Label",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "Field",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Field",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "Value",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Value",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DataType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "DataType",
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
                    },
                    {
                        "source": {
                            "name": "Group",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Group",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IsEncrypted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsEncrypted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "Index",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "Index",
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "IsHidden",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsHidden",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "Description",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Description",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IsDisabled",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsDisabled",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "IsPostBindDisable",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsPostBindDisable",
                            "type": "Boolean",
                            "physicalType": "bit"
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
                            "name": "IgnorePolicyChangeTracking",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IgnorePolicyChangeTracking",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferenceObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ReferenceObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ShowOnReferencedField",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "ShowOnReferencedField",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "IsManualSave",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsManualSave",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "ManualSaveGroup",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ManualSaveGroup",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ManualSaveLabel",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ManualSaveLabel",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IsMaskedExternally",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsMaskedExternally",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'

{
            "dataLoadingBehavior": "DeltaLoad",
			            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
			            "watermarkColumnNameUpdate": "UpdatedDate",
						            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-25T21:06:18.3629872"
			        }', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (304, N'{
            "schema": "dbo",
            "table": "ProductPolicyNumberRange"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ProductPolicyNumberRange"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "ProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ProductId",
                            "type": "Guid"
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
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Prefix",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Prefix",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Suffix",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Suffix",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "StartRange",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "StartRange",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "EndRange",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "EndRange",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "NextIndex",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "NextIndex",
                            "type": "Int32"
                        }
                    },
                    {
                        "source": {
                            "name": "SkipNumbers",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "SkipNumbers",
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
                            "name": "SharedRangeProductId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "SharedRangeProductId",
                            "type": "Guid"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-29T00:00:00"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:00:25"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (335, N'{
            "tableName": "t_clm_accident"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_accident"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true
            }
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "ACCIDENT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_DESC",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "START_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "START_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "EXPIRY_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "EXPIRY_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "VALID_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VALID_FLAG",
                            "type": "String",
                            "physicalType": "char"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "FROM_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "FROM_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "TO_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "TO_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "AREA",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AREA",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (305, N'{
            "schema": "dbo",
            "table": "Role"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Role"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"ExternalId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-14T10:30:40.2184604"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (306, N'{
            "schema": "dbo",
            "table": "Rule"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Rule"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "RuleGroupId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "RuleGroupId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "ObjectType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ObjectType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ObjectField",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ObjectField",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Operator",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Operator",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Values",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Values",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "RuleType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "RuleType",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-06T20:02:02.135485"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (307, N'{
            "schema": "dbo",
            "table": "RuleGroup"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "RuleGroup"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "AttachmentId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "AttachmentId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "AttachmentType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AttachmentType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Description",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Description",
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
                            "name": "ExternalSourceId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceId",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2022-10-06T20:02:02.134993"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (308, N'{
            "schema": "dbo",
            "table": "User"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "User"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Name",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Name",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "FirstName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "FirstName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "LastName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "LastName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MobilePhone",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MobilePhone",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "OtherPhone",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "OtherPhone",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Email",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Email",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PreferredName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PreferredName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ProfileImageUrl",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ProfileImageUrl",
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
                            "name": "IsInternalUser",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsInternalUser",
                            "type": "Boolean"
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
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "2023-09-15T12:59:00.9002912"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (309, N'{
            "schema": "dbo",
            "table": "Workflow"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "Workflow"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"Enabled","type":"Boolean","physicalType":"bit"},"sink":{"name":"Enabled","type":"Boolean"}},{"source":{"name":"ProductLine","type":"String","physicalType":"nvarchar"},"sink":{"name":"ProductLine","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:02:36"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (310, N'{
            "schema": "dbo",
            "table": "WorkflowActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkflowActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"WorfklowId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorfklowId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:02:36"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (311, N'{
            "schema": "dbo",
            "table": "WorkflowStep"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkflowStep"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"WorkflowId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkflowId","type":"Guid"}},{"source":{"name":"ParentStepId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"ParentStepId","type":"Guid"}},{"source":{"name":"Name","type":"String","physicalType":"nvarchar"},"sink":{"name":"Name","type":"String"}},{"source":{"name":"DueDays","type":"Int32","physicalType":"int"},"sink":{"name":"DueDays","type":"Int32"}},{"source":{"name":"Priority","type":"Int32","physicalType":"int"},"sink":{"name":"Priority","type":"Int32"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"StepNumber","type":"Int32","physicalType":"int"},"sink":{"name":"StepNumber","type":"Int32"}},{"source":{"name":"TriggerAssignTo","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerAssignTo","type":"String"}},{"source":{"name":"TriggerEvent","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerEvent","type":"String"}},{"source":{"name":"TriggerType","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerType","type":"String"}},{"source":{"name":"CompleteOnCreate","type":"Boolean","physicalType":"bit"},"sink":{"name":"CompleteOnCreate","type":"Boolean"}},{"source":{"name":"SuspenseInDays","type":"Int32","physicalType":"int"},"sink":{"name":"SuspenseInDays","type":"Int32"}},{"source":{"name":"TriggerByUser","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerByUser","type":"String"}},{"source":{"name":"TriggerByProgram","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerByProgram","type":"String"}},{"source":{"name":"TriggerByEndorsementPremiumType","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerByEndorsementPremiumType","type":"String"}},{"source":{"name":"TriggerSuspenseOnCreate","type":"String","physicalType":"nvarchar"},"sink":{"name":"TriggerSuspenseOnCreate","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:02:36"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (312, N'{
            "schema": "dbo",
            "table": "WorkflowStepActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkflowStepActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"WorkflowStepId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkflowStepId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:02:36"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (348, N'{
            "tableName": "t_clm_settle_payee"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_settle_payee"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "SETTLE_PAYEE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_PAYEE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYEE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PAYEE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYMENT_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYMENT_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLE_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOCAL_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LOCAL_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LOCAL_SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LOCAL_SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PAID_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PAID_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "EXT_TRANS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "EXT_TRANS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PAY_MODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAY_MODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_ACCOUNT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_ACCOUNT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "BANK_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BANK_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCOUNT_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCOUNT_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCOUNT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCOUNT_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CHECK_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CHECK_NUMBER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CHECK_DELIVER_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CHECK_DELIVER_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REMARK",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYEE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYEE_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "REF_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REF_NUMBER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REF_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "REF_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_JSON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS_JSON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCOUNT_JSON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCOUNT_JSON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RESERVE_CURRENCY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_SETTLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RESERVE_SETTLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PARENT_PAYEE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PARENT_PAYEE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SWIFT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SWIFT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CHEQUE_ISSUE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CHEQUE_ISSUE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CHEQUE_RECEIVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CHEQUE_RECEIVE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYEE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYEE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DEBIT_CREDIT_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DEBIT_CREDIT_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_PRIMARY_PAYEE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_PRIMARY_PAYEE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TO_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TO_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CC_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CC_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_PARTY_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PTY_PARTY_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LEGAL_NAME_UWS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LEGAL_NAME_UWS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYEE_NAME_UWS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYEE_NAME_UWS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BCC_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BCC_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "UEN",
                            "type": "String"
                        },
                        "sink": {
                            "name": "UEN",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NRIC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NRIC",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MOBILE_NUMBER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "MOBILE_NUMBER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_ORG_ORGANIZATION_ID_NUMBER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PTY_ORG_ORGANIZATION_ID_NUMBER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (313, N'{
            "schema": "dbo",
            "table": "WorkTask"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkTask"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"AssignedUserId","type":"String","physicalType":"nvarchar"},"sink":{"name":"AssignedUserId","type":"String"}},{"source":{"name":"WorkTaskState","type":"String","physicalType":"nvarchar"},"sink":{"name":"WorkTaskState","type":"String"}},{"source":{"name":"Priority","type":"Int32","physicalType":"int"},"sink":{"name":"Priority","type":"Int32"}},{"source":{"name":"DueDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"DueDate","type":"DateTime"}},{"source":{"name":"AbandonedReason","type":"String","physicalType":"nvarchar"},"sink":{"name":"AbandonedReason","type":"String"}},{"source":{"name":"IsClosed","type":"Boolean","physicalType":"bit"},"sink":{"name":"IsClosed","type":"Boolean"}},{"source":{"name":"InsuredId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"InsuredId","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"BrokerageId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"BrokerageId","type":"Guid"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"PreviousTaskId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"PreviousTaskId","type":"Guid"}},{"source":{"name":"TaskName","type":"String","physicalType":"nvarchar"},"sink":{"name":"TaskName","type":"String"}},{"source":{"name":"WorkflowId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkflowId","type":"Guid"}},{"source":{"name":"WorkflowStepId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkflowStepId","type":"Guid"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedById","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"CreatedById","type":"Guid"}},{"source":{"name":"AccountTransactionId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountTransactionId","type":"Guid"}},{"source":{"name":"ConcurrencyId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ConcurrencyId","type":"String"}},{"source":{"name":"FinishedById","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"FinishedById","type":"Guid"}},{"source":{"name":"FinishedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"FinishedDate","type":"DateTime"}},{"source":{"name":"SuspenseUntilDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"SuspenseUntilDate","type":"DateTime"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:02:36"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (314, N'{
            "schema": "dbo",
            "table": "WorkTaskActivity"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkTaskActivity"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"WorkTaskId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkTaskId","type":"Guid"}},{"source":{"name":"UserId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"UserId","type":"Guid"}},{"source":{"name":"ObjectType","type":"String","physicalType":"nvarchar"},"sink":{"name":"ObjectType","type":"String"}},{"source":{"name":"Event","type":"String","physicalType":"nvarchar"},"sink":{"name":"Event","type":"String"}},{"source":{"name":"OldValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"OldValue","type":"String"}},{"source":{"name":"NewValue","type":"String","physicalType":"nvarchar"},"sink":{"name":"NewValue","type":"String"}},{"source":{"name":"PropertyName","type":"String","physicalType":"nvarchar"},"sink":{"name":"PropertyName","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "CreatedDate",
            "watermarkColumnType": "DateTime",
            "watermarkColumnNameUpdate": "UpdatedDate",
            "watermarkColumnNameUpdatType": "DateTime",
            "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"
        }
', N'{
            "LastExecutionDate": "2023-07-12T10:01:52.9486655Z",
            "LastExecutionTime": "00:04:20"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 0)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (349, N'{
            "tableName": "t_clm_settle"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_settle"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "SETTLE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SETTLE_ID",
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
                            "name": "TIMES",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TIMES",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBMITTER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUBMITTER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBMIT_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "SUBMIT_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "APPROVER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "APPROVER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPROVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "APPROVE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLEMENT_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLEMENT_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIM_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIM_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CO_INSURANCE_PAYMENT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CO_INSURANCE_PAYMENT",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BREACH_OF_CONTRACT_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BREACH_OF_CONTRACT_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SETLNO_ACTION_SUFFIX",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETLNO_ACTION_SUFFIX",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (315, N'{
            "schema": "dbo",
            "table": "ZipCode"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "ZipCode"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "upsert",
            "sqlWriterUseTableLock": false,
            "disableMetricsCollection": false,
            "upsertSettings": {
                "useTempDB": true,
                "keys": [
                    "Id"
                ]
            }
        }', N'{
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
                            "name": "Code",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Code",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "City",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "City",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "County",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "County",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "Country",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Country",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "CountryCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CountryCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "StateCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "StateCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "StateName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "StateName",
                            "type": "String"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[
            "Sandbox",
            "Trigger_1i1"
        ]', N'
{
            "dataLoadingBehavior": "DeltaLoad",
            "watermarkColumnName": "Id",
            "watermarkColumnType": "Int32",
            "watermarkColumnNameUpdate": "Id",
            "watermarkColumnNameUpdatType": "Int32",
            "watermarkColumnStartValue": "76811"
        }
', N'{
            "LastExecutionDate": "2023-09-26T18:15:58.752896Z",
            "LastExecutionTime": "00:01:34"
        }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (353, N'{
            "tableName": "t_pub_diary"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_pub_diary"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "DIARY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DIARY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DIARY_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DIARY_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REFER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "REFER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "REFER_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REFER_NO",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "ATTACH_TO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ATTACH_TO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ASSIGN_TO",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ASSIGN_TO",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DUE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DUE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "STATUS",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PRIORITY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PRIORITY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SEND_MESSAGE_TO",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SEND_MESSAGE_TO",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DIARY_CONTENT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DIARY_CONTENT",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "DIARY_TITLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DIARY_TITLE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel_t_pub_diary', N'[
            "Sandbox",
            "Trigger_9g4"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (354, N'{
            "tableName": "t_pub_address"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_pub_address"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate",
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_TYPE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ADDRESS_TYPE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_STATUS",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ADDRESS_STATUS",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_PRIMARY_ADDRESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_PRIMARY_ADDRESS",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "COUNTRY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COUNTRY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_LINE_1",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS_LINE_1",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_LINE_2",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS_LINE_2",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS_LINE_3",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS_LINE_3",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CITY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CITY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DISTRICT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DISTRICT",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_DISTRICT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_DISTRICT",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COUNTY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COUNTY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POST_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POST_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REFER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "REFER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "FULL_ADDRESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "FULL_ADDRESS",
                            "type": "String",
                            "physicalType": "text"
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
                            "name": "INSERT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "INSERT_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
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
                            "name": "MAILING_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MAILING_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel_t_pub_address', N'[
            "Sandbox",
            "Trigger_yex"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (336, N'{
            "tableName": "t_clm_case_status"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_case_status"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "STATUS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (337, N'{
            "tableName": "t_clm_case"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_case"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
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
                            "name": "CLAIM_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIM_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CASE_ORGAN_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CASE_ORGAN_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURE_ORGAN_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURE_ORGAN_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PROCESS_ORGAN_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PROCESS_ORGAN_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_CAUSE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_CAUSE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "ACCIDENT_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "NOTICE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "NOTICE_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "REGISTER_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "REGISTER_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CALLER_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CALLER_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CALLER_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CALLER_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CALLER_PHONE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CALLER_PHONE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTACT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTACT_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTACT_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTACT_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTACT_PHONE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTACT_PHONE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_PLACE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_PLACE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_DESC",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CASE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CASE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_DISTRICT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ACCIDENT_DISTRICT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "AGENT_TEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AGENT_TEL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICE_STATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICE_STATION",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICE_STATEMENT_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICE_STATEMENT_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICE_STATEMENT_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "POLICE_STATEMENT_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICE_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICE_REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DC_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DC_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_LIABILITY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_LIABILITY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PRODUCT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VALIDATION_DECISION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VALIDATION_DECISION",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "VALIDATION_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "VALIDATION_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "VALIDATION_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VALIDATION_REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "EXT_CLAIM_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "EXT_CLAIM_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FNOL_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "FNOL_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SALVAGE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SALVAGE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CURRENCY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CURRENCY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LAST_REVIEW_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LAST_REVIEW_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_COUNTRY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_COUNTRY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_REGION_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ACCIDENT_REGION_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_ADDRESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_ADDRESS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURANCE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURANCE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REPORTER_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REPORTER_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DATE_REPORTED_INSURED",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DATE_REPORTED_INSURED",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIMS_MADE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIMS_MADE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OWNER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RESERVE_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "REVIEW_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "REVIEW_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIM_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIM_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTACT_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTACT_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_TYPE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_TYPE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REJECT_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REJECT_REASON",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_STREET",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_STREET",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_TOWN",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_TOWN",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ACCIDENT_CITY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ACCIDENT_CITY",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POSTAL_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POSTAL_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FRAUD_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "FRAUD_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICE_REPORT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICE_REPORT",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "OFFICER1",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OFFICER1",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "BADGE1",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BADGE1",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "OFFICER2",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OFFICER2",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "BADGE2",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BADGE2",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "MIGRATION_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MIGRATION_REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "RECOVER_FROM",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RECOVER_FROM",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FP_DRIVER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "FP_DRIVER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "FP_DRIVER_BIRTH_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "FP_DRIVER_BIRTH_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "FP_TEL_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "FP_TEL_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTACT_PERSON_EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTACT_PERSON_EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "LEAD_CLAIM_OWNER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LEAD_CLAIM_OWNER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "REINSURANCE_CLAIM",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REINSURANCE_CLAIM",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BROKER_REFERNCE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BROKER_REFERNCE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CEDING_COMPANY_REFERENCE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CEDING_COMPANY_REFERENCE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MAINTENANCE_PERIOD_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "MAINTENANCE_PERIOD_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CAT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CAT_CODE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CAUSE_OF_LOSS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CAUSE_OF_LOSS_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CAUSE_OF_LOSS_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CAUSE_OF_LOSS_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (338, N'{
            "tableName": "t_clm_item"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_item"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "ITEM_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ITEM_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
                            "name": "PRODUCT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COVERAGE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COVERAGE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COVERAGE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COVERAGE_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUM_INSURED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUM_INSURED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SEQ_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SEQ_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "UPPER_COVERAGE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "UPPER_COVERAGE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "UPPER_COVERAGE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "UPPER_COVERAGE_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "POL_COVERAGE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "POL_COVERAGE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SALVAGE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SALVAGE_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INIT_LOSS_INDEMNITY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INIT_LOSS_INDEMNITY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CURRENCY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CURRENCY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_SHOW",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_SHOW",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "ADD_CAUSE_OF_LOSS_ON_COVERAGE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADD_CAUSE_OF_LOSS_ON_COVERAGE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "text"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (339, N'{
            "tableName": "t_clm_losscause"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_losscause"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "LOSS_CAUSE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_CAUSE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_CAUSE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_CAUSE_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_LINE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_CAUSE_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_CAUSE_DESC",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (342, N'{
            "tableName": "t_clm_party_role"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_party_role"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "ROLE_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ROLE_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ROLE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ROLE_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (343, N'{
            "tableName": "t_clm_party"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_party"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
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
                            "name": "INSURED_RELATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_RELATION",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SEQ_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SEQ_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CERTI_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CERTI_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CERTI_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CERTI_CODE",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "PARTY_ROLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PARTY_ROLE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LICENSE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LICENSE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LICENSE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LICENSE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LICENSE_INITIAL_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LICENSE_INITIAL_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "LICENSE_EXPIRY_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "LICENSE_EXPIRY_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_PARTY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_PARTY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_ADDRESS_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_ADDRESS_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_ACCOUNT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_ACCOUNT_ID",
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "PTY_CONTACT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PTY_CONTACT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "NEW_ROLE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NEW_ROLE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "EMAIL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "EMAIL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LEGAL_NAME_UWS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LEGAL_NAME_UWS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PAYEE_NAME_UWS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PAYEE_NAME_UWS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (344, N'{
            "tableName": "t_clm_pol_insured"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_pol_insured"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "POLICY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_NAME",
                            "type": "String",
                            "physicalType": "text"
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
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BRAND",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BRAND",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MODEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MODEL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VIN_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VIN_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ENGINE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ENGINE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MAKE_YEAR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MAKE_YEAR",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_OWNER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CAR_OWNER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_SEAT_NUM",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_SEAT_NUM",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SEAT_NUM",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SEAT_NUM",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVE_AREA",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVE_AREA",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "NEW_MARKET_VALUE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "NEW_MARKET_VALUE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPOINT_DRIVER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "APPOINT_DRIVER",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BUSINESS_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "VEHICLE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VEHICLE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MAKE_MONTH",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "MAKE_MONTH",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PARENT_INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PARENT_INSURED_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "WEIGHT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "WEIGHT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "VEHICLE_COLOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VEHICLE_COLOR",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VEHICLE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VEHICLE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUM_INSURED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUM_INSURED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_CATEGORY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_CATEGORY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "EXT_CONTENT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "EXT_CONTENT",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "VEHICLE_USAGE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VEHICLE_USAGE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POST_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POST_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COUNTRY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COUNTRY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DISTRICT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DISTRICT",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RETROACTIVE_EFF_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "RETROACTIVE_EFF_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "RETROACTIVE_EXP_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "RETROACTIVE_EXP_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "MAINTAIN_EFF_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "MAINTAIN_EFF_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "MAINTAIN_EXP_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "MAINTAIN_EXP_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "CERTI_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CERTI_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CERTI_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CERTI_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BIRTH_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "BIRTH_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "OCCUPATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OCCUPATION",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ORIGIN_REGION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ORIGIN_REGION",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "DESTINATION_REGION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DESTINATION_REGION",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "MAIN_VOYAGE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MAIN_VOYAGE_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VOYAGE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VOYAGE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DEPARTURE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "DEPARTURE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "VALUATION_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VALUATION_TYPE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "VESSELL_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "VESSELL_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OTHER_MODEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OTHER_MODEL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REG_NO_TYPE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "REG_NO_TYPE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "NEW_VEHICLE_FLAG",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "NEW_VEHICLE_FLAG",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_OWNER_TEL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CAR_OWNER_TEL",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BENE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "BENE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PLAN_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PLAN_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LIMIT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LIMIT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_UID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_UID",
                            "type": "String",
                            "physicalType": "varchar"
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
                            "physicalType": "text"
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_INFO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVER_INFO",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "ADDRESS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ADDRESS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_NATURE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BUSINESS_NATURE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CONTRACT_TITLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONTRACT_TITLE",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "PERSON_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PERSON_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "POLICY_INSURED_ID",
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (345, N'{
            "tableName": "t_clm_policy"
        }', NULL, NULL, N'{
            "schema": "edw_stage",
            "table": "t_clm_policy"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": null,
            "writeBehavior": "insert",
            "sqlWriterUseTableLock": true,
            "disableMetricsCollection": false,
            "upsertSettings": null
        }', N'{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "POLICY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "POLICY_ID",
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
                            "name": "ORGAN_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ORGAN_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PRODUCT_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PRODUCT_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "EFF_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "EFF_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "EXP_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "EXP_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "PREMIUM_IS_PAID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PREMIUM_IS_PAID",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "REINSURENCE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REINSURENCE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CATEGORY_REINS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CATEGORY_REINS",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PREMIUM",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PREMIUM",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ENDO_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ENDO_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_REMARK",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_CLAUSES",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_CLAUSES",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "POLICY_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "POLICY_DESC",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "OPEN_POLICY_INFO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OPEN_POLICY_INFO",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CERTIFICATE_INFO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CERTIFICATE_INFO",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "GROUP_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "GROUP_FLAG",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MANUAL_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MANUAL_FLAG",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ENDO_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ENDO_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COIN_OUR_SHARE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "COIN_OUR_SHARE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "COIN_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COIN_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "COIN_LEADER_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COIN_LEADER_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "PLAN_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PLAN_NAME",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CURRENCY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CURRENCY_CODE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REINSURANCE_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REINSURANCE_FLAG",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "MASTER_POLICY_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MASTER_POLICY_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUM_INSURED",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "SUM_INSURED",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "EXT_CONTENT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "EXT_CONTENT",
                            "type": "String",
                            "physicalType": "text"
                        }
                    },
                    {
                        "source": {
                            "name": "CONFIRM_SEQUENCE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CONFIRM_SEQUENCE_NO",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "STATE_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RELATED_POLICY_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RELATED_POLICY_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RENEWAL_TIMES",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RENEWAL_TIMES",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "LIMIT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "LIMIT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DEDUCTIBLE_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DEDUCTIBLE_ID",
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
                            "physicalType": "datetime"
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
                            "physicalType": "datetime"
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
                            "physicalType": "text"
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
                            "name": "RETROACTIVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "RETROACTIVE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "COMPLEMENTARY_EXTENDED_PERIOD",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "COMPLEMENTARY_EXTENDED_PERIOD",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "SUPPLEMENTARY_EXTENDED_PERIOD",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "SUPPLEMENTARY_EXTENDED_PERIOD",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURANCE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURANCE_TYPE",
                            "type": "String",
                            "physicalType": "char"
                        }
                    },
                    {
                        "source": {
                            "name": "FIXED_EXCHANGE_RATE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "FIXED_EXCHANGE_RATE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIM_MADE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIM_MADE",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "EXTEND_REPORTING_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "EXTEND_REPORTING_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "MAINTAINANCE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "MAINTAINANCE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime"
                        }
                    },
                    {
                        "source": {
                            "name": "SME_LCR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SME_LCR",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLEMENT_OPTION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLEMENT_OPTION",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PML",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "PML",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "BROKER_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BROKER_ID",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BROKER_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BROKER_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CEDING_COMPANY_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CEDING_COMPANY_NAME",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CEDING_COMPANY_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CEDING_COMPANY_ID",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DIRECT_OR_ASSUMED_INDICATOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DIRECT_OR_ASSUMED_INDICATOR",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "AW_POLICY_ID",
                            "type": "String"
                        },
                        "sink": {
                            "name": "AW_POLICY_ID",
                            "type": "String",
                            "physicalType": "varchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MAINTENANCE_PERIOD_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "MAINTENANCE_PERIOD_DATE",
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
        }', N'MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel', N'[
            "Sandbox",
            "Trigger_mqq"
        ]', N'{
            "dataLoadingBehavior": "FullLoad",
            "watermarkColumnName": null,
            "watermarkColumnType": null,
            "watermarkColumnStartValue": null
        }', N'{              "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00"          }', N'{              "SelectStatement": "SELECT * FROM "          }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (356, N'{
            "schema": "dbo",
            "table": "SubjectivityDocument"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "SubjectivityDocument"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate"
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"DocumentId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"DocumentId","type":"Guid"}},{"source":{"name":"AccountSubjectivityId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountSubjectivityId","type":"Guid"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[              "Sandbox",              "Trigger_1i1"          ]', N'{"dataLoadingBehavior": "DeltaLoad", "watermarkColumnName": "CreatedDate", "watermarkColumnType": "DateTime", "watermarkColumnNameUpdate": "UpdatedDate", "watermarkColumnNameUpdatType": "DateTime", "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"}', N'{ "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00" }', N'{ "SelectStatement": "SELECT * FROM " }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (360, N'{
            "schema": "dbo",
            "table": "AccountRequirement"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "AccountRequirement"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate"
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"AccountId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"AccountId","type":"Guid"}},{"source":{"name":"Message","type":"String","physicalType":"nvarchar"},"sink":{"name":"Message","type":"String"}},{"source":{"name":"Prevent","type":"String","physicalType":"nvarchar"},"sink":{"name":"Prevent","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[              "Sandbox",              "Trigger_1i1"          ]', N'{"dataLoadingBehavior": "DeltaLoad", "watermarkColumnName": "CreatedDate", "watermarkColumnType": "DateTime", "watermarkColumnNameUpdate": "UpdatedDate", "watermarkColumnNameUpdatType": "DateTime", "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"}', N'{ "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00" }', N'{ "SelectStatement": "SELECT * FROM " }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (357, N'{
            "schema": "dbo",
            "table": "WebhookRequestLog"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WebhookRequestLog"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate"
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"Id","type":"Guid"}},{"source":{"name":"RequestLog","type":"String","physicalType":"nvarchar"},"sink":{"name":"RequestLog","type":"String"}},{"source":{"name":"Type","type":"String","physicalType":"nvarchar"},"sink":{"name":"Type","type":"String"}},{"source":{"name":"Status","type":"String","physicalType":"nvarchar"},"sink":{"name":"Status","type":"String"}},{"source":{"name":"ErrorMessage","type":"String","physicalType":"nvarchar"},"sink":{"name":"ErrorMessage","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[              "Sandbox",              "Trigger_1i1"          ]', N'{"dataLoadingBehavior": "DeltaLoad", "watermarkColumnName": "CreatedDate", "watermarkColumnType": "DateTime", "watermarkColumnNameUpdate": "UpdatedDate", "watermarkColumnNameUpdatType": "DateTime", "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"}', N'{ "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00" }', N'{ "SelectStatement": "SELECT * FROM " }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (358, N'{
            "schema": "dbo",
            "table": "WorkflowStepRole"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkflowStepRole"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate"
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"WorkFlowStepId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkFlowStepId","type":"Guid"}},{"source":{"name":"RoleId","type":"String","physicalType":"nvarchar"},"sink":{"name":"RoleId","type":"String"}},{"source":{"name":"RoleName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RoleName","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[              "Sandbox",              "Trigger_1i1"          ]', N'{"dataLoadingBehavior": "DeltaLoad", "watermarkColumnName": "CreatedDate", "watermarkColumnType": "DateTime", "watermarkColumnNameUpdate": "UpdatedDate", "watermarkColumnNameUpdatType": "DateTime", "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"}', N'{ "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00" }', N'{ "SelectStatement": "SELECT * FROM " }', 0, 1)
INSERT [edw_stage].[ControlLoadTable] ([Id], [SourceObjectSettings], [SourceConnectionSettingsName], [CopySourceSettings], [SinkObjectSettings], [SinkConnectionSettingsName], [CopySinkSettings], [CopyActivitySettings], [TopLevelPipelineName], [TriggerName], [DataLoadingBehaviorSettings], [LastExecution], [CustomScript], [TaskId], [CopyEnabled]) VALUES (359, N'{
            "schema": "dbo",
            "table": "WorkTaskRole"
        }', NULL, N'{
            "isolationLevel": "ReadUncommitted",
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        }', N'{
            "schema": "edw_stage",
            "table": "WorkTaskRole"
        }', NULL, N'{
            "preCopyScript": null,
            "tableOption": "autoCreate"
        }', N'{"translator":{"type":"TabularTranslator","mappings":[{"source":{"name":"Id","type":"Int32","physicalType":"int"},"sink":{"name":"Id","type":"Int32"}},{"source":{"name":"WorkTaskId","type":"Guid","physicalType":"uniqueidentifier"},"sink":{"name":"WorkTaskId","type":"Guid"}},{"source":{"name":"RoleId","type":"String","physicalType":"nvarchar"},"sink":{"name":"RoleId","type":"String"}},{"source":{"name":"RoleName","type":"String","physicalType":"nvarchar"},"sink":{"name":"RoleName","type":"String"}},{"source":{"name":"ExternalSourceId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceId","type":"String"}},{"source":{"name":"CreatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"CreatedDate","type":"DateTime"}},{"source":{"name":"UpdatedDate","type":"DateTime","physicalType":"datetime2"},"sink":{"name":"UpdatedDate","type":"DateTime"}},{"source":{"name":"ExternalSourceUniqueId","type":"String","physicalType":"nvarchar"},"sink":{"name":"ExternalSourceUniqueId","type":"String"}}],"typeConversion":true,"typeConversionSettings":{"allowDataTruncation":true,"treatBooleanAsNumber":false}}}', N'MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel', N'[              "Sandbox",              "Trigger_1i1"          ]', N'{"dataLoadingBehavior": "DeltaLoad", "watermarkColumnName": "CreatedDate", "watermarkColumnType": "DateTime", "watermarkColumnNameUpdate": "UpdatedDate", "watermarkColumnNameUpdatType": "DateTime", "watermarkColumnStartValue": "1900-01-01T00:00:00.000Z"}', N'{ "LastExecutionDate": "0000-00-00T00:00:00.0000000Z",              "LastExecutionTime": "00:00:00" }', N'{ "SelectStatement": "SELECT * FROM " }', 0, 1)

