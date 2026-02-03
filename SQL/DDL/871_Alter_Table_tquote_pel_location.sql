 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'owned_by_trust_llc_or_other_entity_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD owned_by_trust_llc_or_other_entity_in  VARCHAR(255) NULL;
END;

 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_legal_nm'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_legal_nm  varchar(2000) NULL;
END;



 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_mailing_address'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_mailing_address  NVARCHAR(max) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_purpose'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_purpose  NVARCHAR(max) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_asset_use_or_possession'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_asset_use_or_possession  NVARCHAR(max) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_grantor_and_beneficiaries'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_grantor_and_beneficiaries  NVARCHAR(max) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_membership_details'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_membership_details  NVARCHAR(max) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_owned_holdings_or_assets'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_owned_holdings_or_assets NVARCHAR(max) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_business_activities'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_business_activities NVARCHAR(max) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_insurance_coverage'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_insurance_coverage NVARCHAR(max) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_employees_and_reponsibilities'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_employees_and_reponsibilities NVARCHAR(max) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_income_details'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD trust_or_legal_entity_income_details NVARCHAR(max) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'additional_owners_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD additional_owners_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'business_operations_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD business_operations_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'rented_outside_owners_family_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD rented_outside_owners_family_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'home_type'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD home_type VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'occupancy_type'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD occupancy_type VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tquote_pel_location'
      AND COLUMN_NAME = 'under_construction_or_renovation_in'
)
BEGIN
    ALTER TABLE edw_core.tquote_pel_location
    ADD under_construction_or_renovation_in VARCHAR(255) NULL;
END


