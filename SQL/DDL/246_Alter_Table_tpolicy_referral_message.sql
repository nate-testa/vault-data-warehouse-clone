ALTER TABLE edw_core.tpolicy_referral_message DROP COLUMN refer_in;

ALTER TABLE edw_core.tpolicy_referral_message DROP COLUMN approved_in;

ALTER TABLE [edw_core].[tpolicy_referral_message]  WITH CHECK ADD  CONSTRAINT [fk_tpolicy_referral_message_policy_history_sk] FOREIGN KEY([policy_history_sk])
REFERENCES [edw_core].[tpolicy_history] ([policy_history_sk])
GO
ALTER TABLE [edw_core].[tpolicy_referral_message] CHECK CONSTRAINT [fk_tpolicy_referral_message_policy_history_sk]
GO