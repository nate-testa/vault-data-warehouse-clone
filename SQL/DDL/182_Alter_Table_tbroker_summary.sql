IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_loss_ratio'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_loss_ratio decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_loss_ratio_capped'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_loss_ratio_capped decimal (15,2) null END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_non_cat_loss_ratio'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_non_cat_loss_ratio decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_non_cat_loss_ratio_capped'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_non_cat_loss_ratio_capped decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_frequency'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_frequency decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_non_cat_frequency'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_non_cat_frequency decimal (15,2) null END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_severity'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_severity decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'one_year_non_cat_severity'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD one_year_non_cat_severity decimal (15,2) null END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_loss_ratio'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_loss_ratio decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_loss_ratio_capped'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_loss_ratio_capped decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_non_cat_loss_ratio'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_non_cat_loss_ratio decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_non_cat_loss_ratio_capped'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_non_cat_loss_ratio_capped decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_frequency'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_frequency decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_non_cat_frequency'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_non_cat_frequency decimal (15,2) null END; 

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_severity'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_severity decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tbroker_summary'
    AND COLUMN_NAME = 'three_year_non_cat_severity'
) BEGIN ALTER TABLE edw_core.tbroker_summary ADD three_year_non_cat_severity decimal (15,2) null END;