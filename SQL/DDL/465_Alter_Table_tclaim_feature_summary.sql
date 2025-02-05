
IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subro_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.subro_reserve_amt', 'subrogation_recovery_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subro_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_subro_reserve_amt', 'itd_subrogation_recovery_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'salvage_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.salvage_reserve_amt', 'salvage_recovery_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_salvage_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_salvage_reserve_amt', 'itd_salvage_recovery_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subro_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.subro_expense_reserve_amt', 'subrogation_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subro_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_subro_expense_reserve_amt', 'itd_subrogation_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'salvage_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.salvage_expense_reserve_amt', 'salvage_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_salvage_expense_reserve_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_salvage_expense_reserve_amt', 'itd_salvage_recovery_expense_reserve_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subro_recovery_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.subro_recovery_amt', 'subrogation_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subro_recovery_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_subro_recovery_amt', 'itd_subrogation_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'salvage_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.salvage_expense_paid_amt', 'salvage_expense_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_salvage_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_salvage_expense_paid_amt', 'itd_salvage_expense_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subro_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.subro_expense_paid_amt', 'subrogation_expense_recovery_amt', 'COLUMN' END;

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subro_expense_paid_amt'
)
BEGIN EXEC sp_rename 'edw_core.tclaim_feature_summary.itd_subro_expense_paid_amt', 'itd_subrogation_expense_recovery_amt', 'COLUMN' END;

-------------------------------

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_recovery_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_recovery_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_recovery_expense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_recovery_expense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subrogation_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD subrogation_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subrogation_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_subrogation_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'salvage_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD salvage_recovery_defense_reserve_amt decimal(15,2) END;


IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_salvage_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_salvage_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_recovery_defense_reserve_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_recovery_defense_reserve_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'defense_paid_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD defense_paid_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_defense_paid_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_defense_paid_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_expense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_expense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'subrogation_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD subrogation_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_subrogation_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_subrogation_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'salvage_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD salvage_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_salvage_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_salvage_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'deductible_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD deductible_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_deductible_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_deductible_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'reinsurance_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD reinsurance_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_reinsurance_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_reinsurance_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'overpayment_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD overpayment_defense_recovery_amt decimal(15,2) END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tclaim_feature_summary'
    AND     COLUMN_NAME = 'itd_overpayment_defense_recovery_amt'
) BEGIN ALTER TABLE edw_core.tclaim_feature_summary ADD itd_overpayment_defense_recovery_amt decimal(15,2) END;