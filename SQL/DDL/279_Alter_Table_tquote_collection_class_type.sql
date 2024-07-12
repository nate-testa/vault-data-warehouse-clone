ALTER TABLE edw_core.tquote_collection_class_type
ADD blanket_premium_adjustment_method varchar(255);

ALTER TABLE edw_core.tquote_collection_class_type
ADD blanket_premium_adjustment_factor decimal(16,4);

ALTER TABLE edw_core.tquote_collection_class_type
ADD blanket_premium_adjustment_retention varchar(255);

ALTER TABLE edw_core.tquote_collection_class_type
ADD blanket_premium_adjustment_retention_reason varchar(255);

ALTER TABLE edw_core.tquote_collection_class_type
ADD scheduled_premium_adjustment_method varchar(255);

ALTER TABLE edw_core.tquote_collection_class_type
ADD scheduled_premium_adjustment_factor decimal(16,4);

ALTER TABLE edw_core.tquote_collection_class_type
ADD scheduled_premium_adjustment_retention varchar(255);

ALTER TABLE edw_core.tquote_collection_class_type
ADD scheduled_premium_adjustment_retention_reason varchar(255);