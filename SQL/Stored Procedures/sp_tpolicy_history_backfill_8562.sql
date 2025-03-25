DROP TABLE IF EXISTS edw_temp.tpolicy_history_backfill_temp1
;

SELECT
	acct.id,
	acct.PolicyNumber AS policy_no,
	acct.EffectiveDate AS effective_dt,
	acct.PolicyChangeNumber AS transaction_seq_no,
	acct.IsReversed,
	acct.IsReversal
INTO edw_temp.tpolicy_history_backfill_temp1
FROM edw_stage.AccountTransaction acct 
INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id 
left join edw_stage.Product pr on acctv.ProductId = pr.id
WHERE acct.State ='ISSUED'
and	acct.PolicyNumber is not null 
and pr.ProductLine = 'PersonalLines'
;

UPDATE a 
SET a.transaction_status = 	CASE 
								WHEN b.IsReversed = 1 THEN 'Reversed'
								WHEN b.IsReversal = 1 THEN 'Reversal'
								ELSE 'Issued'
							END
FROM edw_core.tpolicy_history a
LEFT JOIN edw_temp.tpolicy_history_backfill_temp1 b
ON a.policy_no = b.policy_no
AND a.effective_dt = b.effective_dt
AND a.transaction_seq_no = b.transaction_seq_no
;

DROP TABLE IF EXISTS edw_temp.tpolicy_history_backfill_temp1
;
        