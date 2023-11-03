ALTER TABLE edw_core.tbroker_vault_team ADD product_sk int;

ALTER TABLE edw_core.tbroker_vault_team ADD CONSTRAINT fk_tbroker_vault_team_product_sk FOREIGN KEY (product_sk) REFERENCES edw_core.tproduct(product_sk);
