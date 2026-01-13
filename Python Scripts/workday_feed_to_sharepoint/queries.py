from datetime import datetime, timedelta
from calendar import monthrange
import os
import yaml

def get_month_end_date():
    """
    Calculate month-end date based on current date:
    - If today is 2nd-31st: return current month's last day
    - If today is 1st: return prior month's last day
    """
    today = datetime.now()
    
    if today.day == 1:
        # If it's the 1st, get previous month's last day
        first_of_current_month = today.replace(day=1)
        last_day_of_prev_month = first_of_current_month - timedelta(days=1)
        return last_day_of_prev_month.strftime('%Y-%m-%d')
    else:
        # If it's 2nd-31st, get current month's last day
        _, last_day = monthrange(today.year, today.month)
        month_end = today.replace(day=last_day)
        return month_end.strftime('%Y-%m-%d')

def load_config():
    """Load configuration to check date filter setting"""
    config_path = os.path.join(os.path.dirname(__file__), 'config.yml')
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    # Check environment variable override first
    use_filter_env = os.getenv('USE_DATE_FILTER')
    if use_filter_env is not None:
        return use_filter_env.lower() in ('true', '1', 'yes')
    
    # Otherwise use config value (default to True if not specified)
    return config.get('migration', {}).get('use_date_filter', True)

# Calculate the dynamic month-end date
MONTH_END_DATE = get_month_end_date()
USE_DATE_FILTER = load_config()

# Build WHERE clauses based on configuration
# When USE_DATE_FILTER is True, use MAX(accounting_date) or MAX(monthend) instead of hardcoded dates
if USE_DATE_FILTER:
    ACCOUNTING_DATE_FILTER = "WHERE accounting_date = (SELECT MAX(accounting_date) FROM edw_integration.policy_workday_written_premium_feed)"
    MONTHEND_FILTER = "WHERE monthend = (SELECT MAX(monthend) FROM edw_integration.claim_workday_payment_feed)"
    AND_ACCOUNTING_DATE = "AND accounting_date = (SELECT MAX(accounting_date) FROM edw_integration.policy_workday_ceded_premium_feed)"
    AND_MONTHEND = "AND monthend = (SELECT MAX(monthend) FROM edw_integration.claim_workday_reserve_feed)"
else:
    ACCOUNTING_DATE_FILTER = "-- Date filter disabled"
    MONTHEND_FILTER = "-- Date filter disabled"
    AND_ACCOUNTING_DATE = ""
    AND_MONTHEND = ""

