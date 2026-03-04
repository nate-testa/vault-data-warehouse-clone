PHRASE_TO_TABLE = {
    "TRANSACTION DATA FEED":"stage_majesco_transaction_data_feed",
    "INSTALLMENT DATA FEED":"stage_majesco_installment_data_feed",
    "PAYMENT DATA FEED":"stage_majesco_payment_data_feed",
    "OUTPUT DATA FEED":"stage_majesco_output_data_feed",
    "NOTES DATA FEED":"stage_majesco_notes_data_feed",
    "INVOICE DATA FEED":"stage_majesco_invoice_data_feed",
}

# ------------------------------------------------------------
# ---------------------------Mapping--------------------------
# ------------------------------------------------------------

# ------------------------------ 1 ------------------------------
# Mapping for stage_majesco_transaction_data_feed
stage_majesco_transaction_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'SYSTEM_ACTIVITY_NO': 'system_activity_no',
    'SYSTEM_TRANSACTION_SEQ': 'system_transaction_seq',
    'DATE_TIME_CREATED': 'date_time_created',
    'UNDERWRITING_COMPANY': 'underwriting_company',
    'OPERATING_COMPANY': 'operating_company',
    'ACCOUNT_CODE': 'account_code',
    'POLICY_TERM_ID': 'policy_term_id',
    'POLICY_INCEPTION_DATE': 'policy_inception_date',
    'POLICY_EFF_DATE': 'policy_eff_date',
    'POLICY_EXP_DATE': 'policy_exp_date',
    'PRODUCT_CODE': 'product_code',
    'LINE_OF_BUSINESS': 'line_of_business',
    'SUBLINE_OF_BUSINESS': 'subline_of_business',
    'STATE_CODE': 'state_code',
    'BROKER_SYSTEM_CODE': 'broker_system_code',
    'BROKER_CODE': 'broker_code',
    'USER_ID': 'user_id',
    'BILL_TYPE': 'bill_type',
    'TRANSACTION_TYPE': 'transaction_type',
    'PAYMENT_PLAN': 'payment_plan',
    'SYSTEM_REMARKS': 'system_remarks',
    'USER_REMARKS': 'user_remarks',
    'COMMISSION_PAID_BASIS': 'commission_paid_basis',
    'DISCOUNT_PLAN_CODE': 'discount_plan_code',
    'CANCELLATION_DATE': 'cancellation_date',
    'CANCELLATION_TYPE': 'cancellation_type',
    'CANCELLATION_METHOD': 'cancellation_method',
    'CANCELLATION_REASON': 'cancellation_reason',
    'POLICY_BUSINESS_TYPE': 'policy_business_type',
    'TRANSACTION_EXPIRY_DATE': 'transaction_expiry_date',
    'SOURCE_ACCOUNTING_MONTH': 'source_accounting_month',
    'AMOUNT_SPREAD_OPTION': 'amount_spread_option',
    'PAYMENT_METHOD': 'payment_method',
    'SUSPEND_CODE': 'suspend_code',
    'SUSPEND_FLAG': 'suspend_flag',
    'RELEASE_DATE': 'release_date',
    'SUSPEND_NOC_CODE': 'suspend_noc_code',
    'SUSPEND_NOC_RELEASE_DATE': 'suspend_noc_release_date',
    'SUSPEND_COMMISSION_TYPE': 'suspend_commission_type',
    'AMOUNT_BILL_OPTION': 'amount_bill_option',
    'TRANSACTION_EFF_DATE': 'transaction_eff_date',
    'SOURCE_SYSTEM_PROCESS_DATE': 'source_system_process_date',
    'BILLING_ACCOUNTING_MONTH': 'billing_accounting_month',
    'WRITEOFF_REASON': 'writeoff_reason',
    'RECURRING_EFT_TOKEN_ID': 'recurring_eft_token_id',
    'AMOUNT': 'amount',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

# ------------------------------ 2 ------------------------------
# Mapping for stage_majesco_installment_data_feed
stage_majesco_installment_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'SYSTEM_ACTIVITY_NO': 'system_activity_no',
    'SYSTEM_TRANSACTION_SEQ': 'system_transaction_seq',
    'RECEIVABLE_ITEM_SEQ': 'receivable_item_seq',
    'BILL_NO': 'bill_no',
    'RECEIVABLE_CODE': 'receivable_code',
    'BILL_TO_ENTITY': 'bill_to_entity',
    'COMMISSION_AMOUNT': 'commission_amount',
    'SYSTEM_REMARKS': 'system_remarks',
    'USER_REMARKS': 'user_remarks',
    'RECEIVABLE_LEVEL': 'receivable_level',
    'TRANSACTION_TYPE': 'transaction_type',
    'GROSS_AMOUNT': 'gross_amount',
    'NET_AMOUNT': 'net_amount',
    'BILL_TO_ENTITY_TYPE': 'bill_to_entity_type',
    'BILL_TYPE': 'bill_type',
    'BILL_GROSS_NET': 'bill_gross_net',
    'CREATED_BY': 'created_by',
    'CREATED_ON': 'created_on',
    'ACCOUNTING_YEAR_MONTH': 'accounting_year_month',
    'RECEIVABLE_CATEGORY': 'receivable_category',
    'DOWNPAY_YN': 'downpay_yn',
    'COMMISSION_PERCENT': 'commission_percent',
    'AMOUNT_SPREAD_OPTION': 'amount_spread_option',
    'BILL_ACTIVITY_DATE': 'bill_activity_date',
    'BILL_DATE_PREPARED': 'bill_date_prepared',
    'CANCEL_CHECK_PROCESSED_DATE': 'cancel_check_processed_date',
    'ORIGINAL_DUE_DATE': 'original_due_date',
    'DIRECT_BILL_SEND_DATE': 'direct_bill_send_date',
    'DIRECT_BILL_DUE_DATE': 'direct_bill_due_date',
    'BILL_SEND_DATE': 'bill_send_date',
    'BILL_DUE_DATE': 'bill_due_date',
    'INSTALLMENT_NO': 'installment_no',
    'BILLVOIDED_YN': 'billvoided_yn',
    'VOIDED_DATE': 'voided_date',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

