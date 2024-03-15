update [edw_stage].[ControlLoadTable]
set CopyActivitySettings = '{
	"translator": {
		"type": "TabularTranslator",
		"mappings": [
			{
				"source": {
					"name": "PARTY_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PARTY_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "CASE_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "CASE_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "INSURED_RELATION",
					"type": "String"
				},
				"sink": {
					"name": "INSURED_RELATION",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "SEQ_NO",
					"type": "String"
				},
				"sink": {
					"name": "SEQ_NO",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "CERTI_TYPE",
					"type": "String"
				},
				"sink": {
					"name": "CERTI_TYPE",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "CERTI_CODE",
					"type": "String"
				},
				"sink": {
					"name": "CERTI_CODE",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "PARTY_NAME",
					"type": "String"
				},
				"sink": {
					"name": "PARTY_NAME",
					"type": "String",
					"physicalType": "text"
				}
			},
			{
				"source": {
					"name": "PARTY_ROLE",
					"type": "String"
				},
				"sink": {
					"name": "PARTY_ROLE",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "LICENSE_NO",
					"type": "String"
				},
				"sink": {
					"name": "LICENSE_NO",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "LICENSE_TYPE",
					"type": "String"
				},
				"sink": {
					"name": "LICENSE_TYPE",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "LICENSE_INITIAL_DATE",
					"type": "DateTime"
				},
				"sink": {
					"name": "LICENSE_INITIAL_DATE",
					"type": "DateTime",
					"physicalType": "datetime"
				}
			},
			{
				"source": {
					"name": "LICENSE_EXPIRY_DATE",
					"type": "DateTime"
				},
				"sink": {
					"name": "LICENSE_EXPIRY_DATE",
					"type": "DateTime",
					"physicalType": "datetime"
				}
			},
			{
				"source": {
					"name": "PTY_PARTY_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PTY_PARTY_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "PTY_ADDRESS_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PTY_ADDRESS_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "PTY_ACCOUNT_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PTY_ACCOUNT_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "DYNAMIC_FIELDS",
					"type": "String"
				},
				"sink": {
					"name": "DYNAMIC_FIELDS",
					"type": "String",
					"physicalType": "text"
				}
			},
			{
				"source": {
					"name": "BUSINESS_OBJECT_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "BUSINESS_OBJECT_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "INSERT_BY",
					"type": "Decimal"
				},
				"sink": {
					"name": "INSERT_BY",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "INSERT_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "INSERT_TIME",
					"type": "DateTime",
					"physicalType": "datetime"
				}
			},
			{
				"source": {
					"name": "UPDATE_BY",
					"type": "Decimal"
				},
				"sink": {
					"name": "UPDATE_BY",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "UPDATE_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "UPDATE_TIME",
					"type": "DateTime",
					"physicalType": "datetime"
				}
			},
			{
				"source": {
					"name": "PTY_CONTACT_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PTY_CONTACT_ID",
					"type": "Decimal",
					"physicalType": "decimal"
				}
			},
			{
				"source": {
					"name": "NEW_ROLE_TYPE",
					"type": "String"
				},
				"sink": {
					"name": "NEW_ROLE_TYPE",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "EMAIL",
					"type": "String"
				},
				"sink": {
					"name": "EMAIL",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "LEGAL_NAME_UWS",
					"type": "String"
				},
				"sink": {
					"name": "LEGAL_NAME_UWS",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "PAYEE_NAME_UWS",
					"type": "String"
				},
				"sink": {
					"name": "PAYEE_NAME_UWS",
					"type": "String",
					"physicalType": "varchar"
				}
			},
			{
				"source": {
					"name": "EXPERT_SUBTYPE_ROLE",
					"type": "String"
				},
				"sink": {
					"name": "EXPERT_SUBTYPE_ROLE",
					"type": "String",
					"physicalType": "varchar"
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
where JSON_value(SourceObjectSettings,'$.tableName') = 't_clm_party'