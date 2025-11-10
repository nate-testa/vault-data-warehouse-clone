insert into edw_core.tinternal_coverage
(
internal_coverage_cd,product_cd,internal_coverage_desc,aslob_cd,internal_coverage_category_nm,create_ts,update_ts,primary_coverage_cd)
select 'Employment Practices Liability' as internal_coverage_cd,'GRPEL' as product_cd,'Employment Practices Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,getdate(),getdate(),'EPL Coverage' as primary_coverage_cd
union
select 'UM/UIM Motorist Liability' as  internal_coverage_cd,'GRPEL' as product_cd,'UM/UIM Motorist Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,getdate(),getdate(),'UM Motorist' as primary_coverage_cd
union
select 'Excess Liability' as internal_coverage_cd,'GRPEL' as product_cd,'Excess Liability' as internal_coverage_desc,171 as aslob_cd,'Premium' as internal_coverage_category_nm,getdate(),getdate(),'Excess Liability' as primary_coverage_cd
union
select 'Surplus Lines Tax' as internal_coverage_cd,'GRPEL' as product_cd,'Surplus Lines Tax' as internal_coverage_desc,171 as aslob_cd,
'State Tax' as internal_coverage_category_nm,getdate() as create_ts,getdate() as update_ts,'State Tax' as primary_coverage_cd
union
select 'Program Administrator Fees' as  internal_coverage_cd,'GRPEL' as product_cd,'Program Administrator Fees' as internal_coverage_desc,171 as aslob_cd,'
Fee' as internal_coverage_category_nm,getdate() as create_ts,getdate() as update_ts,'Fee' as primary_coverage_cd;