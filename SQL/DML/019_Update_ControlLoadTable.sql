update [edw_stage].[ControlLoadTable]
set CopySinkSettings = '{              "preCopyScript": null,              "tableOption": "autoCreate",              "writeBehavior": "insert",              "sqlWriterUseTableLock": true,              "disableMetricsCollection": false,              "upsertSettings": null          }'
,CopySourceSettings = NULL
,DataLoadingBehaviorSettings = '{              "dataLoadingBehavior": "FullLoad",              "watermarkColumnName": null,              "watermarkColumnType": null,              "watermarkColumnStartValue": null          }'
where triggerName like '%Trigger_mqq%'
and SourceObjectSettings like '%"`t_clm_subclaim_type`"%';

UPDATE [edw_stage].[ControlLoadTable] SET CopyActivitySettings = '{
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
                            "name": "InsuredId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "InsuredId",
                            "type": "Guid"
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
                            "name": "BillToType",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "BillToType",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "BillToBrokerageId",
                            "type": "Guid",
                            "physicalType": "uniqueidentifier"
                        },
                        "sink": {
                            "name": "BillToBrokerageId",
                            "type": "Guid"
                        }
                    },
                    {
                        "source": {
                            "name": "IsFinanced",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsFinanced",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "FinanceCompanyName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "FinanceCompanyName",
                            "type": "String"
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
                            "name": "ReferenceCode",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ReferenceCode",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "BillingAddressIsMailingAddress",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "BillingAddressIsMailingAddress",
                            "type": "Boolean"
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
                            "name": "ContactInfoIsInsured",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "ContactInfoIsInsured",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactEntityName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactEntityName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactPrefix",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactPrefix",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactFirstName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactFirstName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactMiddleName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactMiddleName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactLastName",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactLastName",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactSuffix",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactSuffix",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactPhone",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactPhone",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "ContactEmail",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "ContactEmail",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "MortgageeLoanNumber",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "MortgageeLoanNumber",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PaymentPlan",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PaymentPlan",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "PaymentMethod",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "PaymentMethod",
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
                            "name": "AutoPayToken",
                            "type": "String",
                            "physicalType": "nvarchar"
                        },
                        "sink": {
                            "name": "AutoPayToken",
                            "type": "String"
                        }
                    },
                    {
                        "source": {
                            "name": "IsAutoPay",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsAutoPay",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "EmailUpdated",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "EmailUpdated",
                            "type": "Boolean"
                        }
                    },
                    {
                        "source": {
                            "name": "IsUserCreated",
                            "type": "Boolean",
                            "physicalType": "bit"
                        },
                        "sink": {
                            "name": "IsUserCreated",
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
        }' WHERE SourceObjectSettings LIKE '%"BillingAccount"%';