IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tinternal_coverage_inforce'
    AND     COLUMN_NAME = 'policy_history_sk'
) BEGIN ALTER TABLE edw_core.tinternal_coverage_inforce ADD policy_history_sk int null END; 

ALTER TABLE [edw_core].[tinternal_coverage_inforce]  
ADD  CONSTRAINT [fk_tinternal_coverage_inforce_policy_history_sk] FOREIGN KEY([policy_history_sk])
REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
