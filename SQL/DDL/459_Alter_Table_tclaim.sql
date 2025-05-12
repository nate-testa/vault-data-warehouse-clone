IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subro_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.subro_reserve_amt', 'subrogation_recovery_reserve_amt', 'COLUMN' END;


IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'salvage_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.salvage_reserve_amt', 'salvage_recovery_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subro_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.subro_expense_reserve_amt', 'subrogation_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'salvage_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.salvage_expense_reserve_amt', 'salvage_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subro_recovery_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.subro_recovery_amt', 'subrogation_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'salvage_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.salvage_expense_paid_amt', 'salvage_expense_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subro_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim.subro_expense_paid_amt', 'subrogation_expense_recovery_amt', 'COLUMN' END;

-----------------------------------------

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subrogation_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD subrogation_recovery_defense_reserve_amt decimal(15,2) END;


IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'salvage_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD salvage_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'defense_paid_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD defense_paid_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'subrogation_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD subrogation_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'salvage_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD salvage_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'deductible_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD deductible_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'reinsurance_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD reinsurance_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim'
    AND     COLUMN_NAME = 'overpayment_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim ADD overpayment_defense_recovery_amt decimal(15,2) END;


