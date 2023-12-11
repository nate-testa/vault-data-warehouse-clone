ALTER TABLE edw_core.tbroker_summary 
add  
    prior_ytd_quote_premium_amt decimal(15,2) NULL,
    ytd_quote_premium_amt decimal(15,2) NULL;