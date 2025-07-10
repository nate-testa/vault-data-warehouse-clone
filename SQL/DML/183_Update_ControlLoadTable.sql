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
					"name": "TaxIdNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TaxIdNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressLine1",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressLine1",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressLine2",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressLine2",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressCity",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressCity",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressZipCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressZipCode",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressCountry",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressCountry",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "Code",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Code",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ProducerId",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ProducerId",
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
					"name": "Dba",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Dba",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressCounty",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressCounty",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "HasProfilePhoto",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "HasProfilePhoto",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ReferenceCode",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "ReferenceCode",
					"type": "Int32"
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
					"name": "Status",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "Status",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AddressLineUnit",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AddressLineUnit",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "TaxIdNumberType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "TaxIdNumberType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "AgencyManagementSystem",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "AgencyManagementSystem",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "ClaimsContactEmail",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "ClaimsContactEmail",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressCity",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressCity",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressCountry",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressCountry",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressCounty",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressCounty",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressLine1",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressLine1",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressLine2",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressLine2",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressLineUnit",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressLineUnit",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressSameAsPrimary",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "CommissionAddressSameAsPrimary",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "CommissionAddressState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CommissionAddressZipCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CommissionAddressZipCode",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "EntityType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "EntityType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "EntityTypeLLC",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "EntityTypeLLC",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IVANSUserName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "IVANSUserName",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "IVANSYAccount",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "IVANSYAccount",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "InsuranceCompanyName",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "InsuranceCompanyName",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "InsurancePolicyEffectiveDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "InsurancePolicyEffectiveDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "InsurancePolicyExpirationDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "InsurancePolicyExpirationDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "InsurancePolicyLimit",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "InsurancePolicyLimit",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "InsurancePolicyNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "InsurancePolicyNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LegacySystemNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LegacySystemNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LexisNexisCompanyCodeSuffix",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LexisNexisCompanyCodeSuffix",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressCity",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressCity",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressCountry",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressCountry",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressCounty",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressCounty",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressLine1",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressLine1",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressLine2",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressLine2",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressLineUnit",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressLineUnit",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressSameAsPrimary",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "LocationAddressSameAsPrimary",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "LocationAddressState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "LocationAddressZipCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "LocationAddressZipCode",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressCity",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressCity",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressCountry",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressCountry",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressCounty",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressCounty",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressLine1",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressLine1",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressLine2",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressLine2",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressLineUnit",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressLineUnit",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressSameAsPrimary",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "MailingAddressSameAsPrimary",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "MailingAddressState",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressState",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "MailingAddressZipCode",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "MailingAddressZipCode",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "NewBusinessContactEmail",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "NewBusinessContactEmail",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PolicyChangeContactEmail",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PolicyChangeContactEmail",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PrimaryBrokerId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "PrimaryBrokerId",
					"type": "Guid"
				}
			},
			{
				"source": {
					"name": "PrimaryEmail",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PrimaryEmail",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "PrimaryPhoneNumber",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "PrimaryPhoneNumber",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "RenewalContactEmail",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "RenewalContactEmail",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "BrokerageType",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "BrokerageType",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "StatusUpdateDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "StatusUpdateDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "TerminatedDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "TerminatedDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "Tier",
					"type": "Int32",
					"physicalType": "int"
				},
				"sink": {
					"name": "Tier",
					"type": "Int32"
				}
			},
			{
				"source": {
					"name": "ContractDate",
					"type": "DateTime",
					"physicalType": "datetime2"
				},
				"sink": {
					"name": "ContractDate",
					"type": "DateTime"
				}
			},
			{
				"source": {
					"name": "IsNationalAgency",
					"type": "Boolean",
					"physicalType": "bit"
				},
				"sink": {
					"name": "IsNationalAgency",
					"type": "Boolean"
				}
			},
			{
				"source": {
					"name": "ServicingTeamId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				},
				"sink": {
					"name": "ServicingTeamId",
					"type": "Guid",
					"physicalType": "uniqueidentifier"
				}
			},
			{
				"source": {
					"name": "CanAccessCommercialProducts",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CanAccessCommercialProducts",
					"type": "String"
				}
			},
			{
				"source": {
					"name": "CanAccessPersonalProducts",
					"type": "String",
					"physicalType": "nvarchar"
				},
				"sink": {
					"name": "CanAccessPersonalProducts",
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
where JSON_value(SourceObjectSettings,'$.table') = 'BrokerAge';