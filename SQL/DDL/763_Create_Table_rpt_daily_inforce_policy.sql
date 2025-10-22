IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'edw_insights_ai' 
                AND TABLE_NAME = 'rpt_daily_inforce_policy')
begin
create table edw_insights_ai.rpt_daily_inforce_policy 
(
    actual_dt date,
    policy_no varchar(255),
    product_nm varchar(255),
    broker_id varchar(255),
    broker_nm varchar(255),
    customer_id varchar(255),
    customer_nm varchar(255),
    risk_state_cd varchar(255),
    uw_company_nm varchar(255),
    premium_amt decimal(15,2),
    commission_amt decimal(15,2),
    net_premium_amt decimal(15,2),
    annual_premium_amt decimal(15,2),
    create_ts datetime2(7),
	update_ts datetime2(7),
	etl_audit_sk int  
    constraint pk_rpt_daily_policy_inforce primary key (actual_dt,policy_no)
)
end
