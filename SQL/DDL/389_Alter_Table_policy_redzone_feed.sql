Alter TABLE edw_integration.policy_redzone_feed
add  bdm_nm varchar(255);

Alter TABLE edw_integration.policy_redzone_feed
add  new_underwriter_nm varchar(255); 

Alter TABLE edw_integration.policy_redzone_feed
add  renewal_underwriter_nm varchar(255); 

Alter TABLE edw_integration.policy_redzone_feed
add  effective_dt date;  