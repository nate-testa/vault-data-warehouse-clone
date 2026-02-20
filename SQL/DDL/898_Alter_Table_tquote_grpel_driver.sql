IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
           WHERE 
			CONSTRAINT_NAME = 'uidx_tquote_grpel_driver_qtno_effdt_drvuid' AND TABLE_NAME = 'tquote_grpel_driver'
			AND TABLE_SCHEMA = 'edw_core'
		)
BEGIN    
    ALTER TABLE edw_core.tquote_grpel_driver DROP CONSTRAINT uidx_tquote_grpel_driver_qtno_effdt_drvuid;

	ALTER TABLE edw_core.tquote_grpel_driver ADD CONSTRAINT uidx_tquote_grpel_driver_qtno_effdt_transeq_drvuid
		UNIQUE (quote_no, effective_dt, transaction_seq_no, driver_unique_id);
END
