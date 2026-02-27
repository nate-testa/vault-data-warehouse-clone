IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_core'
and TABLE_name = 'tgrpel_master_policy')
BEGIN
CREATE TABLE edw_core.tgrpel_master_policy
(
grpel_master_policy_sk                                                   int NOT NULL IDENTITY(1,1),  
grpel_master_policy_no                                                   varchar(255) NOT NULL,
effective_dt                                                             date NOT NULL,
expiration_dt                                                            date NOT NULL,
transaction_effective_dt                                                 date NOT NULL,
transaction_seq_no                                                       int NOT NULL,
broker_id                                                                varchar(255) NOT NULL,
customer_id                                                              varchar(255) NOT NULL,
product_cd                                                               varchar(255) NOT NULL,
risk_state_cd                                                            varchar(255) NOT NULL,
insured_nm                                                               varchar(255),
insured_type                                                             varchar(255),
policy_status                                                            varchar(255),
mailing_address_line1                                                    varchar(255),  
mailing_address_line2                                                    varchar(255),
mailing_address_city_nm                                                  varchar(255),
mailing_address_state_cd                                                 varchar(255),
mailing_address_zip_cd                                                   varchar(255), 
mailing_address_county_nm                                                varchar(255),
mailing_address_country_nm                                               varchar(255),
insured_first_nm                                                         varchar(255),
insured_last_nm                                                          varchar(255),
mobile_phone_no                                                          varchar(255),
email                                                                    varchar(255),
enrollment_initial_start_dt                                              varchar(255),
enrollment_preiod_in_days                                                varchar(255),
enrollment_frequency                                                     varchar(255), 
override_enrollment_to_open_in                                           varchar(255),
auto_liability_limit_amt                                                 varchar(255),
no_of_average_homes                                                      varchar(255),
no_of_average_vehicles                                                   varchar(255),
no_of_average_watercraft                                                 varchar(255),
no_of_youthful_driver                                                    varchar(255),  
mvr_trigger_rule                                                         varchar(255), 
commission_pc                                                            varchar(255),
minimum_premium_amt                                                      varchar(255),
prior_nfp_policy_no                                                      varchar(255),
prior_nfp_policy_expiring_dt                                             varchar(255),
excess_liability_limit_1m_premium_amt                                    varchar(255), 
excess_liability_limit_1m_premium_amt_override                           varchar(255),
excess_liability_limit_3m_premium_amt                                    varchar(255),
excess_liability_limit_3m_premium_amt_override                           varchar(255),
excess_liability_limit_5m_premium_amt                                    varchar(255),
excess_liability_limit_5m_premium_amt_override                           varchar(255),
excess_liability_limit_10m_premium_amt                                   varchar(255),
excess_liability_limit_10m_premium_amt_override                          varchar(255),  
excess_liability_limit_15m_premium_amt                                   varchar(255),
excess_liability_limit_15m_premium_amt_override                          varchar(255),
excess_liability_limit_20m_premium_amt                                   varchar(255),
excess_liability_limit_20m_premium_amt_override                          varchar(255),
excess_liability_limit_30m_premium_amt                                   varchar(255), 
excess_liability_limit_30m_premium_amt_override                          varchar(255), 
uninsured_underinsured_motorist_liability_limit_1m_premium_amt           varchar(255),
uninsured_underinsured_motorist_liability_limit_1m_premium_amt_override  varchar(255), 
uninsured_underinsured_motorist_liability_limit_2m_premium_amt           varchar(255),
uninsured_underinsured_motorist_liability_limit_2m_premium_amt_override  varchar(255),
uninsured_underinsured_motorist_liability_limit_3m_premium_amt           varchar(255),
uninsured_underinsured_motorist_liability_limit_3m_premium_amt_override  varchar(255), 
uninsured_underinsured_motorist_liability_limit_5m_premium_amt           varchar(255),
uninsured_underinsured_motorist_liability_limit_5m_premium_amt_override  varchar(255),
uninsured_underinsured_motorist_liability_limit_10m_premium_amt          varchar(255),
uninsured_underinsured_motorist_liability_limit_10m_premium_amt_override varchar(255),
employment_practices_liability_limit_250_250_25_premium_amt              varchar(255),   
employment_practices_liability_limit_250_250_25_premium_amt_override     varchar(255), 
employment_practices_liability_limit_500_500_50_premium_amt              varchar(255),
employment_practices_liability_limit_500_500_50_premium_amt_override     varchar(255),
family_trust_management_liability_limit_1m_premium_amt                   varchar(255),
family_trust_management_liability_limit_1m_premium_amt_override          varchar(255), 
non_profit_do_liability_limit_1m_premium_amt                             varchar(255), 
non_profit_do_liability_limit_1m_premium_amt_override                    varchar(255),
non_profit_do_liability_limit_2m_premium_amt                             varchar(255),  
non_profit_do_liability_limit_2m_premium_amt_override                    varchar(255),
non_profit_do_liability_limit_3m_premium_amt                             varchar(255),  
non_profit_do_liability_limit_3m_premium_amt_override                    varchar(255),
non_profit_do_liability_limit_4m_premium_amt                             varchar(255),
non_profit_do_liability_limit_4m_premium_amt_override                    varchar(255),   
non_profit_do_liability_limit_5m_premium_amt                             varchar(255),
non_profit_do_liability_limit_5m_premium_amt_override                     varchar(255),   
source_system_sk                                                          int NOT NULL,
create_ts                                                                 datetime2(7),
update_ts                                                                 datetime2(7),
etl_audit_sk                                                              int,
CONSTRAINT pk_tgrpel_master_policy PRIMARY KEY (grpel_master_policy_sk),
CONSTRAINT uidx_tgrpel_master_policy_grpel_policy_no_effective_dt_trans_seq_no UNIQUE (grpel_master_policy_no,effective_dt,transaction_seq_no)
)
END;




IF EXISTS
(SELECT 1 FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_master_policy')
BEGIN
	delete FROM edw_core.tedw_table_detail
	where table_nm = 'tgrpel_master_policy' ; 
END ; 

INSERT INTO edw_core.tedw_table_detail (
    table_nm,
    table_type,
    table_category_nm,
    domain_nm,
    load_method,
    load_type,
    load_frequency,
    create_ts,
    update_ts
)
SELECT
    'tgrpel_master_policy',
    'Type-2 Dimension',
    'Base',
    'Group Personal Excess Liability',
    'Stored Procedure',
    'Insert',
    'Daily',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tgrpel_master_policy'
);




