ALTER TABLE edw_integration.quote_note_hubspot_feed
ALTER COLUMN note_created_ts datetime2(7) null;

ALTER TABLE edw_integration.quote_note_hubspot_feed
ALTER COLUMN note_updated_ts datetime2(7) null; 