UPDATE edw_core.tvalidation_sql
SET
    source_sql = 'WITH clue_claim AS (
        SELECT * FROM (
            SELECT 
                claimNumber,
                claimAmount,
                CAST(CAST(claimAmount AS INT) / 100.0 AS DECIMAL(15,2)) AS clue_loss_paid,
                ROW_NUMBER() OVER (PARTITION BY claimNumber ORDER BY create_ts DESC) AS RNK
            FROM edw_integration.claim_clue_property_feed
            WHERE claimReportingStatus = ''A''
        ) A
        WHERE A.RNK = 1
    ),
    edw_claim AS (
        SELECT 
            claim_sk,
            claim_no,
            claim_status,
            SUM(
                loss_paid_amt + expense_paid_amt + defense_paid_amt +
                overpayment_recovery_amt + overpayment_expense_recovery_amt +
                overpayment_defense_recovery_amt
            ) AS edw_loss_paid
        FROM edw_core.tclaim cl
        WHERE source_system_sk != 1
            AND product_sk IN (1, 2, 5)
            AND EXISTS (
                SELECT 1 FROM edw_core.tclaim_transaction ct WHERE cl.claim_sk = ct.claim_sk
            )
            AND policy_no IN (
                SELECT policy_no FROM edw_stage.OneShieldPolicy_clue
                UNION
                SELECT policy_no FROM edw_core.tpolicy
                UNION
                SELECT policy_no FROM edw_core.thome_location
                UNION
                SELECT policy_no FROM edw_core.tcollection_location
            )
        GROUP BY claim_sk, claim_no, claim_status
    )
    SELECT 
        claim_sk,
        b.claim_no,
        claim_status,
        a.clue_loss_paid,
        b.edw_loss_paid
    INTO #temp1
    FROM edw_claim b
    LEFT JOIN clue_claim a ON a.claimNumber = b.claim_no
    WHERE ISNULL(a.clue_loss_paid, 99999999999) != b.edw_loss_paid
        AND claim_no NOT IN (''C24HOA00377'', ''C24HOA00323'')',
    update_ts = GETDATE()
WHERE validation_sql_desc = 'CLUE Property feed validation - loss paid amount mismatch';


UPDATE edw_core.tvalidation_sql
SET
    source_sql = 'WITH clue_claim AS (
        SELECT * FROM (
            SELECT 
                claimNumber,
                claimAmount,
                CAST(CAST(claimAmount AS INT) / 100.0 AS DECIMAL(15,2)) AS clue_loss_paid,
                ROW_NUMBER() OVER (PARTITION BY claimNumber ORDER BY create_ts DESC) AS RNK
            FROM edw_integration.claim_clue_property_feed
            WHERE claimReportingStatus = ''A''
        ) A
        WHERE A.RNK = 1
    ),
    edw_claim AS (
        SELECT 
            claim_sk,
            claim_no,
            claim_status,
            SUM(
                loss_paid_amt + expense_paid_amt + defense_paid_amt +
                overpayment_recovery_amt + overpayment_expense_recovery_amt +
                overpayment_defense_recovery_amt
            ) AS edw_loss_paid
        FROM edw_core.tclaim cl
        WHERE source_system_sk != 1
            AND product_sk IN (1, 2, 5)
            AND EXISTS (
                SELECT 1 FROM edw_core.tclaim_transaction ct WHERE cl.claim_sk = ct.claim_sk
            )
            AND policy_no IN (
                SELECT policy_no FROM edw_stage.OneShieldPolicy_clue
                UNION
                SELECT policy_no FROM edw_core.tpolicy
                UNION
                SELECT policy_no FROM edw_core.thome_location
                UNION
                SELECT policy_no FROM edw_core.tcollection_location
            )
        GROUP BY claim_sk, claim_no, claim_status
    )
    SELECT 
        claim_sk,
        b.claim_no,
        claim_status,
        a.clue_loss_paid,
        b.edw_loss_paid
    INTO #temp1
    FROM edw_claim b
    LEFT JOIN clue_claim a ON a.claimNumber = b.claim_no
    WHERE ISNULL(a.clue_loss_paid, 99999999999) != b.edw_loss_paid
        AND claim_no NOT IN (''C24HOA00377'', ''C24HOA00323'')',
    update_ts = GETDATE()
WHERE validation_sql_desc = 'CLUE Property feed validation - loss paid amount mismatch';