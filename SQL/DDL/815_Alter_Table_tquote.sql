IF  EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tquote'
        AND LOWER(COLUMN_NAME) = 'renewal_review_quote_start_dt')
BEGIN
	alter table edw_core.tquote alter column renewal_review_quote_start_dt datetime2(7);
END;  