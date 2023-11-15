ALTER TABLE edw_core.thome_coverage 
ADD
premium_adjustment_method  varchar(255),
premium_adjustment_factor  decimal(16,4),
premium_adjustment_retention   varchar(255),
premium_adjustment_retention_reason varchar(255),
reinsurance_designation nvarchar(max),
reinsurance_layered_program_in       varchar(255),
reinsurance_attachment_limit_amt  varchar(255),
reinsurance_total_tiv_amt  int
;

