IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE OBJECT_ID = OBJECT_ID('edw_core.tpolicy_transaction') -- Replace 'YourSchema.YourTable' with the fully qualified name of your table
    AND name = 'idx_tpolicy_transaction_internal_coverage_sk' -- Replace 'YourIndex' with the name of the index you want to check
)
BEGIN
CREATE NONCLUSTERED INDEX [idx_tpolicy_transaction_internal_coverage_sk] ON [edw_core].[tpolicy_transaction]
(
	[internal_coverage_sk] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE OBJECT_ID = OBJECT_ID('edw_core.tpolicy_transaction') -- Replace 'YourSchema.YourTable' with the fully qualified name of your table
    AND name = 'idx_tpolicy_transaction_expiration_dt_sk' -- Replace 'YourIndex' with the name of the index you want to check
)
BEGIN
CREATE NONCLUSTERED INDEX [idx_tpolicy_transaction_expiration_dt_sk] ON [edw_core].[tpolicy_transaction]
(
	[expiration_dt_sk] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE OBJECT_ID = OBJECT_ID('edw_core.tpolicy_transaction') -- Replace 'YourSchema.YourTable' with the fully qualified name of your table
    AND name = 'idx_tpolicy_transaction_policy_transaction_type_sk' -- Replace 'YourIndex' with the name of the index you want to check
)
BEGIN
CREATE NONCLUSTERED INDEX [idx_tpolicy_transaction_policy_transaction_type_sk] ON [edw_core].[tpolicy_transaction]
(
	[policy_transaction_type_sk] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END;


