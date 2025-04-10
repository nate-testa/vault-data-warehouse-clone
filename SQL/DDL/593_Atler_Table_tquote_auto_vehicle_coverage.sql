IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_first_party_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_first_party_premium_adjustment_amount int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_first_party_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_first_party_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_first_party_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_first_party_premium_adjustment_reason int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_first_party_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_first_party_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_personal_injury_protection_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_personal_injury_protection_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_personal_injury_protection_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_personal_injury_protection_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_personal_injury_protection_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_personal_injury_protection_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'added_personal_injury_protection_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD added_personal_injury_protection_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'basic_first_party_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD basic_first_party_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'basic_first_party_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD basic_first_party_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'basic_first_party_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD basic_first_party_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'basic_first_party_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD basic_first_party_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'customized_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD customized_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'customized_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD customized_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'customized_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD customized_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'customized_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD customized_premium_adjustment_retention int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'fire_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD fire_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'fire_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD fire_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'fire_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD fire_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'fire_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD fire_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'property_protection_insurance_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD property_protection_insurance_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'property_protection_insurance_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD property_protection_insurance_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'property_protection_insurance_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD property_protection_insurance_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'property_protection_insurance_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD property_protection_insurance_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'theft_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD theft_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'theft_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD theft_premium_adjustment_method int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'theft_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD theft_premium_adjustment_reason int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'theft_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD theft_premium_adjustment_retention int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_bodily_injury_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_bodily_injury_premium_adjustment_amount int END
;


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_bodily_injury_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_bodily_injury_premium_adjustment_method int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_bodily_injury_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_bodily_injury_premium_adjustment_reason int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_bodily_injury_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_bodily_injury_premium_adjustment_retention int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_motorist_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_motorist_premium_adjustment_amount int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_motorist_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_motorist_premium_adjustment_method int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_motorist_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_motorist_premium_adjustment_reason int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_motorist_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_motorist_premium_adjustment_retention int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_property_damage_premium_adjustment_amount'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_property_damage_premium_adjustment_amount int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_property_damage_premium_adjustment_method'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_property_damage_premium_adjustment_method int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_property_damage_premium_adjustment_reason'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_property_damage_premium_adjustment_reason int END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tquote_auto_vehicle_coverage'					
AND COLUMN_NAME = 'uninsured_property_damage_premium_adjustment_retention'					
) BEGIN ALTER TABLE edw_core.tquote_auto_vehicle_coverage ADD uninsured_property_damage_premium_adjustment_retention int END
;

