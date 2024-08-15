alter table edw_core.trenewal_summary
add product_nm varchar(255); 

alter table edw_core.trenewal_summary
add renewal_quote_note_desc  nvarchar(max); 

alter table edw_core.trenewal_summary
add pending_non_renewal_ct int; 

alter table edw_core.trenewal_summary
add agency_primary_location_state_cd  varchar(255);

alter table edw_core.trenewal_summary
add expiring_sixty_day_rate_on_line decimal(15,2);

alter table edw_core.trenewal_summary
add renewal_sixty_day_rate_on_line decimal(15,2);

alter table edw_core.trenewal_summary
add renewal_quote_rate_on_line decimal(15,2);

alter table edw_core.trenewal_summary
add expiring_rate_on_line decimal(15,2);

