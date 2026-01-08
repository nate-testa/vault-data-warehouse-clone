IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'pending_process_ct'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD pending_process_ct INT NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_line_1'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_line_1 VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_line_2'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_line_2 VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_unit_no'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_unit_no VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_city_nm'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_city_nm VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_state_cd'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_state_cd VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'trenewal_summary_v1'
      AND COLUMN_NAME = 'risk_address_zip_cd'
)
BEGIN
    ALTER TABLE edw_stage.trenewal_summary_v1
    ADD risk_address_zip_cd VARCHAR(255) NULL;
END;

