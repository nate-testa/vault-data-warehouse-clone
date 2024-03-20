-- Commenting out because Alreay deployed Manually in production
/*
-- tedw_release_summary
INSERT INTO edw_core.tedw_release_summary (release_summary, send_email_in, send_email_dt, create_ts, update_ts)
VALUES (
'
<span style="background-color: #9D0208; color: white; font-weight: bold; font-size: 18px; padding: 5px; display: inline-block; text-decoration: underline;">Release Summary - 02/26/2024 :</span>
<h4 style="margin-top: 0;">This release includes the following:</h4>
<ol>
    <li>Enhancements - 2
        <ul>
			<li>Added renewal_tiv_amt, renewal_cova_amt and renewal_total_finished_square_feet columns to trenewal_summary </li>
			<li>Added customer_sk column to ttask table</li>	
	   </ul>
    </li>
    <li>Bug tickets - 8
        <ul>
            <li>Fixed migration data issue related to residency_type field in thome_coverage table</li>
			<li>Fixed migration data issue related to mailing_address_line1 field</li>
            <li>Fixed migration data issue related to address_line_1 field in thome_location table</li> 
			<li>Fixed migration data issue related to city_name field in thome_location table</li>
			<li>Fixed migration data issue related to appraisal_dt field in tcollection_scheduled_item table</li>
			<li>Fixed logic for antitheft_device_feature in tauto_vehicle_coverage </li>
        </ul>
    </li>
</ol>
'
,'Yes'
,'2024-02-26'
,getdate()
,getdate()
)
;

-- tedw_release_note

INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29276','Mailing Address Line1 is blank for for policy# EX100121838-03','Bug','2024-02-20','Sandeep Gundreddy','Datafix','edw_core','tpolicy','mailing_address_line1','Isolated issue in Metal impacts just one policy-EX100121838-03. Fixed maiiling address line1 in Metal and EDW.','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI27528/AD4981','city_nm includes state & zip code for manual policies','Bug','2024-02-24','Yunus Mohammed','Datafix','edw_core','thome_location','city_nm','This is a data issue associated with manual policies.  Fixed data in Metal and EDW.','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI26243/AD4647','Blank residencetype for 10 policies','Bug','2024-02-24','Rushin Shah','Datafix','edw_core','thome_coverage','residency_type','This is a migration issue.  Updated data in Metal and EDW. This is just a onetime update.','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI26976/AD4869','Missing Water Deductible for HO100219827-01','Bug','2024-02-26','Rushin Shah','Datafix','edw_core','thome_coverage','water_deductible','This is a migration issue.  Updated data in Metal and EDW. This is just a onetime update.','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI27816/AD5193','Missing Risk Address1 for HOX10010772-02','Bug','2024-02-26','Rushin Shah','Datafix','edw_core','thome_location','address_line_1','This is a migration issue.  Updated data in Metal and EDW. This is just a onetime update.','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29678/AD5184','Enhancements - trenewal_summary ','Enhancement','2024-02-26','Architha Gudimalla','Addition','edw_core','trenewal_summary','renewal_tiv_amt','Created new column','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29678/AD5184','Enhancements - trenewal_summary ','Enhancement','2024-02-26','Architha Gudimalla','Addition','edw_core','trenewal_summary','renewal_cova_amt','Created new column','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29678/AD5184','Enhancements - trenewal_summary ','Enhancement','2024-02-26','Architha Gudimalla','Addition','edw_core','trenewal_summary','renewal_total_finished_square_feet','Created new column','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29553/AD5202','Enhancements - ttask','Enhancement','2024-02-26','Architha Gudimalla','Addition','edw_core','ttask','customer_sk','Created new column','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29553/AD5202','Enhancements - ttask','Enhancement','2024-02-26','Architha Gudimalla','Addition','edw_core','ttask','','Updated logic to include tasks that do not have policy number, these tasks will show customer_sk','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29566/AD5180','Missing autotheft device info','Bug','2024-02-26','Architha Gudimalla','Modification','edw_core','tauto_vehicle_coverage','antitheft_device_feature','Updated logic to include Security and Safety Features group to load autotheft device info','2','Yes','2024-02-26',getdate(),getdate());
INSERT INTO edw_core.tedw_release_note (ticket_no, ticket_short_desc, ticket_type, production_deployment_dt, resource_nm, database_change_type, impacted_table_schema, impacted_table_nm, impacted_column_nm, resolution_summary, edw_release_summary_sk, send_email_in, send_email_dt, create_ts, update_ts) VALUES ('VI29776','Appraisal Date on policy jacket is incorrect from what is in Metal','Bug','2024-02-23','Sandeep Gundreddy','Datafix','edw_core','tcollection_scheduled_item','appraisal_dt','This is a migration issue for policy-HO100125868-01.  Updated data in Metal and EDW. This is just a onetime update.','2','Yes','2024-02-26',getdate(),getdate());

*/