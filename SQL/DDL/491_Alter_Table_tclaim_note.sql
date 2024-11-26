ALTER TABLE edw_core.tclaim_note DROP COLUMN subclaim_seq_no;
ALTER TABLE edw_core.tclaim_note DROP COLUMN send_message_to;
ALTER TABLE edw_core.tclaim_note DROP COLUMN overview_desc;

EXEC sp_rename 'edw_core.tclaim_note.category_nm', 'note_type', 'COLUMN';
EXEC sp_rename 'edw_core.tclaim_note.user_type', 'contact_type', 'COLUMN';

ALTER TABLE edw_core.tclaim_note ADD claim_feature_sk int;