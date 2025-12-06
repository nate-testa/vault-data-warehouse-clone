INSERT INTO edw_core.tedw_release_summary (release_summary, send_email_in, send_email_dt, create_ts, update_ts)
VALUES (
'
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <span style="background-color: #9D0208; color: white; font-weight: bold; font-size: 18px; padding: 5px; display: inline-block; text-decoration: underline;">Release Summary - 12/08/2025 :</span>
    <h4 style="margin-top: 0;font-style: italic;color: blue;">This release had 8 enhancements and 4 bug fix tickets.  Release details are as follows.</h4>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        h1, h2 { color: #333; }
        ul { margin: 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h2 style="font-style: italic;">1. EDW/Datamart Enhancements</h2>
    <ul>
        <li>Commercial Claims EDW enhancements. This includes following tables.
            <ul>
                <li>tcommercial_claim_payment</li>
                <li>tcommercial_claim_transaction</li>
                <li>tcommercial_claim_tag</li>
                <li>tcommercial_claim_summary</li>
                <li>tcommercial_claim_feature_summary</li>
            </ul>
        </li>
        <li>Added column - prior_claims_in to thome_coverage and tquote_home_coverage tables</li>
        <li>Added column - prior_claims_over_2500_in to thome_coverage and tquote_home_coverage tables</li>
        <li>Updated mapping for prior_claim_last5yr_in in thome_coverage and tquote_home_coverage tables</li>
        <li>Added column - risk_sharing_deductible_pc to thome_additional_coverage and tquote_home_additional_coverage tables</li>
        <li>Updated vlc360 view to add the following fields
            <ul>
                <li>InspectionNumber</li>
                <li>RequestDate</li>
                <li>RequestedBy</li>
            </ul>
        </li>
    </ul>
    <h2 style="font-style: italic;">2. EDW Process Enhancements</h2>
    <h3>a. Personal Lines</h3>
    <ul>
        <li>Modified few data validation SQLs to enhance data accuracy</li>
    </ul>
    <h3>b. Commercial Lines</h3>
    <ul>
        <li>Created 30 new validation SQL to identify data quality issues associated with commercial lines data</li>
        <li>Added premium and claim reconciliation checks</li>
    </ul>
    
    <h2 style="font-style: italic;">3. EDW Integrations</h2>
    <h3>a. Hubspot</h3>
    <ul>
        <li>Updated producer hubspot feed logic to remove duplicate producers</li>
    </ul>
    
    <h3>b. IVANS</h3>
    <ul>
        <li>INC45320/INC45319 : Resent IVANS policies associated with these tickets</li>
    </ul>
    <h2 style="font-style: italic;">4. Data Fixes</h2>
    <ul>
        <li>INC45247 : Updated program type for one policy HO200062946-01.  This is just a onetime update.</li>
        <li>AD11755 : Updated a typo in EDW for product name Miscellaneous Professional Liability.</li>
    </ul>
</body>
'
,'Yes'
,'2025-12-08'
,getdate()
,getdate()
)
;

INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','thome_coverage','prior_claims_in','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','tquote_home_coverage','prior_claims_in','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','thome_coverage','prior_claims_over_2500_in','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','tquote_home_coverage','prior_claims_over_2500_in','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','thome_coverage','prior_claim_last5yr_in','Updated mapping associated with this column and performed a backfill for it','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11867','EDW/Datamart Enhancements: Created new column to thome_coverage and tquote_home_coverage tables','Enhancement','2025-12-06','Rushin Shah','Addition','edw_core','tquote_home_coverage','prior_claim_last5yr_in','Updated mapping associated with this column and performed a backfill for it','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11825','EDW/Datamart Enhancements: Created new column to thome_additional_coverage and tquote_home_additional_coverage','Enhancement','2025-12-06','Tuba Mohsin','Addition','edw_core','thome_additional_coverage','risk_sharing_deductible_pc','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11825','EDW/Datamart Enhancements: Created new column to thome_additional_coverage and tquote_home_additional_coverage','Enhancement','2025-12-06','Tuba Mohsin','Addition','edw_core','tquote_home_additional_coverage','risk_sharing_deductible_pc','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','EDW/Datamart Enhancements: Created new commercial claims tables','Enhancement','2025-12-06','Bhaskar Muthyala','Addition','edw_commercial','tcommercial_claim_payment','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','EDW/Datamart Enhancements: Created new commercial claims tables','Enhancement','2025-12-06','Bhaskar Muthyala','Addition','edw_commercial','tcommercial_claim_transaction','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','EDW/Datamart Enhancements: Created new commercial claims tables','Enhancement','2025-12-06','Bhaskar Muthyala','Addition','edw_commercial','tcommercial_claim_tag','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','EDW/Datamart Enhancements: Created new commercial claims tables','Enhancement','2025-12-06','Bhaskar Muthyala','Addition','edw_commercial','tcommercial_claim_summary','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','EDW/Datamart Enhancements: Created new commercial claims tables','Enhancement','2025-12-06','Bhaskar Muthyala','Addition','edw_commercial','tcommercial_claim_feature_summary','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11912','EDW/Datamart Enhancements: Add columns to LC360 view','Enhancement','2025-12-06','Dinesh Bobbili','Addition','edw_core','vlc360','InspectionNumber','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11912','EDW/Datamart Enhancements: Add columns to LC360 view','Enhancement','2025-12-06','Dinesh Bobbili','Addition','edw_core','vlc360','RequestDate','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11912','EDW/Datamart Enhancements: Add columns to LC360 view','Enhancement','2025-12-06','Dinesh Bobbili','Addition','edw_core','vlc360','RequestedBy','Created new column','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11719','Process Enhancements: Created new table for premium and claims daily reconciliation','Enhancement','2025-12-06','Yunus Mohammed','Addition','edw_commercial','tcommercial_reconciliation','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11929','Process Enhancements: Created new table and added 30 validation checks for commercial data','Enhancement','2025-12-06','Yunus Mohammed','Addition','edw_commercial','tcommercial_validation_sql','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11929','Process Enhancements: Created new table and added 30 validation checks for commercial data','Enhancement','2025-12-06','Yunus Mohammed','Addition','edw_commercial','tcommercial_validation_result','','Created new table','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','Process Improvements : Updated validations to tvalidation_sql','Enhancement','2025-12-06','Dinesh Bobbili','Modification','edw_core','tvalidation_sql','','Few validation SQL were refined to enhance accuracy','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC45320/INC45319','IVANS Policy Resent Request','Bug','2025-12-06','Rushin Shah','Datafix','edw_integration','policy_ivans_home_feed','','Resent a few home policies to IVANS','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC45320/INC45319','IVANS Policy Resent Request','Bug','2025-12-06','Rushin Shah','Datafix','edw_integration','policy_ivans_auto_feed','','Resent a few auto policies to IVANS','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC45320/INC45319','IVANS Policy Resent Request','Bug','2025-12-06','Rushin Shah','Datafix','edw_integration','policy_ivans_pel_feed','','Resent a few PEL policies to IVANS','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW Integrations : Updated producer hubspot feed logic to remove duplicate producers','Enhancement','2025-12-06','Architha Gudimalla','Modification','edw_integration','producer_hubspot_feed','','Updated producer hubspot feed logic to remove duplicate producers','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC45247','Data Fixes : Updated program type for one policy HO200062946-01','Bug','2025-12-06','Rushin Shah','Datafix','edw_stage','AccountTransactionVersionObjectField','','Updated program type for one policy HO200062946-01.  This is just a onetime update.','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC45247','Data Fixes : Updated program type for one policy HO200062946-01','Bug','2025-12-06','Rushin Shah','Datafix','edw_stage','AccountObjectField','','Updated program type for one policy HO200062946-01.  This is just a onetime update.','47','Yes','2025-12-08',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11755','Data Fixes : Updated a typo in EDW for product name Miscellaneous Professional Liability','Bug','2025-12-06','Sandeep Gundreddy','Datafix','edw_core','tproduct','product_nm','Updated a typo in EDW for product name Miscellaneous Professional Liability','47','Yes','2025-12-08',getdate(),getdate());