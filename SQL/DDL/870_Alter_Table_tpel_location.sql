 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'owned_by_trust_llc_or_other_entity_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD owned_by_trust_llc_or_other_entity_in  VARCHAR(255) NULL;
END;

 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_legal_name'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_legal_name  VARCHAR(255) NULL;
END;


 IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'mailing_address_trust_or_legal_entity'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD mailing_address_trust_or_legal_entity  VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_purpose'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_purpose  VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_asset_use_or_possession'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_asset_use_or_possession  VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_grantor_and_beneficiaries'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_grantor_and_beneficiaries  VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_membership_details'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_membership_details  VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_owned_holding_or_assets'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_owned_holding_or_assets VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_business_activities'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_business_activities VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_insurance_coverage'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_insurance_coverage VARCHAR(255) NULL;
END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_employees_and_reponsibilities'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_employees_and_reponsibilities VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'trust_or_legal_entity_income_details'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD trust_or_legal_entity_income_details VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'has_additional_owners_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD has_additional_owners_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'has_business_operations_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD has_business_operations_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'is_rented_outside_owners_family_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD is_rented_outside_owners_family_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'home_type'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD home_type VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'extended_liability_occupancy_type_occupancy_type'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD extended_liability_occupancy_type_occupancy_type VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'under_construction_or_renovation_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD under_construction_or_renovation_in VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'is_vacant_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD is_vacant_in  VARCHAR(255) NULL;
END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'edw_core'
      AND TABLE_NAME = 'tpel_location'
      AND COLUMN_NAME = 'is_any_vault_home_for_sale_in'
)
BEGIN
    ALTER TABLE edw_core.tpel_location
    ADD is_any_vault_home_for_sale_in  VARCHAR(255) NULL;
END;