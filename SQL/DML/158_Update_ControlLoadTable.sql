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
					"name": "PolicyChangeNumber",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "PolicyChangeNumber",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "TransactionEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "TransactionEffectiveDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "ProRateFactor",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "ProRateFactor",
					"type": "Decimal"
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
					"name": "TotalPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "TotalPremium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "GrossPremiumOverride",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "GrossPremiumOverride",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "GrossPremiumDeltaProRatedOverride",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "GrossPremiumDeltaProRatedOverride",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "NetPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "NetPremium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "Commission",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "Commission",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "GrossPremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "GrossPremiumDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "NetPremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "NetPremiumDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CommissionDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal"
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
					"physicalType": "decimal"
				},
				"sink": {
					"name": "CommissionPercent",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "Cleared",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "Cleared",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "Referred",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "Referred",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsLatestBoundTransaction",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsLatestBoundTransaction",
					"type": "Boolean"
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
					"name": "Note",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Note",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "NotTakenReason",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NotTakenReason",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CancellationReason",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CancellationReason",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PolicyChangeNotes",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PolicyChangeNotes",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "BindDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "BindDate",
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
					"name": "GrossPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "GrossPremium",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "PreBindComplete",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "PreBindComplete",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ReferredByUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ReferredByUserId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "SubmitById",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "SubmitById",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "CreatedById",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CreatedById",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ReviewedById",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ReviewedById",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "ApproveNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ApproveNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DenyNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "DenyNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsRevision",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRevision",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "QuoteNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "QuoteNote",
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
					"name": "TotalPremiumDeltaProRated",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "TotalPremiumDeltaProRated",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CommissionDelta",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "CommissionDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "GrossPremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "GrossPremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "NetPremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "NetPremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "TotalPremiumDelta",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "TotalPremiumDelta",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "SubmitToBindById",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "SubmitToBindById",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "PolicyChangeGeneratedNotes",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PolicyChangeGeneratedNotes",
					"type": "String"
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
					"name": "NotTakenNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NotTakenNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IssuedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "IssuedDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "PreviousStage",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PreviousStage",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PreviousState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PreviousState",
					"type": "String"
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
					"name": "ReversalOfTransactionId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ReversalOfTransactionId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "IsExternallySubmitted",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsExternallySubmitted",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "TransactionReferenceCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TransactionReferenceCode",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "StateUpdateDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "StateUpdateDate",
					"type": "DateTime"
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
					"name": "DeclineNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "DeclineNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CancellationSubReason",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CancellationSubReason",
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransaction';