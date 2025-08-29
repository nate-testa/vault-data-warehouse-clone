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
					"name": "ProductId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ProductId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Int32",
					"physicalType": "int"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "Decimal",
					"physicalType": "decimal"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
			},
			{
				"source": {
					"name": "FailedClearance",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "FailedClearance",
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"name": "NonRenewalState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NonRenewalState",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "InitialPolicyNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "InitialPolicyNumber",
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Int32",
					"physicalType": "int"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "DateTime",
					"physicalType": "datetime2"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
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
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "IsCopiedFromNonRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsCopiedFromNonRenewal",
					"type": "Boolean",
					"physicalType": "bit"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "String",
					"physicalType": "nvarchar"
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
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "CanChangeRiskState",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "CanChangeRiskState",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "RenewalReviewStartDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "RenewalReviewStartDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "IsRewritten",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRewritten",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "RewrittenAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "RewrittenAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "RewrittenFromAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "RewrittenFromAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "RewrittenIndex",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "RewrittenIndex",
					"type": "Int32",
					"physicalType": "int"
				}
			},
			{
				"source": {
					"name": "IsPendingCancel",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsPendingCancel",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "AdjustedInflationPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "AdjustedInflationPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "PriorTotalPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "PriorTotalPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "ProductSchemaVersionId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ProductSchemaVersionId",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "IsRenewalReviewCreated",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRenewalReviewCreated",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "PolicyChangeRequest",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PolicyChangeRequest",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "PriorPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "PriorPremium",
					"type": "Decimal",
					"physicalType": "decimal"
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
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "BrokerOfRecordChangeApplied",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "BrokerOfRecordChangeApplied",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "BrokerOfRecordChangeAppliedToAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "BrokerOfRecordChangeAppliedToAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "CopiedToAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "CopiedToAccountId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "CopiedToAccountNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CopiedToAccountNumber",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "IsIntegrationDisable",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsIntegrationDisable",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "RenewalCapFactor",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "RenewalCapFactor",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "RenewalCapPercent",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "RenewalCapPercent",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "IsRenewalRequoted",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsRenewalRequoted",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "IsExcessCoverage",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsExcessCoverage",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "IsOfferedAtLeastOne",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsOfferedAtLeastOne",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "PremiumChangedSincePriorFirstTransactionPercentage",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "PremiumChangedSincePriorFirstTransactionPercentage",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "PriorInspectionOrdered",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "PriorInspectionOrdered",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "PendingNonRenewalEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "PendingNonRenewalEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "CopyOnNonRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "CopyOnNonRenewal",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "InProgressStartedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "InProgressStartedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "InProgressStartedUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "InProgressStartedUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "IsInternalCreated",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsInternalCreated",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "IsPolicyChangeRelatedToInspection",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsPolicyChangeRelatedToInspection",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "PartnerDomain",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PartnerDomain",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "ExternalSubmitDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "ExternalSubmitDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "FirstBindRequestDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "FirstBindRequestDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "FirstExternalSubmitUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "FirstExternalSubmitUserId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "FirstOfferedDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "FirstOfferedDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "FirstResponseDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "FirstResponseDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "NumberOfRevisions",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "NumberOfRevisions",
					"type": "Int32",
					"physicalType": "int"
				}
			},
			{
				"source": {
					"name": "IsInspectionCompleted",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsInspectionCompleted",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "LatestInspectionDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "LatestInspectionDateTime",
					"type": "DateTime",
					"physicalType": "datetime2"
				}
			},
			{
				"source": {
					"name": "CurrentOrBoundGrossPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "CurrentOrBoundGrossPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "CurrentOrBoundTotalPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "CurrentOrBoundTotalPremium",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "RenewalChangeNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RenewalChangeNote",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "PlainTextRenewalChangeNote",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PlainTextRenewalChangeNote",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "InsuranceRateScore",
					"type": "Decimal",
					"physicalType": "decimal"
				},
				"sink": {
					"name": "InsuranceRateScore",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "IsPremiumSelectedByUser",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsPremiumSelectedByUser",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "MustReviewBindRequest",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustReviewBindRequest",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "MustReviewQuote",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MustReviewQuote",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "ShowPremium",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "ShowPremium",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "UseProgram",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "UseProgram",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "SubmissionCloseReasonCarrier",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "SubmissionCloseReasonCarrier",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "SubmissionCloseReasonCategory",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "SubmissionCloseReasonCategory",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "SubmissionCloseReasonDetailOther",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "SubmissionCloseReasonDetailOther",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "SubmissionCloseReasonDetails",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "SubmissionCloseReasonDetails",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "TargetAccount",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TargetAccount",
					"type": "String",
					"physicalType": "nvarchar"
				}
			},
			{
				"source": {
					"name": "IsForecast",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsForecast",
					"type": "Boolean",
					"physicalType": "bit"
				}
			},
			{
				"source": {
					"name": "RenewalViewShow",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "RenewalViewShow",
					"type": "Boolean",
					"physicalType": "bit"
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
where JSON_value(SourceObjectSettings,'$.table') = 'Account';