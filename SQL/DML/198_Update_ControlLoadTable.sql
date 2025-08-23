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
			},
			{
				"source": {
					"name": "Disabled",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "Disabled",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "UserEmailConfirmed",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "UserEmailConfirmed",
					"type": "Boolean"
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
			}
		],
		"typeConversion": true,
		"typeConversionSettings": {
			"allowDataTruncation": true,
			"treatBooleanAsNumber": false
		}
	}
}'
where JSON_value(SourceObjectSettings,'$.table') = 'Broker';