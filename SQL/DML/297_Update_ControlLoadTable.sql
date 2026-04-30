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
					"name": "AccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "AccountId",
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
					"name": "PrimaryInsuredId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "PrimaryInsuredId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "PaymentFrom",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PaymentFrom",
					"type": "String"
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
					"name": "PaidVia",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PaidVia",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PaymentDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "PaymentDateTime",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "IsReversed",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsReversed",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsReversal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsReversal",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ReversalOfId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ReversalOfId",
					"type": "Int32"
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
					"name": "BillingAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "BillingAccountId",
					"type": "Guid"
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
					"name": "LineItemCategory",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LineItemCategory",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TransactionDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "TransactionDate",
					"type": "DateTime"
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountPayment';