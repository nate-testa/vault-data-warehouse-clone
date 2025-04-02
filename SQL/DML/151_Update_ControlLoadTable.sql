update [edw_stage].[ControlLoadTable]
set CopyActivitySettings = '{
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
                            "name": "Required",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "Required",
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "name": "IsCompleted",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsCompleted",
                            "type": "Boolean",
                            "physicalType": "bit"
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
                            "name": "IsSignaturePackage",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsSignaturePackage",
                            "type": "Boolean",
                            "physicalType": "bit"
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
                            "type": "Boolean",
                            "physicalType": "bit"
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
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "AddedByRule",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "AddedByRule",
                            "type": "Boolean",
                            "physicalType": "bit"
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
                            "type": "Boolean",
                            "physicalType": "bit"
                        }
                    },
                    {
                        "source": {
                            "name": "AddedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "AddedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    },
                    {
                        "source": {
                            "name": "CompletedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "CompletedByUserId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        }
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountSubjectivity';