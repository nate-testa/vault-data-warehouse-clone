insert into edw_core.taslob
(aslob_cd,aslob_desc,product_cd,coverage_cd,update_ts)
select '192' as aslob_cd,'Auto Other Liability' as aslob_desc,'Auto' as product_cd,'Split Limits' as coverage_cd,getdate() as update_ts
union
select '192' as aslob_cd,'Auto Other Liability' as aslob_desc,'Auto' as product_cd,'Underinsured Motorist Liablity' as coverage_cd,getdate() as update_ts
union
select '040' as aslob_cd,'Homeowners' as aslob_desc,'Homeowners' as product_cd,	'Screen Enclosure' as coverage_cd,getdate() as update_ts
union
select '040' as aslob_cd,'Homeowners' as aslob_desc,'Homeowners' as product_cd,	'Water Damage limitation' as coverage_cd,getdate() as update_ts
union
select '171' as aslob_cd,'Other Liability' as aslob_desc,'Excess Liability' as product_cd,	'Excess Liability' as coverage_cd,getdate() as update_ts