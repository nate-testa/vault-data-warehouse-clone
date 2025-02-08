update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='claim',claim_transaction_type_nm='Loss'
where claim_transaction_type_cd='RC_01'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='adjusting',claim_transaction_type_nm='Expense'
where claim_transaction_type_cd='RC_02'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='defense',claim_transaction_type_nm='Defense'
where claim_transaction_type_cd='RC_03'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='claim-subrogation',claim_transaction_type_nm='Recovery'
where claim_transaction_type_cd='RC_04'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='claim-salvage',claim_transaction_type_nm='Recovery'
where claim_transaction_type_cd='RC_05'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='adjusting-salvage',claim_transaction_type_nm='Recovery'
where claim_transaction_type_cd='RC_06'

update edw_core.tclaim_transaction_type
set claim_transaction_type_cd='adjusting-subrogation',claim_transaction_type_nm='Recovery'
where claim_transaction_type_cd='RC_07'


INSERT INTO edw_core.tclaim_transaction_type (claim_transaction_type_cd,claim_transaction_type_nm,update_ts) VALUES
	('claim-overpayment' , 'Recovery' , getdate()),
	('claim-deductible' , 'Recovery' , getdate()),
	('claim-reinsurance' , 'Recovery' , getdate()),
	('adjusting-overpayment' , 'Recovery' , getdate()),
	('adjusting-deductible' , 'Recovery' , getdate()),
	('adjusting-reinsurance' , 'Recovery' , getdate()),
	('defense-salvage' , 'Recovery' , getdate()),
	('defense-subrogation' , 'Recovery' , getdate()),
	('defense-overpayment' , 'Recovery' , getdate()),
	('defense-deductible' , 'Recovery' , getdate()),
	('defense-reinsurance' , 'Recovery' , getdate());