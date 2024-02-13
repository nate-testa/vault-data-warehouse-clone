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
					"name": "AccountTransactionId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "AccountTransactionId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "Amount",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "Amount",
					"type": "Decimal"
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
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Type",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Type",
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
					"name": "AppliesToPolicyChange",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "AppliesToPolicyChange",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "AmountDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "AmountDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "IsFullyEarned",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsFullyEarned",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "AmountDelta",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "AmountDelta",
					"type": "Decimal"
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
			},{
				"source": {
					"name": "CoverageId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "CoverageId",
					"type": "Guid"
				}
			},{
				"source": {
					"name": "RoundToNearest",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "RoundToNearest",
					"type": "Boolean"
				}
			},{
				"source": {
					"name": "TaxFullyEarnedFee",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "TaxFullyEarnedFee",
					"type": "Boolean"
				}
			},{
				"source": {
					"name": "TaxRate",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "TaxRate",
					"type": "Decimal"
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionTaxAndFee';