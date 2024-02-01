update [edw_stage].[ControlLoadTable]
set CopyActivitySettings = '{
            "translator": {
                "type": "TabularTranslator",
                "mappings": [
                    {
                        "source": {
                            "name": "OBJECT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OBJECT_ID",
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
                            "name": "CLAIMANT_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CLAIMANT_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "CLAIMANT_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLAIMANT_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DRIVER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBCLAIM_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBCLAIM_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RISK_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RISK_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_SEVERITY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_SEVERITY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OBJECT_PLACE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "OBJECT_PLACE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DAMAGE_DESC",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DAMAGE_DESC",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_IS_INSURED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVER_IS_INSURED",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_SUBROGATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_SUBROGATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_SALVAGE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_SALVAGE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "STATUS_CODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_USER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "APPRAISAL_USER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "APPRAISAL_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_APPROVER",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "APPRAISAL_APPROVER",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL_APPROVE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "APPRAISAL_APPROVE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "LAST_DOC_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LAST_DOC_FLAG",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RECEIVED_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "RECEIVED_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "WORKSHOP_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "WORKSHOP_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "PLACETOGO_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PLACETOGO_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "FRAUD_SCORE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "FRAUD_SCORE",
                            "type": "Decimal",
                            "physicalType": "decimal"
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
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TOTAL_LOSS_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TOTAL_LOSS_FLAG",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOSS_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOSS_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SALVAGE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SALVAGE_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBROGATION_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_OWNER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "CAR_OWNER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OWNER_ID",
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
                            "physicalType": "nvarchar"
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
                            "physicalType": "datetime2"
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
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "LITIGATION_FLAG",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LITIGATION_FLAG",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ASSIGN_BY",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "OWNER_ASSIGN_BY",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "OWNER_ASSIGN_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "OWNER_ASSIGN_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "ESTIMATED_LOSS_AMOUNT",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "ESTIMATED_LOSS_AMOUNT",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "ESTIMATED_LOSS_CURRENCY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ESTIMATED_LOSS_CURRENCY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_CAR_SERVICE_STATUS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RENTAL_CAR_SERVICE_STATUS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_CAR_COMPANY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "RENTAL_CAR_COMPANY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CAR_RENTAL_TOWN",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CAR_RENTAL_TOWN",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DAILY_RENTAL_FEE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "DAILY_RENTAL_FEE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "RENTAL_PERIOD",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "RENTAL_PERIOD",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TOTAL_RENTAL_FEE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TOTAL_RENTAL_FEE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "COMPANY_CARE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COMPANY_CARE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_PROVIDER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CARE_PROVIDER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_CALL_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CARE_CALL_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_SERVICE_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "CARE_SERVICE_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "CARE_OPERATOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CARE_OPERATOR",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURANCE_COMPANY",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURANCE_COMPANY",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "REMARK",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DRIVER_REMARK",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DRIVER_REMARK",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DRIVER_ID",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "TP_DRIVER_ID",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_DRIVER_BIRTH_DATE",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "TP_DRIVER_BIRTH_DATE",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_PLATE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_PLATE_NO",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "TP_TEL_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "TP_TEL_NO",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime"
                        },
                        "sink": {
                            "name": "STATUS_CHANGE_TIME",
                            "type": "DateTime",
                            "physicalType": "datetime2"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID_ONE",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID_ONE",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_ID_TWO",
                            "type": "Decimal"
                        },
                        "sink": {
                            "name": "INSURED_ID_TWO",
                            "type": "Decimal",
                            "physicalType": "decimal"
                        }
                    },
                    {
                        "source": {
                            "name": "SEVERITY_CODE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SEVERITY_CODE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "LOS_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SAL_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REASON",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUB_CLOSURE_REMARKS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "BUSINESS_CLASS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "BUSINESS_CLASS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "WORKPLACE_NO",
                            "type": "String"
                        },
                        "sink": {
                            "name": "WORKPLACE_NO",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "WORKPLACE_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "WORKPLACE_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ASSIGNMENT_OF_BENEFITS_CONTRACTOR",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ASSIGNMENT_OF_BENEFITS_CONTRACTOR",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "PUBLIC_ADJUSTER",
                            "type": "String"
                        },
                        "sink": {
                            "name": "PUBLIC_ADJUSTER",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ARBITRATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ARBITRATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "MEDIATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "MEDIATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "APPRAISAL",
                            "type": "String"
                        },
                        "sink": {
                            "name": "APPRAISAL",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "ALTERNATIVE_DISPUTE_RESOLUTION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "ALTERNATIVE_DISPUTE_RESOLUTION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NEUTRAL_EVALUATION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NEUTRAL_EVALUATION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLEMENT_CONFERENCE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLEMENT_CONFERENCE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SETTLEMENT_RESOLUTION",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SETTLEMENT_RESOLUTION",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "NON_FAMILY_MEMBER_USING_VEHICLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "NON_FAMILY_MEMBER_USING_VEHICLE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "YOUTHFUL_USING_VEHICLE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "YOUTHFUL_USING_VEHICLE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "DISTRACTED_DRIVING",
                            "type": "String"
                        },
                        "sink": {
                            "name": "DISTRACTED_DRIVING",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "INSURED_VEHICLE_DRIVER_INFLUENCED",
                            "type": "String"
                        },
                        "sink": {
                            "name": "INSURED_VEHICLE_DRIVER_INFLUENCED",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CATALYTIC_CONVERTER_THEFT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CATALYTIC_CONVERTER_THEFT",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "IS_CATALYTIC_CONVERTER_ANTI_THEFT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "IS_CATALYTIC_CONVERTER_ANTI_THEFT",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "CATALYTIC_CONVERTER_ANTI_THEFT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "CATALYTIC_CONVERTER_ANTI_THEFT",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "GLASS_REPAIR_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "GLASS_REPAIR_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "GLASS_TYPE",
                            "type": "String"
                        },
                        "sink": {
                            "name": "GLASS_TYPE",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SPLIT_LIABILITY_LIMITS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SPLIT_LIABILITY_LIMITS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SPLIT_PROPERTY_DAMAGE_LIMIT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SPLIT_PROPERTY_DAMAGE_LIMIT",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "COMBINED_SINGLE_LIMIT",
                            "type": "String"
                        },
                        "sink": {
                            "name": "COMBINED_SINGLE_LIMIT",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "SUBROGATION_STATUS_INDICATORS",
                            "type": "String"
                        },
                        "sink": {
                            "name": "SUBROGATION_STATUS_INDICATORS",
                            "type": "String",
                            "physicalType": "nvarchar"
                        }
                    },
                    {
                        "source": {
                            "name": "THIRD_PARTY_INSURANCE_COMPANY_NAME",
                            "type": "String"
                        },
                        "sink": {
                            "name": "THIRD_PARTY_INSURANCE_COMPANY_NAME",
                            "type": "String",
                            "physicalType": "nvarchar"
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
where TriggerName like '%Trigger_mqq%'
and SourceObjectSettings like '%"t_clm_object"%';