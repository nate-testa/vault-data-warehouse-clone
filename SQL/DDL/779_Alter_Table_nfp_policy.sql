-- term_effective_date
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'term_effective_date'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD term_effective_date date NULL;
END;

-- transaction_seq_no
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'transaction_seq_no'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD transaction_seq_no int NULL;
END;

-- original_policy_no
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'original_policy_no'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD original_policy_no varchar(255) NULL;
END;

-- original_policy_effective_dt
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'original_policy_effective_dt'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD original_policy_effective_dt date NULL;
END;

-- prior_term_policy_no
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'prior_term_policy_no'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD prior_term_policy_no varchar(255) NULL;
END;

-- uw_company_original_policy_effective_dt
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'uw_company_original_policy_effective_dt'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD uw_company_original_policy_effective_dt date NULL;
END;

-- term_no
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'term_no'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD term_no varchar(255) NULL;
END;

-- policy_term
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_stage'
      AND TABLE_NAME = 'nfp_policy'
      AND COLUMN_NAME = 'policy_term'
)
BEGIN
    ALTER TABLE edw_stage.nfp_policy ADD policy_term varchar(255) NULL;
END;