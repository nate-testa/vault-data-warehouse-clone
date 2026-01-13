IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'tvendor_report_field_data'
      AND COLUMN_NAME = 'lc360_summ_insp_num'
)
BEGIN
    ALTER TABLE edw_stage.tvendor_report_field_data ADD lc360_summ_insp_num VARCHAR(400) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'tvendor_report_field_data'
      AND COLUMN_NAME = 'lc360_insp_insp_num'
)
BEGIN
    ALTER TABLE edw_stage.tvendor_report_field_data ADD lc360_insp_insp_num VARCHAR(400) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'tvendor_report_field_data'
      AND COLUMN_NAME = 'lc360_sum_req_date'
)
BEGIN
    ALTER TABLE edw_stage.tvendor_report_field_data ADD lc360_sum_req_date VARCHAR(400) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'tvendor_report_field_data'
      AND COLUMN_NAME = 'lc360_sum_req_by'
)
BEGIN
    ALTER TABLE edw_stage.tvendor_report_field_data ADD lc360_sum_req_by VARCHAR(400) NULL;
END;