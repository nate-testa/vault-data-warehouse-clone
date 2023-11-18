update edw_stage.ControlLoadTable
set CopyActivitySettings = '{
	"translator": {
		"type": "TabularTranslator",
		"mappings": [
			{
				"source": {
					"name": "USER_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "USER_ID",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "ORG_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "ORG_ID",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "PASSWORD",
					"type": "String"
				},
				"sink": {
					"name": "PASSWORD",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "REAL_NAME",
					"type": "String"
				},
				"sink": {
					"name": "REAL_NAME",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CREATE_DATE",
					"type": "DateTime"
				},
				"sink": {
					"name": "CREATE_DATE",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "USER_NAME",
					"type": "String"
				},
				"sink": {
					"name": "USER_NAME",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PASSWORD_CHANGE",
					"type": "DateTime"
				},
				"sink": {
					"name": "PASSWORD_CHANGE",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "NEED_CHANGE_PASS",
					"type": "String"
				},
				"sink": {
					"name": "NEED_CHANGE_PASS",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DEFAULT_LANG",
					"type": "String"
				},
				"sink": {
					"name": "DEFAULT_LANG",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "USER_DISABLE",
					"type": "String"
				},
				"sink": {
					"name": "USER_DISABLE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DISABLE_CAUSE",
					"type": "String"
				},
				"sink": {
					"name": "DISABLE_CAUSE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "INVALID_LOGIN",
					"type": "Decimal"
				},
				"sink": {
					"name": "INVALID_LOGIN",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "LATEST_IP",
					"type": "String"
				},
				"sink": {
					"name": "LATEST_IP",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LATEST_IP_OLD",
					"type": "String"
				},
				"sink": {
					"name": "LATEST_IP_OLD",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LATEST_LOGIN_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "LATEST_LOGIN_TIME",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "LATEST_LOGIN_OLD",
					"type": "DateTime"
				},
				"sink": {
					"name": "LATEST_LOGIN_OLD",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "LATEST_LOGOUT_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "LATEST_LOGOUT_TIME",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "LATEST_ACCESS_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "LATEST_ACCESS_TIME",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "USER_TYPE",
					"type": "Decimal"
				},
				"sink": {
					"name": "USER_TYPE",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "PARTY_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "PARTY_ID",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "PARTY_ROLE",
					"type": "String"
				},
				"sink": {
					"name": "PARTY_ROLE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DEPT_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "DEPT_ID",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "EMAIL",
					"type": "String"
				},
				"sink": {
					"name": "EMAIL",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DISABLE_DATE",
					"type": "DateTime"
				},
				"sink": {
					"name": "DISABLE_DATE",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "CUSTOMER_ID",
					"type": "String"
				},
				"sink": {
					"name": "CUSTOMER_ID",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ID_CARD",
					"type": "String"
				},
				"sink": {
					"name": "ID_CARD",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ACTIVATE_PASSWORD",
					"type": "String"
				},
				"sink": {
					"name": "ACTIVATE_PASSWORD",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "USER_ON_LEAVE",
					"type": "String"
				},
				"sink": {
					"name": "USER_ON_LEAVE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "DISABLE_CAUSE_DETAIL",
					"type": "String"
				},
				"sink": {
					"name": "DISABLE_CAUSE_DETAIL",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "INSERT_BY",
					"type": "Decimal"
				},
				"sink": {
					"name": "INSERT_BY",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "UPDATE_BY",
					"type": "Decimal"
				},
				"sink": {
					"name": "UPDATE_BY",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "INSERT_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "INSERT_TIME",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "UPDATE_TIME",
					"type": "DateTime"
				},
				"sink": {
					"name": "UPDATE_TIME",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "DYNAMIC_FIELDS",
					"type": "String"
				},
				"sink": {
					"name": "DYNAMIC_FIELDS",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MOBILE",
					"type": "String"
				},
				"sink": {
					"name": "MOBILE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ORGAN_ID",
					"type": "Decimal"
				},
				"sink": {
					"name": "ORGAN_ID",
					"type": "Decimal"
				}
			},
			{
				"source": {
					"name": "CODE",
					"type": "String"
				},
				"sink": {
					"name": "CODE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "STATUS",
					"type": "String"
				},
				"sink": {
					"name": "STATUS",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ON_LEAVE_FLAG",
					"type": "String"
				},
				"sink": {
					"name": "ON_LEAVE_FLAG",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "REGISTER_CODE",
					"type": "String"
				},
				"sink": {
					"name": "REGISTER_CODE",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "REGISTER_EXPIRE_DATE",
					"type": "DateTime"
				},
				"sink": {
					"name": "REGISTER_EXPIRE_DATE",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "TITLE",
					"type": "String"
				},
				"sink": {
					"name": "TITLE",
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
where JSON_value(SourceObjectSettings,'$.tableName') like '%t_pub_user';