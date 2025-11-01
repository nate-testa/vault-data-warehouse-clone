INSERT INTO edw_core.tvalidation_sql 
(validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'UMLimit not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from
edw_core.tpolicy p
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where	
	not exists
	(
		select 1
		from
		edw_stage.ProductObjectFieldValueDisplay pofv 
		where ps.Id = pofv.ProductId and pofv.Field = ''UMLimit'' and pofv.ObjectType = ''Automobile''
		and  p.risk_state_cd=pofv.statecode
		and p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')
		and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end
		and ( apc.uninsured_motorist_limit_amt = replace(pofv.[ValueDisplay],''$'',''''))
	)
	and isnull(apc.uninsured_motorist_limit_amt,'''')!=''''
	and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'AdditionalPIP not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1  from   edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''AdditionalPIP'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.additional_pip = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.additional_pip,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'BasicPIP not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''BasicPIP'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.basic_pip = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.basic_pip,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'BILimit not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''BILimit'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.bodily_injury_limit_amt = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.bodily_injury_limit_amt,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'DeductibleAppliesTo not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''DeductibleAppliesTo'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.deductible_applies_to = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.deductible_applies_to,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'UIMLimit not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''UIMLimit'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.underinsured_motorist_limit_amt = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.underinsured_motorist_limit_amt,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'UMBIPolicyLimit not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''UMBIPolicyLimit'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.um_bi_policy_limit_amt = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.um_bi_policy_limit_amt,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts
union
SELECT
'WorkLossExclusion not matching with edw_stage.ProductObjectFieldValueDisplay' as validation_sql_desc,
'select count(*)
from edw_core.tpolicy p 
inner join edw_core.tproduct pr on p.product_cd = pr.product_cd 
inner join edw_stage.[Product] ps on ps.[Name] = case when pr.[product_nm] = ''Auto'' then ''Automobile'' else pr.[product_nm] end 
inner join edw_core.tauto_policy_coverage apc on p.policy_no = apc.policy_no and p.effective_dt = apc.effective_dt
where  
not exists ( select 1 from edw_stage.ProductObjectFieldValueDisplay pofv where ps.Id = pofv.ProductId
and pofv.Field = ''WorkLossExclusion'' and pofv.ObjectType = ''Automobile'' and p.risk_state_cd=pofv.statecode   and 
p.Effective_dt between pofv.EffectiveDate and isnull(pofv.ExpirationDate,''2099-01-01'')   
and pofv.IsRenewal = case when p.policy_term = ''Renewal'' then 1 else 0 end  
and ( apc.work_loss_exclusion = replace(pofv.[ValueDisplay],''$'',''''))  
)  
and isnull(apc.work_loss_exclusion,'''')!=''''
and cast(apc.create_ts as date) = cast(getdate() as date)' AS source_sql  ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts