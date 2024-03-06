
ALTER TABLE edw_core.tquote_home_coverage ADD waive_inspection_in varchar(255);
ALTER TABLE edw_core.tquote_home_coverage ADD waive_inspection_reason varchar(255);
ALTER TABLE edw_core.tquote_home_coverage ADD inspection_note nvarchar(max);
ALTER TABLE edw_core.tquote_home_coverage ADD rms_reviewed_in varchar(255);