ALTER TABLE edw_core.tpolicy_history
ADD
producer_sk int;

ALTER TABLE edw_core.tpolicy_history ADD CONSTRAINT fk_tpolicy_history_producer_sk FOREIGN KEY(producer_sk) REFERENCES edw_core.tproducer(producer_sk);