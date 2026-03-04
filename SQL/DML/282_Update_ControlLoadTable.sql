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
          "name": "IssueId",
          "type": "Guid",
          "physicalType": "uniqueidentifier"
        },
        "sink": {
          "name": "IssueId",
          "type": "Guid"
        }
      },
      {
        "source": {
          "name": "ReferralLevel",
          "type": "Int32",
          "physicalType": "int"
        },
        "sink": {
          "name": "ReferralLevel",
          "type": "Int32"
        }
      },
      {
        "source": {
          "name": "Message",
          "type": "String",
          "physicalType": "nvarchar"
        },
        "sink": {
          "name": "Message",
          "type": "String"
        }
      },
      {
        "source": {
          "name": "CanRefer",
          "type": "Boolean",
          "physicalType": "bit"
        },
        "sink": {
          "name": "CanRefer",
          "type": "Boolean"
        }
      },
      {
        "source": {
          "name": "IsApproved",
          "type": "Boolean",
          "physicalType": "bit"
        },
        "sink": {
          "name": "IsApproved",
          "type": "Boolean"
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
          "name": "ExternalApplyScope",
          "type": "String",
          "physicalType": "nvarchar"
        },
        "sink": {
          "name": "ExternalApplyScope",
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
where JSON_value(SourceObjectSettings,'$.table') = 'AccountTransactionIssue';