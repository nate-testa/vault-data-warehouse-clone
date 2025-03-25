SELECT top 100 * FROM [edw_core].[tcustomer] WHERE customer_id = '1234543774';
SELECT top 100 * FROM [edw_core].[tpolicy] WHERE policy_no like 'HO100203234%';
SELECT * FROM edw_stage.[Insured] WHERE referencecode = '1234543774';