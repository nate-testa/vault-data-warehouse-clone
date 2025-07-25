ALTER TABLE edw_core.tedw_release_note
DROP CONSTRAINT chk_impacted_table_schema;

 

ALTER TABLE edw_core.tedw_release_note
ADD CONSTRAINT chk_impacted_table_schema
CHECK (
    impacted_table_schema IN ('edw_integration', 'edw_stage', 'edw_core', 'edw_commercial')
);