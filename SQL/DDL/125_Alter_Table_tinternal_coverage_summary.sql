ALTER TABLE edw_core.tinternal_coverage_summary 
add  
    annual_net_premium_amt decimal(15,2) null;

CREATE NONCLUSTERED INDEX [IX_tinternal_coverage_summary_month_sk] ON [edw_core].tinternal_coverage_summary
(
	month_sk ASC
) ;