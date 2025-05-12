update [edw_stage].[ControlLoadTable]
set CopyEnabled = 1
,CopyActivitySettings = '{
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
					"name": "AccountTransactionVersionPremiumId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "AccountTransactionVersionPremiumId",
					"type": "Int32"
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
					"type": "String"
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
					"name": "RaterReferenceId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RaterReferenceId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RaterReferenceUrl",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RaterReferenceUrl",
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
					"name": "ExternalSourceUniqueId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ExternalSourceUniqueId",
					"type": "String"
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
					"type": "String"
				}
			},
			{
				"source": {
					"name": "EngineProvider",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "EngineProvider",
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
}'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersionPremiumRaterReference';

update [edw_stage].[ControlLoadTable]
set CopyEnabled = 1
,CopyActivitySettings = '{
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
			},
			{
				"source": {
					"name": "ExternalVersionId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ExternalVersionId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "EngineProvider",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "EngineProvider",
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
}'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountRaterReference';
