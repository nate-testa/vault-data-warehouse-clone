SELECT DISTINCT
        acct.PolicyNumber as quote_no, acct.EffectiveDate as effective_dt, acct.Number as transaction_seq_no,
            acctsh.Stage as transaction_type, acctsh.State as transaction_status,
        acctsh.CreatedDate as transaction_ts   
FROM edw_stage.[AccountTransactionStatusHistory] acctsh 
INNER JOIN  edw_stage.[AccountTransaction] acct  ON acctsh.AccountTransactionId = acct.Id 
left join edw_stage.Account acc on acc.id = acctsh.accountid
left join edw_stage.Product pr on acc.ProductId = pr.id
where acct.policynumber =  'AU100255039-03'
    and acctsh.Stage in ('QUOTE','POLICY')
    and pr.ProductLine = 'PersonalLines'
;

--EDW
SELECT TOP 10 * FROM edw_stage.[AccountTransaction] WHERE policynumber =  'AU100255039-03';
SELECT TOP 10 * FROM edw_stage.[AccountTransactionStatusHistory] 
WHERE AccountTransactionId IN ('c82535ad-01a8-4cbc-871e-25395861f49b','9ea2f9db-3b6d-4207-ab97-9b55308cbb74','b6587c6d-4fe1-4118-afd0-db1058b3fd39')
;

--Metal
SELECT TOP 10 * FROM dbo.[AccountTransaction] WHERE policynumber =  'AU100255039-03';
SELECT TOP 10 * FROM dbo.[AccountTransactionStatusHistory] 
WHERE AccountTransactionId IN ('c82535ad-01a8-4cbc-871e-25395861f49b','9ea2f9db-3b6d-4207-ab97-9b55308cbb74','b6587c6d-4fe1-4118-afd0-db1058b3fd39')
;