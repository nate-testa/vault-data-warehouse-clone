IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tquote_auto_vehicle_coverage'
    AND     COLUMN_NAME = 'vehicle_unique_id'
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD vehicle_unique_id varchar(255) end;

/*
ALTER TABLE [edw_core].[tquote_auto_vehicle_coverage] drop CONSTRAINT [uidx_tquote_auto_vehicle_coverage_qtno_effdt_vehno_transeq]; 

ALTER TABLE [edw_core].[tquote_auto_vehicle_coverage] ADD CONSTRAINT [uidx_tquote_auto_vehicle_coverage_qtno_effdt_transeq_vehicle_unique_id] 
UNIQUE (quote_no,effective_dt,transaction_seq_no,vehicle_unique_id);
*/
 



