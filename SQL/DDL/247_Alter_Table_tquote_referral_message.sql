ALTER TABLE edw_core.tquote_referral_message DROP COLUMN refer_in;

ALTER TABLE edw_core.tquote_referral_message DROP COLUMN approved_in;

ALTER TABLE [edw_core].[tquote_referral_message]  WITH CHECK ADD  CONSTRAINT [fk_tquote_referral_message_quote_history_sk] FOREIGN KEY([quote_history_sk])
REFERENCES [edw_core].[tquote_history] ([quote_history_sk])
GO
ALTER TABLE [edw_core].[tquote_referral_message] CHECK CONSTRAINT [fk_tquote_referral_message_quote_history_sk]
GO