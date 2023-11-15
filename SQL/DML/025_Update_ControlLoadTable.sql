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
					"name": "ReferralState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ReferralState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsPolicyChange",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsPolicyChange",
					"type": "Boolean"
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
					"name": "MustClear",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustClear",
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
					"name": "IsCreatingFromOcr",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsCreatingFromOcr",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "MustRate",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustRate",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ChangeOccuredSinceLastTransaction",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "ChangeOccuredSinceLastTransaction",
					"type": "Boolean"
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
					"name": "FailedClearance",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "FailedClearance",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "RateServiceName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RateServiceName",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RuleServiceName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RuleServiceName",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RiskStateCodeSet",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "RiskStateCodeSet",
					"type": "Boolean"
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
					"name": "FormServiceName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "FormServiceName",
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
					"name": "NewBrokerId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "NewBrokerId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "NewBrokerageId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "NewBrokerageId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "NotificationBrokerId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "NotificationBrokerId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "RelatedAccountsId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "RelatedAccountsId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "CopyOfAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "CopyOfAccountId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "CloseReasonType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CloseReasonType",
					"type": "String"
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
					"name": "IsReviseBinder",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsReviseBinder",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ExternalSourceGroupId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ExternalSourceGroupId",
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
					"name": "BillToType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "BillToType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalStatus",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RenewalStatus",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "RenewalAccountId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "CancellationNoticeCancellationEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "CancellationNoticeCancellationEffectiveDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "IsRenewalLapsePending",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRenewalLapsePending",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "IsUnderCancellationNotice",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsUnderCancellationNotice",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "RenewalLapsePendingAsOfDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "RenewalLapsePendingAsOfDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "MustCheckForms",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustCheckForms",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "MustCheckRules",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustCheckRules",
					"type": "Boolean"
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
					"name": "CancellationRequestedEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "CancellationRequestedEffectiveDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "CancellationRequestedReason",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CancellationRequestedReason",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsCancellationRequested",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsCancellationRequested",
					"type": "Boolean"
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
					"name": "CopyOfAccountNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CopyOfAccountNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalOfAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "RenewalOfAccountId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "IsReviseQuote",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsReviseQuote",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ReviseQuoteTransactionId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ReviseQuoteTransactionId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "NonRenewalStateNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NonRenewalStateNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "NonRenewalStateSubNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NonRenewalStateSubNote",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsConditionalRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsConditionalRenewal",
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
where SourceObjectSettings like '%"Account"%';

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
			}
		],
		"typeConversion": true,
		"typeConversionSettings": {
			"allowDataTruncation": true,
			"treatBooleanAsNumber": false
		}
	}
}'
where SourceObjectSettings like '%"AccountTransactionVersion"%';