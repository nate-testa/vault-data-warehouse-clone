update [edw_stage].[ControlLoadTable]
set CopyActivitySettings = '{
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
                            "name": "ValueDisplay",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ValueDisplay",
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
                    },
                    {
                        "source": {
                            "name": "StateCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "StateCode",
                            "type": "String",
                            "physicalType": "nvarchar"
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
                            "name": "ExternalVersionId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ExternalVersionId",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IsRenewal",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsRenewal",
                            "type": "Boolean",
                            "physicalType": "bit"
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
                    }
                ],
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        }'
where JSON_value(SourceObjectSettings,'$.table') = 'ProductObjectFieldValueDisplay';