QUERIES = {
    "Workday_Written_Premium.csv": f"""
        SELECT ACCOUNTING_DATE, policy_image_identifier_id as TRANSACTION_ID, POLICY_NUMBER, PRODUCT, COMPANY, TRANSACTION_DATE, 
               EFFECTIVE_DATE, EXPIRATION_DATE, TRANSACTION_TYPE, PRODUCER_CODE, AGENCY_NAME, NUMBER_OF_INSTALLMENTS, INSURED_NAME, 
               ADDRESS, COUNTY, CITY, RISK_STATE, ZIP, FIRE_PROTECTION, CATEGORY, SUBCATEGORY, FINANCIAL_CATEGORY_ID, 
               FINANCIAL_CATEGORY_NAME, ASLOB, AMOUNT, CONTRIBCUTOFFDATE, DO_LIMIT_AMT, EMPLOYMENT_PRACTICES_LIABILITY_AMT, 
               PEL_LIMIT_AMT, UNINSURED_UNDERINSURED_LIABILITY_AMT, UNINSURED_UNDERINSURED_MOTORIST_LIABILITY_AMT, 
               SCHEDULED_LIMIT_AMT, BLANKET_LIMIT_AMT
        FROM edw_integration.policy_workday_written_premium_feed
        {ACCOUNTING_DATE_FILTER}
    """,
    
    "Workday_Unearned_Premium.csv": f"""
        SELECT ACCOUNTING_DATE, TRANSACTION_SEQUENCE, POLICY_NUMBER, PRODUCT, COMPANY, TRANSACTION_DATE, EFFECTIVE_DATE, 
               EXPIRATION_DATE, TRANSACTION_TYPE, PRODUCER_CODE, AGENCY_NAME, NUMBER_OF_INSTALLMENTS, INSURED_NAME, ADDRESS, 
               COUNTY, CITY, RISK_STATE, ZIP, FIRE_PROTECTION, CATEGORY, SUBCATEGORY, FINANCIAL_CATEGORY_ID, FINANCIAL_CATEGORY_NAME, 
               ASLOB, AMOUNT, UNEARNED, CONTRIBCUTOFFDATE, DO_LIMIT_AMT, EMPLOYMENT_PRACTICES_LIABILITY_AMT, 
               PEL_LIMIT_AMT, UNINSURED_UNDERINSURED_LIABILITY_AMT, UNINSURED_UNDERINSURED_MOTORIST_LIABILITY_AMT, 
               SCHEDULED_LIMIT_AMT, BLANKET_LIMIT_AMT, TRANSACTION_EFFECTIVE_DATE, TRANSACTION_TS
        FROM edw_integration.policy_workday_unearned_premium_feed
        {ACCOUNTING_DATE_FILTER}
    """,
    
    "Workday_Ceded_Premium.csv": f"""
        SELECT ACCOUNTING_DATE, policy_image_id as TRANSACTION_ID, POLICY_NUMBER, PRODUCT, COMPANY, TRANSACTION_DATE, 
               EFFECTIVE_DATE, EXPIRATION_DATE, TRANSACTION_TYPE, PRODUCER_CODE, AGENCY_NAME, NUMBER_OF_INSTALLMENTS, 
               INSURED_NAME, ADDRESS, COUNTY, CITY, RISK_STATE, ZIP, FIRE_PROTECTION, FINANCIAL_CATEGORY_ID, COVERAGENAME, 
               AMOUNT, GROSS_PREMIUM_AMT, contribcutoffdate as SUBSCRIBER_CONTRIBUTION_END_DT
        FROM edw_integration.policy_workday_ceded_premium_feed
        WHERE (amount != 0 OR gross_premium_amt != 0)
          {AND_ACCOUNTING_DATE}
    """,
    
    "Workday_Claim_Payment.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               PAYMENTTYPE, PAYEENAME, PAYMENTAMOUNT, SETTLEMENTTYPE, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, 
               MONTHEND, CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_workday_payment_feed
        {MONTHEND_FILTER}
    """,
    
    "Workday_Claim_Reserve.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               RESERVE_TYPE, RESERVE_AMOUNT, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, MONTHEND, INSUREDNAME, 
               CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_workday_reserve_feed
        WHERE reserve_amount != 0
          {AND_MONTHEND}
    """,
    
    "Workday_Claim_Reserve_ITD.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               RESERVE_TYPE, RESERVE_AMOUNT, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, MONTHEND, INSUREDNAME, 
               CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_workday_itd_reserve_feed
        WHERE reserve_amount != 0
          AND claim_no NOT LIKE 'CL%'
          {AND_MONTHEND}
    """,
    
    "Workday_Litigation_Claim_Payment.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               PAYMENTTYPE, PAYEENAME, PAYMENTAMOUNT, SETTLEMENTTYPE, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, 
               MONTHEND, CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_litigation_workday_payment_feed
        {MONTHEND_FILTER}
    """,
    
    "Workday_Litigation_Claim_Reserve.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               RESERVE_TYPE, RESERVE_AMOUNT, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, MONTHEND, INSUREDNAME, 
               CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_litigation_workday_reserve_feed
        WHERE reserve_amount != 0
          {AND_MONTHEND}
    """,
    
    "Workday_Litigation_Claim_Reserve_ITD.csv": f"""
        SELECT COMPANY, CLAIM_NO, POLICY_NO, TRANSACTION_DATE, POLICYEFFECTIVEDATE, CLAIMLOSSDATE, CLAIMREPORTEDDATE, 
               ADDRESS, CITY, STATE, ZIP, CAUSEOFLOSS, CATASTROPHECODE, CATASTROPHENAME, PRODUCT, POLICYCOVERAGETYPE, 
               RESERVE_TYPE, RESERVE_AMOUNT, ACCIDENT_YEAR, RISK_STATE, ASLOB, TRANSACTION_ID, MONTHEND, INSUREDNAME, 
               CLAIM_STATUS, LOSS_STATUS
        FROM edw_integration.claim_litigation_workday_itd_reserve_feed
        WHERE reserve_amount != 0
          {AND_MONTHEND}
    """
}
