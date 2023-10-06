INSERT INTO [edw_core].[tetl_control]
       ([process_nm]
       ,[last_source_extract_ts]
       ,[update_ts])
SELECT
       'sp_billing_account_customer_portal_api',
       NULL,
       NULL
WHERE NOT EXISTS (
       SELECT 1
       FROM [edw_core].[tetl_control]
       WHERE [process_nm] = 'sp_billing_account_customer_portal_api'
);

INSERT INTO [edw_core].[tetl_control]
       ([process_nm]
       ,[last_source_extract_ts]
       ,[update_ts])
SELECT
       'sp_policy_customer_portal_api',
       NULL,
       NULL
WHERE NOT EXISTS (
       SELECT 1
       FROM [edw_core].[tetl_control]
       WHERE [process_nm] = 'sp_policy_customer_portal_api'
);