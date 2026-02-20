IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
           WHERE 
			CONSTRAINT_NAME = 'uidx_tquote_grpel_vehicle_qtno_effdt_vehuid' AND TABLE_NAME = 'tquote_grpel_vehicle'
			AND TABLE_SCHEMA = 'edw_core'
		)
BEGIN    
    ALTER TABLE edw_core.tquote_grpel_vehicle DROP CONSTRAINT uidx_tquote_grpel_vehicle_qtno_effdt_vehuid;

	ALTER TABLE edw_core.tquote_grpel_vehicle ADD CONSTRAINT uidx_tquote_grpel_vehicle_qtno_effdt_transeq_vehuid
		UNIQUE (quote_no, effective_dt, transaction_seq_no, vehicle_unique_id);
END
