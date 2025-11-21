INSERT INTO edw_core.tedw_release_summary (release_summary, send_email_in, send_email_dt, create_ts, update_ts)
VALUES (
'
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <span style="background-color: #9D0208; color: white; font-weight: bold; font-size: 18px; padding: 5px; display: inline-block; text-decoration: underline;">Release Summary - 11/24/2025 :</span>
    <h4 style="margin-top: 0;font-style: italic;color: blue;">This release had 2 enhancements and 3 bug fix tickets.  Release details are as follows.</h4>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        h1, h2 { color: #333; }
        ul { margin: 10px 0; padding-left: 20px; }
    </style>
</head>
<body>
    <h2 style="font-style: italic;">1. EDW/Datamart Enhancements</h2>
    <ul>
        <li>Added column - allow_communication_to_customer_in to tbroker table</li>
        <li>Integration of NFP data in EDW : NFP data will be inserted in the following EDW tables.
            <ul>
                <li>tpolicy</li>
                <li>tpolicy_history</li>
                <li>tpolicy_transaction</li>
                <li>tcustomer</li>
                <li>tgrpel_coverage</li>
                <li>tcustomer_summary</li>
                <li>tdaily_inforce_summary</li>
                <li>tpolicy_summary</li>
                <li>tpolicy_transaction_summary</li>
                <li>tinternal_coverage_inforce</li>
                <li>tinternal_coverage_summary</li>
                <li>trenewal_summary</li>
                <li>tbroker_summary</li>
                <li>tclaim</li>
                <li>tclaim_feature</li>
                <li>tclaim_transaction</li>
                <li>tclaim_summary</li>
                <li>tclaim_feature_summary</li>
            </ul>
        </li>
    </ul>
    <h2 style="font-style: italic;">2. EDW Integrations</h2>
    <h3>a. IVANS</h3>
    <ul>
        <li>INC44665/INC44651/INC44447 : Resent IVANS policies associated with these tickets</li>
    </ul>
</body>
'
,'Yes'
,'2025-11-24'
,getdate()
,getdate()
)
;

INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11744','EDW/Datamart Enhancements: Created new column to tpolicy and tquote table','Enhancement','2025-11-22','Tuba Mohsin','Addition','edw_core','tbroker','allow_communication_to_customer_in','Created new column','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tpolicy','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tpolicy_history','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tpolicy_transaction','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tcustomer','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tgrpel_coverage','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tdaily_inforce_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tpolicy_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tpolicy_transaction_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','trenewal_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tbroker_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tcustomer_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tinternal_coverage_summary','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Dinesh Bobbili','Modification','edw_core','tinternal_coverage_inforce','','Loaded NFP data into this table','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Yunus Mohammed','Modification','edw_core','tclaim','','Backfilled policy_sk, policy_history_sk, product_sk, broker_id and customer_id associated with NFP data','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Yunus Mohammed','Modification','edw_core','tclaim_feature','','Backfilled coverage_sk and product_sk associated with NFP data','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Yunus Mohammed','Modification','edw_core','tclaim_transaction','','Backfilled policy_sk,  product_sk, broker_sk and customer_sk associated with NFP data','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Yunus Mohammed','Modification','edw_core','tclaim_summary','','Backfilled policy_sk, broker_sk, product_sk and customer_sk associated with NFP data','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('AD11764','EDW/Datamart Enhancements: Integrate NFP Group Excess data into EDW','Enhancement','2025-11-22','Yunus Mohammed','Modification','edw_core','tclaim_feature_summary','','Backfilled policy_sk, broker_sk, product_sk and customer_sk associated with NFP data','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC44665/INC44651/INC44447','IVANS Policy Resent Request','Bug','2025-11-22','Rushin Shah','Datafix','edw_integration','policy_ivans_home_feed','','Resent a few home policies to IVANS','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC44665/INC44651/INC44447','IVANS Policy Resent Request','Bug','2025-11-22','Rushin Shah','Datafix','edw_integration','policy_ivans_auto_feed','','Resent a few auto policies to IVANS','46','Yes','2025-11-24',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('INC44665/INC44651/INC44447','IVANS Policy Resent Request','Bug','2025-11-22','Rushin Shah','Datafix','edw_integration','policy_ivans_pel_feed','','Resent a few PEL policies to IVANS','46','Yes','2025-11-24',getdate(),getdate());