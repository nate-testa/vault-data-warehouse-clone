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
					"name": "Coverage",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Coverage",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Premium",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "Premium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "PremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "PremiumDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "ProRateFactor",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "ProRateFactor",
					"type": "Decimal"
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
					"name": "RoundPremiumToNearestDollar",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "RoundPremiumToNearestDollar",
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
					"name": "AsLob",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AsLob",
					"type": "String"
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
					"name": "PremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "PremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "Commission",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "Commission",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CommissionDelta",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CommissionDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CommissionDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CommissionDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CommissionPercent",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CommissionPercent",
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
			},
			{
				"source": {
					"name": "ObjectId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ObjectId",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "ObjectUniqueId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ObjectUniqueId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "CededPremium",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CededPremium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CededPremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CededPremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CededPremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "CededPremiumDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "StatePremium",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "StatePremium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "StatePremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "StatePremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "StatePremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal",
					"scale": 4,
					"precision": 16
				},
				"sink": {
					"name": "StatePremiumDeltaProRated",
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionCoveragePremium';