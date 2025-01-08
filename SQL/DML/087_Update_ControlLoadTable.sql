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
					"name": "AssignedUserId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AssignedUserId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "WorkTaskState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "WorkTaskState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Priority",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Priority",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DueDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "DueDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "AbandonedReason",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AbandonedReason",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IsClosed",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsClosed",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "InsuredId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "InsuredId",
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
					"name": "PreviousTaskId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "PreviousTaskId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "TaskName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TaskName",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "WorkflowId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "WorkflowId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "WorkflowStepId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "WorkflowStepId",
					"type": "Guid"
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
					"name": "CreatedById",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "CreatedById",
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
					"name": "ConcurrencyId",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ConcurrencyId",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "FinishedById",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "FinishedById",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "FinishedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "FinishedDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "SuspenseUntilDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "SuspenseUntilDate",
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
where JSON_value(SourceObjectSettings,'$.table') = 'WorkTask';

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
					"name": "WorkflowId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "WorkflowId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "ParentStepId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ParentStepId",
					"type": "Guid"
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
					"name": "DueDays",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "DueDays",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "Priority",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Priority",
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
					"name": "StepNumber",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "StepNumber",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "TriggerAssignTo",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerAssignTo",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TriggerEvent",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerEvent",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TriggerType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CompleteOnCreate",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "CompleteOnCreate",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "SuspenseInDays",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "SuspenseInDays",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "TriggerByUser",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerByUser",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TriggerByProgram",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerByProgram",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TriggerByEndorsementPremiumType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerByEndorsementPremiumType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TriggerSuspenseOnCreate",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TriggerSuspenseOnCreate",
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
where JSON_value(SourceObjectSettings,'$.table') = 'WorkflowStep';