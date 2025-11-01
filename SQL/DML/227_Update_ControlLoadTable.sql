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
					"name": "OptOut",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "OptOut",
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
					"name": "InternalCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "InternalCode",
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
}'
where JSON_value(SourceObjectSettings,'$.table') = 'InsuredMarketingPreference';