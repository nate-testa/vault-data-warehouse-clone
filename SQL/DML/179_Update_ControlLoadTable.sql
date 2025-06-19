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
			},
			{
				"source": {
					"name": "LicenseType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LicenseType",
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
where JSON_value(SourceObjectSettings,'$.table') = '"BrokerageLicense"';