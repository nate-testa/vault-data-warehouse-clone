ALTER TABLE edw_core.titem_summary 
add  
    annual_net_premium_amt decimal(15,2) null;

CREATE NONCLUSTERED INDEX [IX_titem_summary_month_sk] ON [edw_core].titem_summary
(
	month_sk ASC
) ;