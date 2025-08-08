IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'edw_core'
and TABLE_name = 'tgroup_umbrella_coverage')
BEGIN
CREATE TABLE edw_core.tgroup_umbrella_coverage
(
group_umbrella_coverage_sk              int NOT NULL IDENTITY(1,1),  
policy_no                  varchar(255) NOT NULL,
group_umbrella_policy_no   varchar(255),
effective_dt               date NOT NULL,
transaction_effective_dt   date NOT NULL,
expiration_dt              date NOT NULL,
transaction_dt             date NOT NULL,
transaction_seq_no         int NOT NULL,
policy_history_sk          int NOT NULL,
group_nm      	        varchar(255),
insured_spouse_nm            varchar(255),
group_excess_liability_limit_amt  varchar(255),
group_excess_liability_premium_amt  varchar(255),
uninsured_motorist_liability_limit_amt  varchar(255),
uninsured_motorist_liability_premium_amt  varchar(255),
employment_practises_liability_limit_amt  varchar(255),
employment_practises_liability_premium_amt  varchar(255),
non_profit_do_liability_limit_amt  varchar(255),
non_profit_do_liability_premium_amt  varchar(255),
family_trust_management_liability_limit_amt  varchar(255),
family_trust_management_liability_premium_amt  varchar(255),
no_of_residences             varchar(255),
no_of_vehicles               varchar(255),
no_of_drivers_under_22        varchar(255),
no_of_drivers_from_22_to_75      varchar(255),
no_of_drivers_76_and_older       varchar(255),
underlying_auto_liability_limit_amt nvarchar(max),
underlying_home_liability_limit_amt nvarchar(max),
underlying_watercraft_liability_limit_amt nvarchar(max),
underinsured_liability_limit_desc nvarchar(max),
nfp_program_sharing_funding_amt  varchar(255),
vault_fronting_fees_excessofloss_ceding_comm_collected_amt  varchar(255),
quota_share_ceding_comm_collected_amt  varchar(255),
total_ceding_comm_collected_amt  varchar(255),
vault_ceding_comm_override_after_expenses_amt  varchar(255),
vault_fronting_fees_amt  varchar(255),
add_fee_income_due_amt  varchar(255),
vault_premium_with_profitshare_frontfees_amt  varchar(255),
risk_group  varchar(255),
fronting_fee_total_amt  varchar(255),
underwriting_year_pc  varchar(255),
source_system_sk                  int NOT NULL,
create_ts                           datetime,
update_ts                           datetime,
etl_audit_sk                        int,
CONSTRAINT pk_tgroup_umbrella_coverage PRIMARY KEY (group_umbrella_coverage_sk),
CONSTRAINT uidx_tgroup_umbrella_coverage_polno_effdt_transeq UNIQUE (policy_no,effective_dt,transaction_seq_no),
CONSTRAINT fk_tgroup_umbrella_coverage_policy_history_sk FOREIGN KEY (policy_history_sk) REFERENCES  edw_core.tpolicy_history(policy_history_sk)
)
END;

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
    'tgroup_umbrella_coverage',
    'Type-2 Dimension',
    'Base',
    'Policy',
    'Stored Procedure',
    'Insert',
    'Monthly',
    GETDATE(),
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tedw_table_detail
    WHERE table_nm = 'tgroup_umbrella_coverage'
);

