IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'hubspot_company_goals'
    AND     COLUMN_NAME = 'target_2024_policy_inforce_renewal_rentention_pct'
) BEGIN EXEC sp_rename 'edw_stage.hubspot_company_goals.target_2024_policy_inforce_renewal_rentention_pct', 'target_2024_policy_inforce_renewal_retention__', 'COLUMN';
 END;  

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'hubspot_company_goals'
    AND     COLUMN_NAME = 'target_monthly_nb_quote_commitment_$'
) BEGIN EXEC sp_rename 'edw_stage.hubspot_company_goals.target_monthly_nb_quote_commitment_$', 'target_monthly_nb_quote_commitment__', 'COLUMN';
 END;  

IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'hubspot_company_goals'
    AND     COLUMN_NAME = 'Pct_target_growth_2024_inforce_premium_over_last_year'
) BEGIN EXEC sp_rename 'edw_stage.hubspot_company_goals.Pct_target_growth_2024_inforce_premium_over_last_year', 'target_growth_2024_inforce_premium_over_last_year', 'COLUMN';
 END;  
 
IF EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_stage'
    AND     TABLE_NAME = 'hubspot_company_goals'
    AND     COLUMN_NAME = 'Pct_target_growth_2024_nb_premium_over_last_year'
) BEGIN EXEC sp_rename 'edw_stage.hubspot_company_goals.Pct_target_growth_2024_nb_premium_over_last_year', 'target_growth_2024_nb_premium_over_last_year', 'COLUMN';
 END;   