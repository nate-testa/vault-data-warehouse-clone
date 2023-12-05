ALTER TABLE edw_core.tmanuscript ADD
manuscript_seq_no  int
;

ALTER TABLE edw_core.tmanuscript DROP CONSTRAINT uidx_tmanuscript_polno_effdt_transeq_manuscript_no;

CREATE UNIQUE INDEX uidx_tmanuscript_polno_effdt_transeq_manuscript_seq_no ON edw_core.tmanuscript(policy_no,effective_dt,transaction_seq_no,manuscript_seq_no);
