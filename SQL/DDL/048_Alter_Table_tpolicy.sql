alter table edw_core.tpolicy
add
prior_term_policy_no              varchar(255),
pending_non_renewal_in            varchar(255),
conditional_renewal_in            varchar(255),
non_renewal_note_desc             nvarchar(max),
non_renewal_sub_note_desc         nvarchar(max)
; 