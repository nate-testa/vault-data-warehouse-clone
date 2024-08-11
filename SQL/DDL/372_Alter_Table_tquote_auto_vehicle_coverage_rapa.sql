ALTER TABLE edw_core.tquote_auto_vehicle_coverage_rapa 
DROP CONSTRAINT IF EXISTS uidx_tquote_auto_vehicle_coverage_rapa_qtno_effdt_vehno_transeq; 

/*
ALTER TABLE edw_core.tquote_auto_vehicle_coverage_rapa  
ADD CONSTRAINT uidx_tquote_auto_vehicle_coverage_rapa_qtno_effdt_unqid_transeq unique (
	[quote_no] ,
	[effective_dt] ,
	[vehicle_unique_id] ,
	[transaction_seq_no] 
)
*/
