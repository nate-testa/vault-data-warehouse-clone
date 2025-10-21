
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_insights_ai' 
               AND TABLE_NAME = 'rpt_policy_transaction')
BEGIN
CREATE TABLE edw_insights_ai.rpt_policy_transaction 
(
    policy_no VARCHAR(255),
    effective_dt DATE,
    expiration_dt DATE,
    transaction_effective_dt DATE,
    transaction_seq_no INT,
    transaction_dt DATE,
    product_nm VARCHAR(255),
    broker_id VARCHAR(255),
    broker_nm VARCHAR(255),
    customer_id VARCHAR(255),
    customer_nm VARCHAR(255),
    risk_state_cd VARCHAR(255),
    uw_company_nm VARCHAR(255),
    transaction_type VARCHAR(255),
    transaction_desc NVARCHAR(MAX),
    cancellation_reason_desc NVARCHAR(MAX),
    cancellation_sub_reason_desc VARCHAR(255),
    premium_amt DECIMAL(15, 2),
    commission_amt DECIMAL(15, 2),
    net_premium_amt DECIMAL(15, 2),
    annual_premium_amt DECIMAL(15, 2),
    tax_fee_surcharge_amt DECIMAL(15, 2),
    CONSTRAINT pk_rpt_policy_transaction PRIMARY KEY (policy_no,effective_dt,transaction_seq_no)
)
END