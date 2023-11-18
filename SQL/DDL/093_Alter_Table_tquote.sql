ALTER TABLE edw_core.tquote ALTER COLUMN effective_dt date NULL;

ALTER TABLE edw_core.tquote ALTER COLUMN expiration_dt date NULL;

ALTER TABLE edw_core.tquote ALTER COLUMN broker_id varchar(255) NULL;

ALTER TABLE edw_core.tquote ALTER COLUMN risk_state_cd varchar(255) NULL;