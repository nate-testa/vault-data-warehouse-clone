
 ALTER TABLE edw_core.tbroker_summary DROP CONSTRAINT fk_tbs_tsource_system_source_system_sk;
 
 ALTER TABLE edw_core.tbroker_summary
    DROP COLUMN source_system_sk; 