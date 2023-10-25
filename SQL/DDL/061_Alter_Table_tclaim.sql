ALTER TABLE edw_core.tclaim
ADD
claim_created_ts datetime,
claim_created_by_nm varchar(255),
claim_first_closed_dt  date,
claim_first_reopen_dt date
;