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
					"name": "ProductId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ProductId",
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
					"name": "UnderwriterUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "UnderwriterUserId",
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
					"name": "Stage",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Stage",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "State",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "State",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRenewal",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "Number",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "Number",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "PolicyNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PolicyNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalOfPolicyNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RenewalOfPolicyNumber",
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
					"name": "RateDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "RateDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "RiskStateCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RiskStateCode",
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
					"name": "RulesReferenceUrl",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RulesReferenceUrl",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "FormReferenceUrl",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "FormReferenceUrl",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CoInsuredId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "CoInsuredId",
					"type": "Guid"
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
					"name": "MinimumEarnedPremiumPercent",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "MinimumEarnedPremiumPercent",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "IsRenewed",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRenewed",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "NonRenewalState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NonRenewalState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalIndex",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "RenewalIndex",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "Program",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Program",
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
					"name": "OriginalEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "OriginalEffectiveDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "PremiumAnalyticsGrade",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PremiumAnalyticsGrade",
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionVersion';