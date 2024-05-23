ALTER TABLE edw_core.tquote_pel_coverage
ADD excess_coverage_premium_adjustment_method varchar(255);

ALTER TABLE edw_core.tquote_pel_coverage
ADD excess_coverage_premium_adjustment_factor decimal(16,4);

ALTER TABLE edw_core.tquote_pel_coverage
ADD excess_coverage_premium_adjustment_retention varchar(255);

ALTER TABLE edw_core.tquote_pel_coverage
ADD excess_coverage_premium_adjustment_retention_reason varchar(255);