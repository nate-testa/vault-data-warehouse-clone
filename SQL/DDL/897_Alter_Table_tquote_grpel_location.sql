IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
           WHERE 
			CONSTRAINT_NAME = 'uidx_tquote_grpel_location_qtno_effdt_locuid' AND TABLE_NAME = 'tquote_grpel_location'
			AND TABLE_SCHEMA = 'edw_core'
		)
BEGIN    
    ALTER TABLE edw_core.tquote_grpel_location DROP CONSTRAINT uidx_tquote_grpel_location_qtno_effdt_locuid;

	ALTER TABLE edw_core.tquote_grpel_location ADD CONSTRAINT uidx_tquote_grpel_location_qtno_effdt_transeq_locuid 
		UNIQUE (quote_no, effective_dt, transaction_seq_no, location_unique_id);
END
