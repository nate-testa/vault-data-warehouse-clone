DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "AccountRaterReference"
        },
        "SinkObjectSettings": {
            "table": "AccountRaterReference",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "BlobIdentifier",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "BlobIdentifier",
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ProductInternalName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ProductInternalName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ReferenceType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ReferenceType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "Version",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Version",
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
        "CopyEnabled": 0
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "AccountRelatedAddress"
        },
        "SinkObjectSettings": {
            "table": "AccountRelatedAddress",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ObjectUniqueId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ObjectUniqueId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "FieldGroup",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "FieldGroup",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FullAddress",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "FullAddress",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IsMailing",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsMailing",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "IsRisk",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsRisk",
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
        "CopyEnabled": 0
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "AccountRelatedProductCount"
        },
        "SinkObjectSettings": {
            "table": "AccountRelatedProductCount",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "Total",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "Total",
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "IsBound",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsBound",
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
        "CopyEnabled": 0
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "AccountReportDocument"
        },
        "SinkObjectSettings": {
            "table": "AccountReportDocument",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "ReportId",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "ReportId",
                            "type": "Int32",
                            "physicalType": "int"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
        "CopyEnabled": 0
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "BillingAccountLog"
        },
        "SinkObjectSettings": {
            "table": "BillingAccountLog",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "BillingAccountId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BillingAccountId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "AccountInvoiceId",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "AccountInvoiceId",
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "AccountVersionId",
                            "type": "Int32",
                            "physicalType": "int"
                        },
                        "sink": {
                            "name": "AccountVersionId",
                            "type": "Int32",
                            "physicalType": "int"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "Event",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Event",
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "name": "Error",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Error",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "Request",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Request",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "Proceeded",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "Proceeded",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "ProceededSuccess",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "ProceededSuccess",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "ProcessByName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ProcessByName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ProcessDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "ProcessDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "InsuredUpdate",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "InsuredUpdate",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "MovePolicy",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "MovePolicy",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "UpdateExistingBillingAccount",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "UpdateExistingBillingAccount",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "MoveNewBillingAccount",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "MoveNewBillingAccount",
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
        "CopyEnabled": 0
    },
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "CommissionGlobalExclusion"
        },
        "SinkObjectSettings": {
            "table": "CommissionGlobalExclusion",
            "schema": "edw_stage"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "KeepAtRenewalForStatesIfTerminated",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "KeepAtRenewalForStatesIfTerminated",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MustHaveCompanionProducts",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "MustHaveCompanionProducts",
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "CompanionProducts",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "CompanionProducts",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionPercentIfFail",
                            "type": "Decimal",
                            "physicalType": "decimal",
                            "scale": 4,
                            "precision": 16
                        },
                        "sink": {
                            "name": "CommissionPercentIfFail",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
            "table": "CommissionTier"
        },
        "SinkObjectSettings": {
            "table": "CommissionTier",
            "schema": "edw_stage"
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
            "table": "CommissionTierBrokerage"
        },
        "SinkObjectSettings": {
            "table": "CommissionTierBrokerage",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionTierId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "CommissionTierId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
                            "name": "EffectiveDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        },
                        "sink": {
                            "name": "EffectiveDate",
                            "type": "DateTime",
                            "physicalType": "datetime2"
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
            "table": "CommissionTierPercentage"
        },
        "SinkObjectSettings": {
            "table": "CommissionTierPercentage",
            "schema": "edw_stage"
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
                            "type": "Int32",
                            "physicalType": "int"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionTierId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "CommissionTierId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "CoverageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "CoverageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "State",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "State",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ProgramType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ProgramType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BusinessType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "BusinessType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CommissionPercent",
                            "type": "Decimal",
                            "physicalType": "decimal",
                            "scale": 4,
                            "precision": 16
                        },
                        "sink": {
                            "name": "CommissionPercent",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
                            "type": "DateTime",
                            "physicalType": "datetime2"
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
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "IsExpired",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsExpired",
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
                            "name": "ExternalSourceUniqueId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalSourceUniqueId",
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
            "table": "DocumentFolder"
        },
        "SinkObjectSettings": {
            "table": "DocumentFolder",
            "schema": "edw_stage"
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
                            "name": "DocumentFolderType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "DocumentFolderType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ParentFolderId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "ParentFolderId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
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
        "CopyEnabled": 0
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