# ------------------------------ 3 ------------------------------
# Mapping for stage_majesco_payment_data_feed
stage_majesco_payment_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'SYSTEM_ACTIVITY_NO': 'system_activity_no',
    'SYSTEM_TRANSACTION_SEQ': 'system_transaction_seq',
    'RECEIVABLE_ITEM_SEQ': 'receivable_item_seq',
    'TRANSACTION_TYPE': 'transaction_type',
    'PAYMENT_AMOUNT': 'payment_amount',
    'CREATED_ON': 'created_on',
    'CREATED_BY': 'created_by',
    'SYSTEM_REMARK': 'system_remark',
    'USER_REMARK': 'user_remark',
    'ACCOUNTING_YEAR_MONTH': 'accounting_year_month',
    'BILL_TYPE': 'bill_type',
    'UNDERWRITING_COMPANY': 'underwriting_company',
    'OPERATING_COMPANY': 'operating_company',
    'PAYMENT_METHOD': 'payment_method',
    'PAYMENT_CHANNEL': 'payment_channel',
    'DATA_SEGMENT': 'data_segment',
    'RECEIVABLE_CODE': 'receivable_code',
    'PAYMENT_CATEGORY': 'payment_category',
    'PAYMENT_SEQ': 'payment_seq',
    'PAYMENT_IDENTIFIER': 'payment_identifier',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

# ------------------------------ 4 ------------------------------
# Mapping for stage_majesco_output_data_feed
stage_majesco_output_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'SYSTEM_ACTIVITY_NO': 'system_activity_no',
    'SYSTEM_TRANSACTION_SEQ': 'system_transaction_seq',
    'UNDERWRITING_COMPANY': 'underwriting_company',
    'POLICY_EFF_DATE': 'policy_eff_date',
    'POLICY_EXP_DATE': 'policy_exp_date',
    'PRODUCT_CODE': 'product_code',
    'STATE_CODE': 'state_code',
    'FORM_NAME': 'form_name',
    'FORM_DESCRIPTION': 'form_description',
    'RECEIPIENT_TYPE': 'receipient_type',
    'DATE_GENERATE': 'date_generate',
    'DOC_ID': 'doc_id',
    'MAILING_ENTITY_TYPE': 'mailing_entity_type',
    'MAILING_ENTITY_SYSTEM_CODE': 'mailing_entity_system_code',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

# ------------------------------ 5 ------------------------------
# Mapping for stage_majesco_notes_data_feed
stage_majesco_notes_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'REMARKS': 'remarks',
    'PRIVATE': 'private',
    'HAS_ATTACHMENT': 'has_attachment',
    'ATTACHMENT_CATEGORY': 'attachment_category',
    'ATTACHMENT_DESCRIPTION': 'attachment_description',
    'ATTACHMENT_FILENAME': 'attachment_filename',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

# ------------------------------ 6 ------------------------------
# Mapping for stage_majesco_invoice_data_feed
stage_majesco_invoice_data_feed = {
    'POLICY_NO': 'policy_no',
    'ACCOUNT_NO': 'account_no',
    'SYSTEM_ACTIVITY_NO': 'system_activity_no',
    'SYSTEM_TRANSACTION_SEQ': 'system_transaction_seq',
    'INVOICE_SEND_DATE': 'invoice_send_date',
    'POLICY_EFF_DATE': 'policy_eff_date',
    'POLICY_EXP_DATE': 'policy_exp_date',
    'INVOICE_DUE_DATE': 'invoice_due_date',
    'TOTAL_POLICY_COST': 'total_policy_cost',
    'PAYMENT_IN_FULL': 'payment_in_full',
    'CURRENT_DUE': 'current_due',
    'PAST_DUE': 'past_due',
    'INSTALLMENT_FEE': 'installment_fee',
    'NSF_FEE': 'nsf_fee',
    'DATAFIXINDICATOR_YN': 'datafixindicator_yn',
    'DATAFIX_DATE': 'datafix_date',
}

def get_mapping(table_name):
    """
    Returns the mapping dictionary for the given table name.
    """
    mappings = {
        'stage_majesco_transaction_data_feed': stage_majesco_transaction_data_feed,
        'stage_majesco_installment_data_feed': stage_majesco_installment_data_feed,
        'stage_majesco_payment_data_feed': stage_majesco_payment_data_feed,
        'stage_majesco_output_data_feed': stage_majesco_output_data_feed,
        'stage_majesco_notes_data_feed': stage_majesco_notes_data_feed,
        'stage_majesco_invoice_data_feed': stage_majesco_invoice_data_feed,
    }
    
    return mappings.get(table_name, {})