IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'tdaily_inforce_policy'
    AND     COLUMN_NAME = 'policy_history_sk'
) BEGIN ALTER TABLE edw_core.tdaily_inforce_policy ADD policy_history_sk int null END; 

ALTER TABLE [edw_core].[tdaily_inforce_policy]  
ADD  CONSTRAINT [fk_tdaily_inforce_policy_policy_history_sk] FOREIGN KEY([policy_history_sk])
REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk]) 
