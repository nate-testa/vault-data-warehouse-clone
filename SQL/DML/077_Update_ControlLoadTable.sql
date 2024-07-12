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
					"name": "VersionObjectId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "VersionObjectId",
					"type": "Int32"
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
					"name": "Field",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Field",
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
					"name": "DataType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "DataType",
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
					"name": "Group",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Group",
					"type": "String"
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
					"type": "Boolean"
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
					"name": "IsHidden",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsHidden",
					"type": "Boolean"
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
					"name": "IsDisabled",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsDisabled",
					"type": "Boolean"
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
					"name": "IgnorePolicyChangeTracking",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IgnorePolicyChangeTracking",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsOverrideByUser",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsOverrideByUser",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "OverrideByUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "OverrideByUserId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "ReferenceObjectId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ReferenceObjectId",
					"type": "Int32"
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
					"name": "ShowOnReferencedField",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "ShowOnReferencedField",
					"type": "Boolean"
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
					"type": "Boolean"
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
					"type": "String"
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
					"type": "String"
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
					"type": "Boolean"
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
					"name": "ValueBlob",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ValueBlob",
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersionObjectField';