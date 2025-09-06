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
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "AccountTransactionVersionId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "AccountTransactionVersionId",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "ParentObjectId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ParentObjectId",
					"type": "Int32"
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
					"name": "ObjectGroupIdentifier",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ObjectGroupIdentifier",
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
					"name": "MaxAllowed",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "MaxAllowed",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "IsForm",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsForm",
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
					"name": "TableIdentifier",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TableIdentifier",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "UniqueId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "UniqueId",
					"type": "Guid"
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
					"name": "IsDeletedOnPolicyChange",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsDeletedOnPolicyChange",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsDeletedOnRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsDeletedOnRenewal",
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
}'
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersionObject';