ALTER TABLE edw_core.tpolicy_summary 
add  
    annual_net_premium_amt decimal(15,2) null;

CREATE NONCLUSTERED INDEX [IX_tpolicy_summary_month_sk] ON [edw_core].tpolicy_summary
(
	month_sk ASC
) ;