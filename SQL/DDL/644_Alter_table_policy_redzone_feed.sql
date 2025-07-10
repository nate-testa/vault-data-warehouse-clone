IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'policy_redzone_feed'					
AND COLUMN_NAME = 'gate_entry_code_required_in'					
) BEGIN ALTER TABLE edw_integration.policy_redzone_feed ADD gate_entry_code_required_in VARCHAR(255) END ; 