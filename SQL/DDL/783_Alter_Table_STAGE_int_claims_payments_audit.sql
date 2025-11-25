ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_amount              decimal(18,2) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_mail_tracking_number nvarchar(255) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_monitored           nvarchar(255) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_selection           nvarchar(255) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_method_last4digit   nvarchar(255) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_re_issue            nvarchar(255) NULL;
ALTER TABLE [edw_stage].[int_claims_payments_audit]
    ALTER COLUMN pm_error_code          nvarchar(255) NULL;