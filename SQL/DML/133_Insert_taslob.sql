insert into edw_core.taslob
(aslob_cd,aslob_desc,product_cd,coverage_cd,update_ts)
select '171' as aslob_cd,'Other Liability' as aslob_desc,'Excess Liability' as product_cd,'Excess Liability' as coverage_cd,getdate() as update_ts