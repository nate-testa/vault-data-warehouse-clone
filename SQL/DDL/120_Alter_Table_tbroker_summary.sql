ALTER TABLE edw_core.tbroker_summary 
add  
    prior_ytd_submission_ct int NOT NULL default 0,
    ytd_submission_ct int NOT NULL default 0;